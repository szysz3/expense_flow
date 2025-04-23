from typing import List
from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.services.vector_store import VectorStoreService
from expense_flow.api.models import Receipt
import logging

logger = logging.getLogger("expense_flow")

class DatabaseSyncService:
    """Service for keeping TinyDB and vector database in sync"""
    
    def __init__(self, vector_store_service: VectorStoreService, receipt_repository: ReceiptRepository):
        """
        Initialize database sync service
        
        Args:
            vector_store_service: Vector store service
            receipt_repository: Receipt repository
        """
        self.vector_store = vector_store_service
        self.repository = receipt_repository
    
    def populate_vector_store(self):
        """Populate vector store from TinyDB data"""
        # Get all receipts
        receipts = self.repository.get_all_receipts()
        
        total_items = 0
        unique_items = set() 
        
        for receipt in receipts:
            for item in receipt.items:
                if not item.description.strip():
                    continue
                    
                item_data = {
                    "description": item.description,
                    "category": item.category.value,
                    "receipt_id": receipt.id
                }
                
                self.vector_store.add_item_embedding(item_data)
                total_items += 1
                unique_items.add(item.description)
                
        logger.info(f"Populated vector store with {total_items} items ({len(unique_items)} unique) from {len(receipts)} receipts")
    
    def sync_receipt_items(self, receipt: Receipt):
        """
        Sync a receipt's items to the vector store
        
        Args:
            receipt: Receipt to sync
        """
        for item in receipt.items:
            if not item.description.strip():
                continue
                
            item_data = {
                "description": item.description,
                "category": item.category.value,
                "receipt_id": receipt.id
            }
            
            self.vector_store.add_item_embedding(item_data)
            
        logger.info(f"Synced receipt {receipt.id} items to vector store")
    
    def remove_receipt_items(self, receipt_id: str):
        """
        Remove all items for a specific receipt from the vector store
        
        Args:
            receipt_id: ID of the receipt
        """
        try:
            self.vector_store.delete_items_by_receipt_id(receipt_id)
            logger.info(f"Removed items for receipt {receipt_id} from vector store")
        except Exception as e:
            logger.error(f"Error removing items for receipt {receipt_id}: {str(e)}")