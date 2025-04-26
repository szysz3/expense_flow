#!/usr/bin/env python3

import sys
import os
import logging
from pathlib import Path
import json
import uuid

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, '../..'))

sys.path.insert(0, PROJECT_ROOT)

from expense_flow.config import get_config
from expense_flow.api.models import Receipt, Category
from expense_flow.services.vector_store_service import VectorStoreService

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def initialize_empty_vector_db():
    """Initialize an empty vector database for testing"""
    logger.info("Initializing empty vector database for testing")
    
    config = get_config()
    logger.info(f"Vector database path: {config.vector_db_path}")
    
    vector_store = VectorStoreService(config)
    vector_store._init_collections()
    
    logger.info("Empty vector database initialized successfully")

def main():
    """Initialize vector database for testing"""
    logger.info("Starting test vector database initialization")
    
    os.chdir(PROJECT_ROOT)
    logger.info(f"Changed working directory to: {os.getcwd()}")
    
    try:
        initialize_empty_vector_db()
        logger.info("Test vector database setup complete")
    except Exception as e:
        logger.error(f"Error initializing test vector database: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()