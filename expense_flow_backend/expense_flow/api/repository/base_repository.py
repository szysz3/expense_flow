from decimal import Decimal
from typing import List, Optional, Any, Callable
from datetime import datetime
from functools import wraps, reduce
from difflib import SequenceMatcher
import re
from tinydb import TinyDB, Query

class DatabaseError(Exception):
    """Enhanced exception for database operations with context information"""
    def __init__(self, operation: str, details: str, original_exception: Optional[Exception] = None):
        self.operation = operation
        self.details = details
        self.original_exception = original_exception
        message = f"Database operation '{operation}' failed: {details}"
        if original_exception:
            message += f" Original error: {str(original_exception)}"
        super().__init__(message)


def handle_db_errors(func):
    """Decorator to handle database exceptions and provide context"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            if isinstance(e, DatabaseError):
                raise e
            operation = func.__name__.replace('_', ' ')
            raise DatabaseError(operation, "Operation failed", e)
    return wrapper


class BaseRepository:
    """
    Base repository class with shared database functionality
    
    Provides common utilities for database operations including:
    - Connection management
    - Serialization/deserialization
    - Query building
    - Text similarity comparison
    """
    def __init__(self, db_path: str):
        """
        Initialize the repository with a database path
        
        Args:
            db_path: Path to the TinyDB database file
        """
        self.db_path = db_path
        self._db = None
        
    def __enter__(self):
        """Enable 'with' statement usage"""
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Close database connection when exiting context"""
        self.close()
        
    @property
    def db(self) -> TinyDB:
        """
        Lazily initialize database connection
        
        Returns:
            TinyDB instance
        """
        if self._db is None:
            self._db = TinyDB(self.db_path)
        return self._db
        
    def close(self):
        """Close database connection if open"""
        if self._db is not None:
            self._db.close()
            self._db = None
    
    @handle_db_errors
    def serialize(self, data: dict, decimal_fields: Optional[List[str]] = None, 
                 datetime_fields: Optional[List[str]] = None) -> dict:
        """
        Generic serialization handling both decimal and datetime fields
        
        Args:
            data: Dictionary to serialize
            decimal_fields: List of field names containing Decimal values
            datetime_fields: List of field names containing datetime objects
            
        Returns:
            Serialized dictionary with string representations of special types
        """
        result = data.copy()
        if decimal_fields:
            result = self._serialize_decimal_fields(result, decimal_fields)
        if datetime_fields:
            result = self._serialize_datetime_fields(result, datetime_fields)
        return result

    @handle_db_errors
    def deserialize(self, data: dict, decimal_fields: Optional[List[str]] = None, 
                   datetime_fields: Optional[List[str]] = None) -> dict:
        """
        Generic deserialization handling both decimal and datetime fields
        
        Args:
            data: Dictionary to deserialize
            decimal_fields: List of field names to convert to Decimal
            datetime_fields: List of field names to convert to datetime
            
        Returns:
            Deserialized dictionary with proper types
        """
        result = data.copy()
        if datetime_fields:
            result = self._deserialize_datetime_fields(result, datetime_fields)
        if decimal_fields:
            result = self._deserialize_decimal_fields(result, decimal_fields)
        return result
    
    @handle_db_errors
    def _serialize_decimal_fields(self, data: dict, fields: List[str]) -> dict:
        """
        Convert all decimal fields to strings for storage
        
        Args:
            data: Dictionary containing fields to convert
            fields: List of field names to convert
            
        Returns:
            Dictionary with converted fields
        """
        result = data.copy()
        for field in fields:
            if field in result and isinstance(result[field], Decimal):
                result[field] = str(result[field])
        return result
    
    @handle_db_errors
    def _serialize_datetime_fields(self, data: dict, fields: List[str]) -> dict:
        """
        Convert all datetime fields to ISO format strings
        
        Args:
            data: Dictionary containing fields to convert
            fields: List of field names to convert
            
        Returns:
            Dictionary with converted fields
        """
        result = data.copy()
        for field in fields:
            if field in result and isinstance(result[field], datetime):
                result[field] = result[field].isoformat()
        return result
    
    @handle_db_errors
    def _deserialize_decimal_fields(self, data: dict, fields: List[str]) -> dict:
        """
        Convert string fields back to Decimal
        
        Args:
            data: Dictionary containing fields to convert
            fields: List of field names to convert
            
        Returns:
            Dictionary with converted fields
        """
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
        """
        Convert ISO format strings back to datetime objects
        
        Args:
            data: Dictionary containing fields to convert
            fields: List of field names to convert
            
        Returns:
            Dictionary with converted fields
        """
        result = data.copy()
        for field in fields:
            if field in result and isinstance(result[field], str):
                try:
                    result[field] = datetime.fromisoformat(result[field])
                except:
                    # Keep as string if conversion fails
                    pass
        return result
    
    def _normalize_text(self, text: str) -> str:
        """
        Normalize text for comparison by removing extra spaces, lowercasing, etc.
        
        Args:
            text: String to normalize
            
        Returns:
            Normalized string
        """
        # Remove multiple spaces, special characters, lowercase
        normalized = re.sub(r'\s+', ' ', text.lower().strip())
        normalized = re.sub(r'[^\w\s]', '', normalized)
        return normalized
    
    def _are_similar(self, text1: str, text2: str, threshold: float = 0.95) -> bool:
        """
        Compare two strings for similarity after normalization
        
        Args:
            text1: First string to compare
            text2: Second string to compare
            threshold: Similarity threshold (0.0 to 1.0)
            
        Returns:
            True if similarity ratio is above threshold
        """
        normalized1 = self._normalize_text(text1)
        normalized2 = self._normalize_text(text2)
        return SequenceMatcher(None, normalized1, normalized2).ratio() >= threshold
    
    def build_query(self, query_conditions: List[Optional[Any]]) -> Callable:
        """
        Build a TinyDB query from a list of conditions
        
        Args:
            query_conditions: List of query conditions (can contain None values)
            
        Returns:
            Callable query function
        """
        # Filter out None conditions
        valid_conditions = [q for q in query_conditions if q is not None]
        
        if not valid_conditions:
            return lambda _: True
            
        return reduce(lambda x, y: x & y, valid_conditions)
    
    def create_date_filter(self, field_name: str, 
                          start_date: Optional[datetime] = None, 
                          end_date: Optional[datetime] = None) -> List[Any]:
        """
        Create date range filter for a datetime field
        
        Args:
            field_name: Name of the datetime field to filter
            start_date: Optional start date filter
            end_date: Optional end date filter
            
        Returns:
            List of query conditions
        """
        field_query = Query()[field_name]
        queries = []
        
        if start_date:
            queries.append(field_query.test(
                lambda x: datetime.fromisoformat(x) >= start_date
            ))
        if end_date:
            queries.append(field_query.test(
                lambda x: datetime.fromisoformat(x) <= end_date
            ))
        
        return queries