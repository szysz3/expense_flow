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
        Normalize text for product comparison while preserving important identifiers
        
        Args:
            text: String to normalize
            
        Returns:
            Normalized string
        """
        # Convert to lowercase and trim whitespace
        normalized = text.lower().strip()
        
        # Normalize whitespace
        normalized = re.sub(r'\s+', ' ', normalized)
        
        # Remove trailing single characters that might be batch codes
        normalized = re.sub(r'[,\s]+[a-zA-Z]$', '', normalized)
        
        # Remove common punctuation but preserve product-relevant symbols
        normalized = re.sub(r'[^\w\s\dx,.]', '', normalized)
        
        return normalized
    
    def _are_similar(self, text1: str, text2: str, threshold: float = 0.9) -> bool:
        """
        Compare two product strings for similarity, handling both spelling variations
        and non-essential product codes
        
        Args:
            text1: First string to compare
            text2: Second string to compare
            threshold: Similarity threshold (0.0 to 1.0)
            
        Returns:
            True if products are considered the same
        """
        normalized1 = self._normalize_text(text1)
        normalized2 = self._normalize_text(text2)
        
        # Overall similarity check
        overall_similarity = SequenceMatcher(None, normalized1, normalized2).ratio()
        if overall_similarity >= threshold:
            return True
        
        # Token-by-token analysis for detecting variations like EXSTRA/EKSTRA
        tokens1 = normalized1.split()
        tokens2 = normalized2.split()
        
        # Check if we have the same number of tokens
        if len(tokens1) == len(tokens2):
            # Count matching and similar tokens
            exact_matches = 0
            similar_tokens = 0
            
            for t1, t2 in zip(tokens1, tokens2):
                if t1 == t2:
                    exact_matches += 1
                elif SequenceMatcher(None, t1, t2).ratio() >= 0.8:
                    similar_tokens += 1
                    
            # If all tokens match exactly except for one that's very similar
            if exact_matches == len(tokens1) - 1 and similar_tokens == 1:
                return True
                
            # Or if most tokens match exactly and the remaining are similar
            total_token_count = len(tokens1)
            if (exact_matches + similar_tokens == total_token_count and 
                exact_matches >= total_token_count * 0.7):
                return True
        
        # Check product core (name part before quantities)
        # Extract the main product name (everything before quantities)
        def extract_product_core(text):
            # Match everything up to a number followed by unit (g, ml, tb, etc.)
            match = re.match(r'^(.*?)(?:\d+\s*(?:[a-z]+))', text, re.IGNORECASE)
            return match.group(1).strip() if match else text
        
        core1 = extract_product_core(normalized1)
        core2 = extract_product_core(normalized2)
        
        # Check if the product cores are very similar
        core_similarity = SequenceMatcher(None, core1, core2).ratio()
        if core_similarity >= 0.9:
            # Extract and compare quantities separately
            quantity1 = normalized1[len(core1):].strip()
            quantity2 = normalized2[len(core2):].strip()
            
            quantity_similarity = SequenceMatcher(None, quantity1, quantity2).ratio()
            if quantity_similarity >= 0.9:
                return True
        
        return False
    
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