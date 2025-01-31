from enum import Enum
from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, model_validator, validator
from decimal import Decimal

class LLMType(str, Enum):
    LOCAL = "local"
    CHATGPT = "chatgpt"
    
    def __str__(self):
        return self.value

class Category(str, Enum):
    GROCERIES = "groceries"
    ALCOHOLIC_BEVERAGES = "alcoholic_beverages"
    PERSONAL_CARE = "personal_care"
    HOUSEHOLD = "household"
    CLOTHING = "clothing"
    ENTERTAINMENT = "entertainment"
    TRANSPORTATION = "transportation"
    PET = "pet"
    OTHER = "other"

class Merchant(BaseModel):
    name: str
    address: str

class ReceiptItem(BaseModel):
    description: str
    quantity: float
    total_price: Decimal
    category: Category

class Receipt(BaseModel):
    id: Optional[str] = Field(default=None)  # Will be set by database
    merchant: Merchant
    items: List[ReceiptItem]
    total: Decimal
    transaction_datetime: datetime
    added_datetime: datetime = Field(default_factory=datetime.utcnow)

class ProcessReceiptRequest(BaseModel):
    llm_type: LLMType = Field(default=LLMType.LOCAL)

class ErrorDetail(BaseModel):
    error: str
    detail: str
    retry_count: Optional[int] = None

class ProcessReceiptResponse(BaseModel):
    receipt_id: str
    receipt: Receipt
    
class ReceiptQuery(BaseModel):
    merchant_name: Optional[str] = Field(None, description="Name of the merchant to search for")
    start_date: Optional[datetime] = Field(None, description="Start date for the search range")
    end_date: Optional[datetime] = Field(None, description="End date for the search range")
    categories: Optional[List[Category]] = Field(None, description="List of categories to filter by")
    item_description: Optional[str] = Field(None, description="Description of items to search for")
    
    @model_validator(mode='before')
    @classmethod
    def check_unknown_fields(cls, data: Dict[str, Any]) -> Dict[str, Any]:
        allowed_fields = {
            'merchant_name', 'start_date', 'end_date', 
            'categories', 'item_description'
        }
        unknown_fields = set(data.keys()) - allowed_fields
        if unknown_fields:
            raise ValueError(
                f"Unknown field(s): {', '.join(unknown_fields)}. "
                f"Allowed fields are: {', '.join(allowed_fields)}"
            )
        return data
    
    @validator('end_date')
    def validate_date_range(cls, v, values):
        if v and 'start_date' in values and values['start_date']:
            if v < values['start_date']:
                raise ValueError('end_date must be after start_date')
        return v
    
    @validator('categories', each_item=True)
    def validate_categories(cls, v):
        try:
            return Category(v)
        except ValueError:
            valid_categories = [c.value for c in Category]
            raise ValueError(
                f"Invalid category: '{v}'. "
                f"Valid categories are: {', '.join(valid_categories)}"
            )
        
class SearchResultItem(BaseModel):
    description: str
    total_price: str
    category: str

class SearchResult(BaseModel):
    items: List[SearchResultItem]
    total: str    