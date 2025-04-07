from decimal import Decimal
from typing import List, Optional, Dict, Any, Tuple
from datetime import datetime
from collections import defaultdict
from dateutil.relativedelta import relativedelta
import re
import uuid
from tinydb import Query

from .base_repository import BaseRepository, handle_db_errors
from expense_flow.api.models import (
    DailyExpense, Receipt, Category, SearchResult, CategoryItem, CategoryWithItems,
    CategorySummary, MonthSummary, MonthSummaryResponse, CategoryResponse,
    get_category_icon, get_category_name
)

class ReceiptRepository(BaseRepository):
    """
    Repository for handling receipt data storage and retrieval
    
    Provides methods for:
    - Adding and retrieving receipts
    - Categorizing and aggregating receipt items
    - Generating summaries by time period
    - Searching receipts by various criteria
    """
    
    def __init__(self, db_path: str = "receipts.db"):
        """
        Initialize receipt repository
        
        Args:
            db_path: Path to the TinyDB database file (default: "receipts.db")
        """
        super().__init__(db_path)
        self.RECEIPT_DATETIME_FIELDS = ['transaction_datetime', 'added_datetime']
        self.RECEIPT_DECIMAL_FIELDS = ['total']

    def _serialize_receipt(self, receipt_dict: dict) -> dict:
        """
        Serialize receipt data for database storage
        
        Args:
            receipt_dict: Dictionary representation of a Receipt
            
        Returns:
            Serialized dictionary ready for database storage
        """
        # First use the generic serializer for main fields
        serialized = self.serialize(
            receipt_dict,
            decimal_fields=self.RECEIPT_DECIMAL_FIELDS,
            datetime_fields=self.RECEIPT_DATETIME_FIELDS
        )
        
        # Process items directly since they're nested
        for item in serialized['items']:
            item['total_price'] = str(item['total_price'])
                
        return serialized

    def _deserialize_receipt(self, receipt_dict: dict) -> dict:
        """
        Deserialize receipt data from database storage
        
        Args:
            receipt_dict: Dictionary from database
            
        Returns:
            Deserialized dictionary with proper types
        """
        # First use the generic deserializer for main fields
        deserialized = self.deserialize(
            receipt_dict,
            decimal_fields=self.RECEIPT_DECIMAL_FIELDS,
            datetime_fields=self.RECEIPT_DATETIME_FIELDS
        )
        
        # Process items directly since they're nested
        for item in deserialized['items']:
            item = self._deserialize_decimal_fields(item, ['total_price'])
            
        return deserialized

    @handle_db_errors
    def insert_receipt(self, receipt: Receipt) -> str:
        """
        Insert a new receipt and return its ID
        
        Args:
            receipt: Receipt object to insert
            
        Returns:
            Generated UUID for the receipt
        """
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
        """
        Retrieve a receipt by ID
        
        Args:
            receipt_id: UUID of the receipt
            
        Returns:
            Receipt object if found, None otherwise
        """
        receipt_query = Query()
        result = self.db.get(receipt_query.id == receipt_id)
        
        if result:
            # Deserialize stored data
            deserialized_result = self._deserialize_receipt(result)
            return Receipt(**deserialized_result)
        return None

    def get_category_totals(self, start_date: Optional[datetime] = None, 
                        end_date: Optional[datetime] = None) -> Dict[Category, Decimal]:
        """
        Calculate total spending by category for a given date range
        
        Args:
            start_date: Optional start date filter
            end_date: Optional end date filter
            
        Returns:
            Dictionary mapping Category to total Decimal amount
        """
        date_filters = self.create_date_filter('transaction_datetime', start_date, end_date)
        query = self.build_query(date_filters)
        receipts = self.db.search(query)

        totals = defaultdict(Decimal)
        for receipt in receipts:
            for item in receipt['items']:
                category = Category(item['category'])
                totals[category] += Decimal(item['total_price'])

        return totals

    def get_categorized_items(self, category: Category, start_date: Optional[datetime] = None, 
                            end_date: Optional[datetime] = None) -> List[Dict]:
        """
        Get all items for a specific category within date range
        
        Args:
            category: Category to filter by
            start_date: Optional start date filter
            end_date: Optional end date filter
            
        Returns:
            List of dictionaries with item description and total price
        """
        date_filters = self.create_date_filter('transaction_datetime', start_date, end_date)
        query = self.build_query(date_filters)
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

    @handle_db_errors
    def get_daily_expenses(self, year: int, month: int) -> List[DailyExpense]:
        """
        Get daily expenses for a specific month
        
        Args:
            year: Year to filter by
            month: Month to filter by
            
        Returns:
            List of daily expenses
        """
        start_date = datetime(year, month, 1)
        
        if month == 12:
            end_date = datetime(year + 1, 1, 1)
        else:
            end_date = datetime(year, month + 1, 1)
            
        date_filters = self.create_date_filter('transaction_datetime', start_date, end_date)
        query = self.build_query(date_filters)
        receipts = self.db.search(query)
        
        daily_expenses = {}
        for receipt in receipts:
            receipt_date = datetime.fromisoformat(receipt['transaction_datetime'])
            day = receipt_date.day
            
            if day not in daily_expenses:
                daily_expenses[day] = {
                    'total': Decimal('0'),
                    'transaction_datetime': receipt_date
                }
                
            receipt_total = Decimal(receipt['total'])
            daily_expenses[day]['total'] += receipt_total
        
        result = [
            DailyExpense(
                day=day,
                total=data['total'],
                transaction_datetime=data['transaction_datetime']
            )
            for day, data in daily_expenses.items()
        ]
        
        return sorted(result, key=lambda x: x.day)

    def _find_similar_description(
        self,
        normalized_desc: str, 
        existing_descriptions: list[str], 
        threshold: float = 0.95
    ) -> Optional[str]:
        """
        Find the most similar existing description from the list
        
        Args:
            normalized_desc: Normalized description to find matches for
            existing_descriptions: List of existing normalized descriptions
            threshold: Similarity threshold (0.0 to 1.0)
            
        Returns:
            Most similar description if above threshold, None otherwise
        """
        for existing in existing_descriptions:
            if self._are_similar(normalized_desc, existing, threshold):
                return existing
        return None

    def _get_current_month_range(self) -> Tuple[datetime, datetime]:
        """
        Get current month date range
        
        Returns:
            Tuple with (start of current month, start of next month)
        """
        current_month = datetime.utcnow().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        next_month = current_month + relativedelta(months=1)
        return current_month, next_month

    def _group_similar_items(self, items: List[Dict], category: Category) -> Dict:
        """
        Group similar items together and calculate totals
        
        Args:
            items: List of items to group
            category: Category these items belong to
            
        Returns:
            Dictionary with grouped items
        """
        grouped_items = defaultdict(lambda: {"total": Decimal('0'), "count": 0, "original_descriptions": set()})
        
        known_descriptions: list[str] = []
        current_month, next_month = self._get_current_month_range()
        
        for item in items:
            original_desc = item['description']
            normalized_desc = original_desc.lower().strip()
            
            matching_desc = self._find_similar_description(normalized_desc, known_descriptions)
            
            if matching_desc:
                group_key = matching_desc
            else:
                group_key = normalized_desc
                known_descriptions.append(normalized_desc)
            
            grouped_items[group_key]["total"] += item['total_price']
            
            receipt_query = Query()
            date_filters = self.create_date_filter('transaction_datetime', current_month, next_month)
            item_filter = receipt_query.items.any(lambda x: x['description'] == original_desc)
            
            query = self.build_query([item_filter] + date_filters)
            matching_receipts = self.db.search(query)
            
            for receipt in matching_receipts:
                for receipt_item in receipt['items']:
                    if receipt_item['description'] == original_desc:
                        grouped_items[group_key]["count"] += receipt_item['quantity']
            
            grouped_items[group_key]["original_descriptions"].add(original_desc)
            
        return grouped_items

    def _convert_to_category_items(self, grouped_items: Dict, category: Category) -> List[CategoryItem]:
        """
        Convert grouped items to CategoryItem models
        
        Args:
            grouped_items: Dictionary with grouped items
            category: Category these items belong to
            
        Returns:
            List of CategoryItem objects sorted by total amount
        """
        category_items = []
        for idx, (group_key, data) in enumerate(
            sorted(grouped_items.items(), key=lambda x: x[1]["total"], reverse=True)
        ):
            display_name = min(data["original_descriptions"], key=len)
            
            category_items.append(CategoryItem(
                id=f"{category.value}_{idx + 1}",
                name=display_name,
                amount=float(data["total"]),
                count=int(data["count"])
            ))
        
        if not category_items:
            category_items.append(CategoryItem(
                id=f"{category.value}_1",
                name="No items this month",
                amount=0.0,
                count=0
            ))
            
        return category_items

    def get_categories_with_items(self) -> CategoryResponse:
        """
        Get all categories with their actual items from receipts
        
        Returns:
            CategoryResponse with categories and their items
        """
        current_month, next_month = self._get_current_month_range()
        categories = []
        
        for category in Category:
            items = self.get_categorized_items(category, current_month, next_month)
            
            grouped_items = self._group_similar_items(items, category)
            category_items = self._convert_to_category_items(grouped_items, category)
            
            categories.append(CategoryWithItems(
                id=category.value,
                name=get_category_name(category),
                iconName=get_category_icon(category),
                items=category_items
            ))
        
        return CategoryResponse(categories=categories)

    def _get_month_data(self, receipts: List[Dict]) -> Dict[str, List[Dict]]:
        """
        Group receipts by month
        
        Args:
            receipts: List of receipts to group
            
        Returns:
            Dictionary mapping month keys to lists of receipts
        """
        months = defaultdict(list)
        for receipt in receipts:
            date = datetime.fromisoformat(receipt['transaction_datetime'])
            month_key = date.strftime('%Y-%m')
            months[month_key].append(receipt)
            
        return months

    def _calculate_month_totals(self, receipts: List[Dict]) -> Dict[str, Decimal]:
        """
        Calculate category totals for a list of receipts
        
        Args:
            receipts: List of receipts
            
        Returns:
            Dictionary mapping category values to total amounts
        """
        totals = defaultdict(Decimal)
        for receipt in receipts:
            for item in receipt['items']:
                category = item['category']
                totals[category] += Decimal(item['total_price'])
                
        return totals

    def get_monthly_summaries(self) -> MonthSummaryResponse:
        """
        Get spending summaries by month
        
        Returns:
            MonthSummaryResponse with monthly spending summaries
        """
        all_receipts = self.db.all()
        
        months = self._get_month_data(all_receipts)
        sorted_months = sorted(months.keys(), reverse=True)
        
        summaries = []
        for i, month_key in enumerate(sorted_months):
            current_month = datetime.strptime(month_key, '%Y-%m')
            
            current_totals = self._calculate_month_totals(months[month_key])
            prev_month_key = (current_month - relativedelta(months=1)).strftime('%Y-%m')
            prev_totals = defaultdict(Decimal)
            if prev_month_key in months:
                prev_totals = self._calculate_month_totals(months[prev_month_key])
            
            category_summaries = []
            for category in Category:
                category_summaries.append(CategorySummary(
                    id=category.value,
                    name=get_category_name(category),
                    iconName=get_category_icon(category),
                    amount=float(current_totals[category.value]),
                    previousMonthAmount=float(prev_totals[category.value])
                ))
            
            prev_month_total = sum(prev_totals.values())
            
            summaries.append(MonthSummary(
                id=str(len(sorted_months) - i),
                month=current_month.strftime('%B %Y'),
                previousMonthTotal=float(prev_month_total),
                categories=category_summaries
            ))
        
        return MonthSummaryResponse(months=summaries)

    def _filter_items_by_categories(self, receipts: List[Receipt], categories: List[Category]) -> Dict:
        """
        Filter receipt items by categories and calculate total
        
        Args:
            receipts: List of Receipt objects
            categories: List of categories to filter by
            
        Returns:
            Dictionary with matching items and total
        """
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
        """
        Convert list of receipts to SearchResult format
        
        Args:
            receipts: List of Receipt objects
            
        Returns:
            Dictionary with items and total
        """
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
        """
        Search receipts with various filters
        
        Args:
            merchant_name: Optional merchant name to search for
            start_date: Optional start date filter
            end_date: Optional end date filter
            categories: Optional list of categories to filter by
            item_description: Optional item description to search for
            
        Returns:
            SearchResult with matching items
        """
        receipt_query = Query()
        queries = []
        
        if merchant_name:
            queries.append(receipt_query.merchant.name.search(merchant_name, flags=re.IGNORECASE))
            
        date_filters = self.create_date_filter('transaction_datetime', start_date, end_date)
        queries.extend(date_filters)
            
        if categories:
            queries.append(receipt_query.items.any(
                lambda x: x['category'] in [c.value for c in categories]
            ))
            
        if item_description:
            queries.append(receipt_query.items.any(
                lambda x: item_description.lower() in x['description'].lower()
            ))

        query = self.build_query(queries)
        results = self.db.search(query)

        receipts = []
        for result in results:
            deserialized_result = self._deserialize_receipt(result)
            receipts.append(Receipt(**deserialized_result))

        if categories:
            return SearchResult(**self._filter_items_by_categories(receipts, categories))
        
        return SearchResult(**self._convert_to_search_result(receipts))