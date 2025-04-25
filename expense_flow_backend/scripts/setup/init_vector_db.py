#!/usr/bin/env python3

import sys
import os
import logging
from pathlib import Path

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, '../..'))

sys.path.insert(0, PROJECT_ROOT)

from expense_flow.config import get_config
from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.services.vector_store import VectorStoreService
from expense_flow.services.sync import DatabaseSyncService

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def main():
    """Initialize vector database from TinyDB data"""
    logger.info("Starting vector database initialization")
    logger.info(f"Script directory: {SCRIPT_DIR}")
    logger.info(f"Project root: {PROJECT_ROOT}")
    
    os.chdir(PROJECT_ROOT)
    logger.info(f"Changed working directory to: {os.getcwd()}")
    
    config = get_config()
    logger.info(f"Database path: {config.db_path}")
    logger.info(f"Vector database path: {config.vector_db_path}")
    
    repository = ReceiptRepository(config.db_path)
    vector_store = VectorStoreService(config)
    sync_service = DatabaseSyncService(vector_store, repository)
    
    try:
        logger.info("Populating vector store from receipt database...")
        sync_service.populate_vector_store()
        logger.info("Vector database initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing vector database: {str(e)}")
        logger.info("Initializing empty vector collections as fallback...")
        vector_store._init_collections()
        logger.info("Empty vector database initialized")

if __name__ == "__main__":
    main()