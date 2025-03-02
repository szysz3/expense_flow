from typing import List, Optional, Dict, Any
from datetime import datetime
import uuid
from fastapi.encoders import jsonable_encoder
from tinydb import Query

from .base_repository import BaseRepository
from .models import TempReceipt, ReceiptStatus
from .api_config import APIConfig

class TempReceiptRepository(BaseRepository):
    def __init__(self, api_config: APIConfig):
        super().__init__(api_config.temp_db_path)

    def insert_temp_receipt(self, receipt_data: Dict[str, Any]) -> str:
        """Store receipt data and return temp receipt ID"""
        temp_receipt = TempReceipt(
            id=str(uuid.uuid4()),
            raw_data=receipt_data,
            status=ReceiptStatus.PENDING,
            created_at=datetime.utcnow()
        )
        
        # Serialize datetime fields
        serialized_data = jsonable_encoder(temp_receipt)
        
        self.db.insert(serialized_data)
        return temp_receipt.id

    def get_unprocessed_receipts(self) -> List[TempReceipt]:
        """Get all receipts that aren't in COMPLETED status"""
        Receipt = Query()
        results = self.db.search(
            (Receipt.status == ReceiptStatus.PENDING.value) | 
            (Receipt.status == ReceiptStatus.PROCESSING.value) |
            (Receipt.status == ReceiptStatus.ERROR.value)
        )
        
        # Convert to TempReceipt objects and sort by created_at
        receipts = []
        for r in results:
            # Convert created_at back to datetime if it's a string
            if isinstance(r.get('created_at'), str):
                r['created_at'] = datetime.fromisoformat(r['created_at'])
            receipts.append(TempReceipt(**r))
            
        return sorted(receipts, key=lambda x: x.created_at)

    def get_pending_receipts(self) -> List[TempReceipt]:
        """Get receipts in PENDING status only"""
        Receipt = Query()
        results = self.db.search(Receipt.status == ReceiptStatus.PENDING.value)
        
        receipts = []
        for r in results:
            # Convert created_at back to datetime if it's a string
            if isinstance(r.get('created_at'), str):
                r['created_at'] = datetime.fromisoformat(r['created_at'])
            receipts.append(TempReceipt(**r))
            
        return receipts

    def update_status(
        self, 
        receipt_id: str, 
        status: ReceiptStatus, 
        error_message: Optional[str] = None
    ):
        """Update receipt status and optional error message"""
        Receipt = Query()
        update_data = {"status": status.value}
        if error_message is not None:
            update_data["error_message"] = error_message
        self.db.update(update_data, Receipt.id == receipt_id)

    def delete_receipt(self, receipt_id: str):
        """Remove receipt from temp storage"""
        Receipt = Query()
        self.db.remove(Receipt.id == receipt_id)