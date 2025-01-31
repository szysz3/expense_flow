from enum import Enum
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field
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
    merchant_name: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    categories: Optional[List[Category]] = None
    item_description: Optional[str] = None

class SearchResultItem(BaseModel):
    description: str
    total_price: str
    category: str

class SearchResult(BaseModel):
    items: List[SearchResultItem]
    total: str    