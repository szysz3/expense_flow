from typing import List, Optional, Dict, Any
from datetime import datetime
import uuid
from fastapi.encoders import jsonable_encoder
from tinydb import Query

from .base_repository import BaseRepository, handle_db_errors
from .models import TempReceipt, ReceiptStatus
from .api_config import APIConfig

class TempReceiptRepository(BaseRepository):
    """
    Repository for managing temporary receipts during processing
    
    Provides functionality for:
    - Storing receipt data before processing
    - Tracking receipt processing status
    - Managing the lifecycle of temporary receipts
    """
    
    def __init__(self, api_config: APIConfig):
        """
        Initialize temporary receipt repository
        
        Args:
            api_config: API configuration with temp database path
        """
        super().__init__(api_config.temp_db_path)
        self.TEMP_RECEIPT_DATETIME_FIELDS = ['created_at']

    @handle_db_errors
    def insert_temp_receipt(self, receipt_data: Dict[str, Any]) -> str:
        """
        Store receipt data and return temp receipt ID
        
        Args:
            receipt_data: Raw receipt data to store
            
        Returns:
            Generated UUID for the temporary receipt
        """
        temp_receipt = TempReceipt(
            id=str(uuid.uuid4()),
            raw_data=receipt_data,
            status=ReceiptStatus.PENDING,
            created_at=datetime.utcnow()
        )
        
        # Serialize the receipt for database storage
        serialized_data = self.serialize(
            jsonable_encoder(temp_receipt),
            datetime_fields=self.TEMP_RECEIPT_DATETIME_FIELDS
        )
        
        self.db.insert(serialized_data)
        return temp_receipt.id

    @handle_db_errors
    def _get_receipts_by_status(self, statuses: List[ReceiptStatus]) -> List[TempReceipt]:
        """
        Get receipts with specific statuses
        
        Args:
            statuses: List of statuses to filter by
            
        Returns:
            List of TempReceipt objects sorted by creation time
        """
        receipt_query = Query()
        
        status_queries = [receipt_query.status == status.value for status in statuses]
        if not status_queries:
            query = lambda _: True
        else:
            query = status_queries[0]
            for status_query in status_queries[1:]:
                query = query | status_query
            
        results = self.db.search(query)
        
        receipts = []
        for r in results:
            deserialized = self.deserialize(r, datetime_fields=self.TEMP_RECEIPT_DATETIME_FIELDS)
            receipts.append(TempReceipt(**deserialized))
            
        return sorted(receipts, key=lambda x: x.created_at)

    @handle_db_errors
    def get_unprocessed_receipts(self) -> List[TempReceipt]:
        """
        Get all receipts that aren't in COMPLETED status
        
        Returns:
            List of TempReceipt objects that need processing
        """
        unprocessed_statuses = [
            ReceiptStatus.PENDING,
            ReceiptStatus.PROCESSING,
            ReceiptStatus.ERROR
        ]
        return self._get_receipts_by_status(unprocessed_statuses)

    @handle_db_errors
    def get_pending_receipts(self) -> List[TempReceipt]:
        """
        Get receipts in PENDING status only
        
        Returns:
            List of TempReceipt objects in PENDING status
        """
        return self._get_receipts_by_status([ReceiptStatus.PENDING])

    @handle_db_errors
    def update_status(
        self, 
        receipt_id: str, 
        status: ReceiptStatus, 
        error_message: Optional[str] = None
    ) -> None:
        """
        Update receipt status and optional error message
        
        Args:
            receipt_id: ID of the receipt to update
            status: New status to set
            error_message: Optional error message if status is ERROR
        """
        receipt_query = Query()
        update_data = {"status": status.value}
        if error_message is not None:
            update_data["error_message"] = error_message
            
        self.db.update(update_data, receipt_query.id == receipt_id)

    @handle_db_errors
    def delete_receipt(self, receipt_id: str) -> None:
        """
        Remove receipt from temp storage
        
        Args:
            receipt_id: ID of the receipt to delete
        """
        receipt_query = Query()
        self.db.remove(receipt_query.id == receipt_id)