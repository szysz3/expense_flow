#!/usr/bin/env python3

import sys
import os
import logging

# Add parent directory to path to import expense_flow
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from expense_flow.config import get_config
from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.services.vector_store import VectorStoreService
from expense_flow.services.sync import DatabaseSyncService

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def main():
    """Initialize vector database from TinyDB data"""
    logger.info("Starting vector database initialization")
    
    config = get_config()
    repository = ReceiptRepository(config.db_path)
    vector_store = VectorStoreService(config)
    
    sync_service = DatabaseSyncService(vector_store, repository)
    sync_service.populate_vector_store()
    
    logger.info("Vector database initialized successfully")

if __name__ == "__main__":
    main()