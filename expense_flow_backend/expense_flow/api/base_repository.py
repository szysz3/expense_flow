from decimal import Decimal
from typing import List, Optional, Dict
from datetime import datetime
from functools import wraps
from difflib import SequenceMatcher
from tinydb import TinyDB

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

class BaseRepository:
    """Base repository class with shared database functionality"""
    def __init__(self, db_path: str):
        self.db_path = db_path
        self._db = None
        
    @property
    def db(self) -> TinyDB:
        """Lazily initialize database connection"""
        if self._db is None:
            self._db = TinyDB(self.db_path)
        return self._db
        
    def close(self):
        """Close database connection if open"""
        if self._db is not None:
            self._db.close()
            self._db = None
    
    @handle_db_errors
    def _serialize_decimal_fields(self, data: dict, fields: List[str]) -> dict:
        """Convert all decimal fields to strings for storage"""
        result = data.copy()
        for field in fields:
            if field in result and isinstance(result[field], Decimal):
                result[field] = str(result[field])
        return result
    
    @handle_db_errors
    def _serialize_datetime_fields(self, data: dict, fields: List[str]) -> dict:
        """Convert all datetime fields to ISO format strings"""
        result = data.copy()
        for field in fields:
            if field in result and isinstance(result[field], datetime):
                result[field] = result[field].isoformat()
        return result
    
    @handle_db_errors
    def _deserialize_decimal_fields(self, data: dict, fields: List[str]) -> dict:
        """Convert string fields back to Decimal"""
        result = data.copy()
        for field in fields:
            if field in result and isinstance(result[field], str):
                try:
                    result[field] = Decimal(result[field])
                except:
                    # Keep as string if conversion fails
                    pass
        return result
    
    @handle_db_errors
    def _deserialize_datetime_fields(self, data: dict, fields: List[str]) -> dict:
        """Convert ISO format strings back to datetime objects"""
        result = data.copy()
        for field in fields:
            if field in result and isinstance(result[field], str):
                try:
                    result[field] = datetime.fromisoformat(result[field])
                except:
                    # Keep as string if conversion fails
                    pass
        return result
    
    def _are_similar(self, text1: str, text2: str, threshold: float = 0.95) -> bool:
        """
        Compare two strings for similarity using SequenceMatcher.
        Returns True if similarity ratio is above threshold.
        """
        return SequenceMatcher(None, text1, text2).ratio() >= threshold