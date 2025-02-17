from decimal import Decimal
from typing import List, Optional, Dict, Union
from datetime import datetime
from collections import defaultdict
from dateutil.relativedelta import relativedelta
import re
from tinydb import TinyDB, Query
import uuid
from contextlib import contextmanager
from functools import reduce, wraps

from .models import (
    Receipt, Category, SearchResult, SearchResultItem,
    CategoryItem, CategoryWithItems, CategorySummary,
    MonthSummary, MonthSummaryResponse, CategoryResponse,
    get_category_icon, get_category_name
)

class DatabaseError(Exception):
    pass

def handle_db_errors(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            raise DatabaseError(f"Database operation failed: {str(e)}")
    return wrapper

class ReceiptRepository:
    def __init__(self, db_path: str = "receipts.db"):
        self.db_path = db_path
        self._db = None
        
    @property
    def db(self) -> TinyDB:
        if self._db is None:
            self._db = TinyDB(self.db_path)
        return self._db
        
    def close(self):
        if self._db is not None:
            self._db.close()
            self._db = None

    def _serialize_receipt(self, receipt_dict: dict) -> dict:
        """Serialize receipt data for database storage"""
        serialized = receipt_dict.copy()
        
        if 'transaction_datetime' in serialized:
            serialized['transaction_datetime'] = serialized['transaction_datetime'].isoformat()
        if 'added_datetime' in serialized:
            serialized['added_datetime'] = serialized['added_datetime'].isoformat()
            
        serialized['total'] = str(serialized['total'])
        for item in serialized['items']:
            item['total_price'] = str(item['total_price'])
            
        return serialized

    @handle_db_errors
    def insert_receipt(self, receipt: Receipt) -> str:
        """Insert a new receipt and return its ID"""
        receipt_dict = receipt.dict()
        receipt_dict['id'] = str(uuid.uuid4())
        
        # Ensure added_datetime is set
        if 'added_datetime' not in receipt_dict:
            receipt_dict['added_datetime'] = datetime.utcnow()
            
        # Serialize the data for database storage
        serialized_receipt = self._serialize_receipt(receipt_dict)
        
        self.db.insert(serialized_receipt)
        return receipt_dict['id']

    @handle_db_errors
    def get_receipt(self, receipt_id: str) -> Optional[Receipt]:
        """Retrieve a receipt by ID"""
        receipt_query = Query()
        result = self.db.get(receipt_query.id == receipt_id)
        
        if result:
            # Convert datetime strings back to datetime objects
            result['transaction_datetime'] = datetime.fromisoformat(result['transaction_datetime'])
            result['added_datetime'] = datetime.fromisoformat(result['added_datetime'])
            
            # Convert stored strings back to decimal
            result['total'] = Decimal(result['total'])
            for item in result['items']:
                item['total_price'] = Decimal(item['total_price'])
                
            return Receipt(**result)
        return None

    def get_category_totals(self, start_date: Optional[datetime] = None, 
                        end_date: Optional[datetime] = None) -> Dict[Category, Decimal]:
        """Calculate total spending by category for a given date range"""
        receipt_query = Query()
        queries = []
        
        if start_date:
            queries.append(receipt_query.transaction_datetime.test(
                lambda x: datetime.fromisoformat(x) >= start_date
            ))
        if end_date:
            queries.append(receipt_query.transaction_datetime.test(
                lambda x: datetime.fromisoformat(x) <= end_date
            ))

        query = reduce(lambda x, y: x & y, queries) if queries else lambda _: True
        receipts = self.db.search(query)

        totals = defaultdict(Decimal)
        for receipt in receipts:
            for item in receipt['items']:
                category = Category(item['category'])
                totals[category] += Decimal(item['total_price'])

        return totals

    def get_categorized_items(self, category: Category, start_date: Optional[datetime] = None, 
                            end_date: Optional[datetime] = None) -> List[Dict]:
        """Get all items for a specific category within date range"""
        receipt_query = Query()
        queries = []
        
        if start_date:
            queries.append(receipt_query.transaction_datetime.test(
                lambda x: datetime.fromisoformat(x) >= start_date
            ))
        if end_date:
            queries.append(receipt_query.transaction_datetime.test(
                lambda x: datetime.fromisoformat(x) <= end_date
            ))

        query = reduce(lambda x, y: x & y, queries) if queries else lambda _: True
        receipts = self.db.search(query)

        items = []
        for receipt in receipts:
            for item in receipt['items']:
                if item['category'] == category.value:
                    items.append({
                        'description': item['description'],
                        'total_price': Decimal(item['total_price'])
                    })

        # Group similar items together and sum their prices
        grouped_items = defaultdict(Decimal)
        for item in items:
            grouped_items[item['description']] += item['total_price']

        return [
            {'description': desc, 'total_price': price}
            for desc, price in grouped_items.items()
        ]

    def get_categories_with_items(self) -> CategoryResponse:
        """Get all categories with their actual items from receipts"""
        current_month = datetime.utcnow().replace(day=1)
        next_month = current_month + relativedelta(months=1)
        
        categories = []
        for category in Category:
            items = self.get_categorized_items(category, current_month, next_month)
            
            # Convert to CategoryItem models, using most common items by spend
            category_items = []
            for idx, item in enumerate(sorted(items, key=lambda x: x['total_price'], reverse=True)):
                category_items.append(CategoryItem(
                    id=f"{category.value}_{idx + 1}",
                    name=item['description'],
                    amount=float(item['total_price'])
                ))
            
            # If we don't have any items for this category, add placeholder
            if not category_items:
                category_items.append(CategoryItem(
                    id=f"{category.value}_1",
                    name="No items this month",
                    amount=0.0
                ))
            
            categories.append(CategoryWithItems(
                id=category.value,
                name=get_category_name(category),
                iconName=get_category_icon(category),
                items=category_items
            ))
        
        return CategoryResponse(categories=categories)

    def get_monthly_summaries(self) -> MonthSummaryResponse:
        """Get spending summaries by month"""
        all_receipts = self.db.all()
        
        # Group receipts by month
        months = defaultdict(list)
        for receipt in all_receipts:
            date = datetime.fromisoformat(receipt['transaction_datetime'])
            month_key = date.strftime('%Y-%m')
            months[month_key].append(receipt)
        
        # Sort months in descending order
        sorted_months = sorted(months.keys(), reverse=True)
        
        summaries = []
        for i, month_key in enumerate(sorted_months):
            current_month = datetime.strptime(month_key, '%Y-%m')
            
            # Calculate current month totals
            current_totals = defaultdict(Decimal)
            for receipt in months[month_key]:
                for item in receipt['items']:
                    category = item['category']
                    current_totals[category] += Decimal(item['total_price'])
            
            # Calculate previous month totals
            prev_month_key = (current_month - relativedelta(months=1)).strftime('%Y-%m')
            prev_totals = defaultdict(Decimal)
            if prev_month_key in months:
                for receipt in months[prev_month_key]:
                    for item in receipt['items']:
                        category = item['category']
                        prev_totals[category] += Decimal(item['total_price'])
            
            # Create category summaries
            category_summaries = []
            for category in Category:
                category_summaries.append(CategorySummary(
                    id=category.value,
                    name=get_category_name(category),
                    iconName=get_category_icon(category),
                    amount=float(current_totals[category.value]),
                    previousMonthAmount=float(prev_totals[category.value])
                ))
            
            # Calculate previous month total
            prev_month_total = sum(prev_totals.values())
            
            summaries.append(MonthSummary(
                id=str(len(sorted_months) - i),
                month=current_month.strftime('%B %Y'),
                previousMonthTotal=float(prev_month_total),
                categories=category_summaries
            ))
        
        return MonthSummaryResponse(months=summaries)

    def _filter_items_by_categories(self, receipts: List[Receipt], categories: List[Category]) -> Dict:
        """Filter receipt items by categories and calculate total"""
        matching_items = []
        total = Decimal('0')
        
        for receipt in receipts:
            for item in receipt.items:
                if item.category in categories:
                    matching_items.append({
                        "description": item.description,
                        "total_price": str(item.total_price),
                        "category": item.category.value
                    })
                    total += item.total_price
                    
        return {
            "items": matching_items,
            "total": str(total)
        }

    def _convert_to_search_result(self, receipts: List[Receipt]) -> Dict:
        """Convert list of receipts to SearchResult format"""
        matching_items = []
        total = Decimal('0')
        
        for receipt in receipts:
            for item in receipt.items:
                matching_items.append({
                    "description": item.description,
                    "total_price": str(item.total_price),
                    "category": item.category.value
                })
                total += item.total_price
                    
        return {
            "items": matching_items,
            "total": str(total)
        }

    @handle_db_errors
    def search_receipts(
        self,
        merchant_name: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        categories: Optional[List[Category]] = None,
        item_description: Optional[str] = None
    ) -> SearchResult:
        """Search receipts with various filters"""
        ReceiptQuery = Query()
        queries = []
        
        if merchant_name:
            queries.append(ReceiptQuery.merchant.name.search(merchant_name, flags=re.IGNORECASE))
            
        if start_date:
            queries.append(ReceiptQuery.transaction_datetime.test(
                lambda x: datetime.fromisoformat(x) >= start_date
            ))
            
        if end_date:
            queries.append(ReceiptQuery.transaction_datetime.test(
                lambda x: datetime.fromisoformat(x) <= end_date
            ))
            
        if categories:
            queries.append(ReceiptQuery.items.any(
                lambda x: x['category'] in [c.value for c in categories]
            ))
            
        if item_description:
            queries.append(ReceiptQuery.items.any(
                lambda x: item_description.lower() in x['description'].lower()
            ))

        query = reduce(lambda x, y: x & y, queries) if queries else lambda _: True
        results = self.db.search(query)

        receipts = []
        for result in results:
            result['transaction_datetime'] = datetime.fromisoformat(result['transaction_datetime'])
            result['added_datetime'] = datetime.fromisoformat(result['added_datetime'])
            result['total'] = Decimal(result['total'])
            for item in result['items']:
                item['total_price'] = Decimal(item['total_price'])
            receipts.append(Receipt(**result))

        if categories:
            return SearchResult(**self._filter_items_by_categories(receipts, categories))
        
        return SearchResult(**self._convert_to_search_result(receipts))