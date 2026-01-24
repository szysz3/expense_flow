from enum import Enum
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, field_validator, model_validator, validator
from decimal import Decimal
import uuid
import math

# Default values for optional fields
DEFAULT_QUANTITY: float = 1.0

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
    STANDING_ORDERS = "standing_orders"
    OTHER = "other"

class Merchant(BaseModel):
    name: str = Field(default="")
    address: str = Field(default="")
    
    class Config:
        json_schema_extra = {"example": {"name": "", "address": ""}}

class DevicePlatform(str, Enum):
    IOS = "ios"
    ANDROID = "android"

class RegisterDeviceRequest(BaseModel):
    token: str = Field(min_length=1, max_length=512)
    platform: DevicePlatform

class UnregisterDeviceRequest(BaseModel):
    token: str = Field(min_length=1, max_length=512)

class ReceiptItem(BaseModel):
    description: str
    quantity: float = Field(default=DEFAULT_QUANTITY)
    total_price: Decimal
    category: Category

    class Config:
        json_encoders = {
            Decimal: float
        }

    @field_validator("quantity", mode="before")
    @classmethod
    def default_missing_quantity(cls, value: Optional[float]) -> float:
        if value is None:
            return DEFAULT_QUANTITY
        return value

def _utc_now() -> datetime:
    """Return current UTC time as timezone-aware datetime."""
    return datetime.now(timezone.utc)


class Receipt(BaseModel):
    id: Optional[str] = Field(default=None)
    merchant: Merchant = Field(default_factory=Merchant)
    items: List[ReceiptItem]
    total: Decimal
    transaction_datetime: datetime = Field(default_factory=_utc_now)
    added_datetime: datetime = Field(default_factory=_utc_now)

    class Config:
        json_encoders = {
            Decimal: float
        }

    @field_validator("merchant", mode="before")
    @classmethod
    def default_missing_merchant(cls, value: Optional[Merchant]) -> Merchant:
        if value is None:
            return Merchant()
        return value

    @field_validator("transaction_datetime", mode="before")
    @classmethod
    def default_missing_transaction_datetime(
        cls, value: Optional[datetime]
    ) -> datetime:
        if value is None:
            return _utc_now()
        return value

class ProcessReceiptRequest(BaseModel):
    llm_type: LLMType = Field(default=LLMType.LOCAL)

class ErrorDetail(BaseModel):
    error: str
    detail: str
    retry_count: Optional[int] = None

class ProcessReceiptResponse(BaseModel):
    receipt_id: str
    receipt: Receipt
    
class SimpleSuccessResponse(BaseModel):
    success: bool
    message: str
    
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

class CategoryItem(BaseModel):
    id: str
    name: str
    amount: float
    count: int = Field(default=1)

class CategoryWithItems(BaseModel):
    id: str
    name: str
    iconName: str
    items: List[CategoryItem]

class CategoryResponse(BaseModel):
    categories: List[CategoryWithItems]

class CategorySummary(BaseModel):
    id: str
    name: str
    iconName: str
    amount: float
    previousMonthAmount: float

class MonthSummary(BaseModel):
    id: str
    monthNumber: int
    year: int
    previousMonthTotal: float
    categories: List[CategorySummary]

class MonthSummaryResponse(BaseModel):
    months: List[MonthSummary]

def get_category_icon(category: Category) -> str:
    """Get the icon path for a category"""
    return f"packages/presentation/assets/icon_{category.value}.svg"

def get_category_name(category: Category) -> str:
    """Convert category enum value to display name"""
    return " ".join(word.capitalize() for word in category.value.split('_'))    
class MerchantResponse(BaseModel):
    name: str = Field(default="")
    address: str = Field(default="")

    class Config:
        json_schema_extra = {"example": {"name": "", "address": ""}}

class ReceiptItemResponse(BaseModel):
    description: str
    quantity: float
    total_price: float
    category: str

    class Config:
        json_encoders = {
            Decimal: float,
            float: float
        }

class ReceiptResponse(BaseModel):
    id: Optional[str] = None
    merchant: MerchantResponse
    items: List[ReceiptItemResponse]
    total: float
    transaction_datetime: datetime
    added_datetime: datetime

    class Config:
        json_encoders = {
            Decimal: float,
            float: float,
            datetime: lambda v: v.isoformat()
        }

class CreateReceiptRequest(BaseModel):
    description: str
    quantity: float = Field(default=DEFAULT_QUANTITY)
    total_price: Decimal
    category: Category
    merchant: Optional[Merchant] = Field(
        default_factory=lambda: Merchant(name="", address="")
    )
    transaction_datetime: Optional[datetime] = Field(default_factory=_utc_now)

    class Config:
        json_encoders = {
            Decimal: float
        }

class CreateReceiptResponse(BaseModel):
    receipt_id: str
    receipt: ReceiptResponse

    class Config:
        json_encoders = {
            Decimal: float
        }

class ReceiptStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    ERROR = "error"


class TempReceiptMerchant(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None

    @field_validator("name", "address", mode="before")
    @classmethod
    def normalize_optional_text(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        if isinstance(value, str) and not value.strip():
            return None
        return value


class TempReceiptItemPayload(BaseModel):
    description: str
    quantity: Optional[Decimal] = Field(default=None)
    total_price: Decimal = Field(..., ge=0)

    @field_validator("description")
    @classmethod
    def validate_description(cls, value: str) -> str:
        if not value or not value.strip():
            raise ValueError("items[].description must not be empty")
        return value

    @field_validator("quantity", mode="before")
    @classmethod
    def validate_quantity(cls, value: Optional[Decimal]) -> Optional[Decimal]:
        if value is None:
            return None
        if isinstance(value, float) and math.isnan(value):
            raise ValueError("quantity must be finite")
        if value < 0:
            raise ValueError("quantity must be non-negative")
        return value

    @field_validator("total_price", mode="before")
    @classmethod
    def validate_total_price(cls, value: Decimal) -> Decimal:
        if value is None:
            raise ValueError("total_price must not be null")
        if isinstance(value, float) and math.isnan(value):
            raise ValueError("total_price must be finite")
        return value


class TempReceiptPayload(BaseModel):
    merchant: Optional[TempReceiptMerchant] = None
    items: List[TempReceiptItemPayload]
    total: Decimal = Field(..., ge=0)
    transaction_datetime: Optional[datetime] = None

    @field_validator("total", mode="before")
    @classmethod
    def validate_total(cls, value: Decimal) -> Decimal:
        if value is None:
            raise ValueError("total must not be null")
        if isinstance(value, float) and math.isnan(value):
            raise ValueError("total must be finite")
        return value

    @field_validator("transaction_datetime", mode="before")
    @classmethod
    def normalize_transaction_datetime(
        cls, value: Optional[datetime]
    ) -> Optional[datetime]:
        if value is None:
            return None
        if isinstance(value, str) and not value.strip():
            return None
        return value

    @model_validator(mode="after")
    def check_items(self) -> "TempReceiptPayload":
        if not self.items:
            raise ValueError("at least one item is required")
        return self

class TempReceipt(BaseModel):
    id: str
    raw_data: Dict[str, Any]
    status: ReceiptStatus = ReceiptStatus.PENDING
    created_at: datetime = Field(default_factory=_utc_now)
    error_message: Optional[str] = None

class UnprocessedReceiptsResponse(BaseModel):
    receipts: List[TempReceipt]
    total_count: int        

class DailyExpense(BaseModel):
    """Daily expense summary"""
    day: int
    total: Decimal
    transaction_datetime: datetime
    
    class Config:
        json_encoders = {
            Decimal: float
        }    

class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = None
    
class ChatMessage(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    content: str
    sender: str
    timestamp: datetime = Field(default_factory=_utc_now)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
