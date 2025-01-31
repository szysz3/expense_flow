from decimal import Decimal
from typing import List, Optional, Dict, Union
from datetime import datetime
import re
from tinydb import TinyDB, Query
import uuid
from contextlib import contextmanager
from functools import reduce, wraps

from .models import Receipt, Category, SearchResult, SearchResultItem

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
        Receipt = Query()
        result = self.db.get(Receipt.id == receipt_id)
        
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
                    # Calculate total using the item's total_price directly
                    total += Decimal(item.total_price)
                    
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
            return self._filter_items_by_categories(receipts, categories)
            
        return receipts 