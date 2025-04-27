#!/usr/bin/env python3

import sys
import os
import logging
from pathlib import Path
import uuid
import argparse
import json
from typing import Set, Dict, Any, List
from datetime import datetime

# Add project root to Python path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, '../..'))
sys.path.insert(0, PROJECT_ROOT)

from expense_flow.config import get_config
from expense_flow.services.vector_store_service import VectorStoreService
from expense_flow.api.models import Category

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def get_existing_vector_items(vector_store: VectorStoreService) -> Set[str]:
    """
    Get a set of existing vector item identifiers to avoid duplicates
    
    Returns:
        Set of item descriptions (not including receipt_id)
    """
    try:
        # Get all points from the collection
        scroll_results = vector_store.client.scroll(
            collection_name="items",
            limit=1000,  # Process in batches of 1000
            with_payload=True
        )
        
        # Create identifier set from results
        identifiers = set()
        total_items = 0
        
        # Process all batches
        while True:
            results, next_offset = scroll_results
            total_items += len(results)
            
            # Add item descriptions to set
            for item in results:
                description = item.payload.get("description", "").strip().lower()
                if description:
                    identifiers.add(description)
            
            # Check if we've processed all items
            if next_offset is None:
                break
                
            # Get next batch
            scroll_results = vector_store.client.scroll(
                collection_name="items",
                limit=1000,
                offset=next_offset,
                with_payload=True
            )
        
        logger.info(f"Found {total_items} total items in vector database")
        logger.info(f"Found {len(identifiers)} unique item descriptions in vector database")
        
        # Log a few examples for debugging
        if identifiers and logger.isEnabledFor(logging.DEBUG):
            sample = list(identifiers)[:5]
            logger.debug(f"Sample existing descriptions: {sample}")
        
        return identifiers
    except Exception as e:
        logger.warning(f"Error getting existing vector items: {str(e)}")
        return set()  # Return empty set on error

def load_json_files(json_dir: str) -> List[Dict[str, Any]]:
    """
    Load all JSON files from the specified directory
    
    Args:
        json_dir: Directory containing JSON files
        
    Returns:
        List of loaded JSON data
    """
    json_files = []
    dir_path = Path(json_dir)
    
    # Check if directory exists
    if not dir_path.exists() or not dir_path.is_dir():
        logger.error(f"Directory {json_dir} does not exist or is not a directory")
        return []
    
    # Find all JSON files
    file_paths = list(dir_path.glob("*.json"))
    logger.info(f"Found {len(file_paths)} JSON files in {json_dir}")
    
    # Load each JSON file
    for file_path in file_paths:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                # Add file name as ID if not present
                if 'id' not in data:
                    data['id'] = file_path.stem
                json_files.append(data)
                
            if len(json_files) % 10 == 0:
                logger.info(f"Loaded {len(json_files)} JSON files so far...")
                
        except Exception as e:
            logger.error(f"Error loading {file_path}: {str(e)}")
    
    logger.info(f"Successfully loaded {len(json_files)} JSON files")
    return json_files

def extend_vector_db(args):
    """
    Extend vector database with data from JSON files
    """
    logger.info("Starting vector database extension from JSON files")
    
    # Change to project root
    os.chdir(PROJECT_ROOT)
    logger.info(f"Working directory: {os.getcwd()}")
    
    # Get config
    config = get_config()
    logger.info(f"Vector database path: {config.vector_db_path}")
    logger.info(f"JSON files directory: {args.json_dir}")
    
    # Initialize services
    vector_store = VectorStoreService(config)
    
    try:
        # Initialize collections if they don't exist
        vector_store._init_collections()
        
        # Get existing items to avoid duplicates (unless force flag is used)
        existing_items = set() if args.force else get_existing_vector_items(vector_store)
        
        if args.force:
            logger.info("Force flag set - will add all items regardless of duplicates")
        
        if args.dry_run:
            logger.info("Dry run mode - no items will actually be added")
        
        # Load JSON files
        receipts = load_json_files(args.json_dir)
        logger.info(f"Processing {len(receipts)} receipt JSON files")
        
        # Process receipts and add to vector database
        total_items = 0
        added_items = 0
        skipped_items = 0
        unique_descriptions = set()
        all_descriptions = set()
        
        for receipt in receipts:
            # Skip processing if there are no items
            if 'items' not in receipt or not receipt['items']:
                continue
                
            receipt_id = receipt.get('id', str(uuid.uuid4()))
            
            # Process receipt items
            for item in receipt['items']:
                if 'description' not in item or not item['description'].strip():
                    continue
                
                total_items += 1
                
                # Normalize description
                normalized_description = str(item['description']).strip().lower()
                all_descriptions.add(normalized_description)
                unique_descriptions.add(str(item['description']))
                
                # Check if description already exists
                if not args.force and normalized_description in existing_items:
                    skipped_items += 1
                    if logger.isEnabledFor(logging.DEBUG):
                        logger.debug(f"Skipping existing item: {item['description']}")
                    continue
                
                # Get category (default to "other" if not present)
                category = item.get('category', 'other')
                # Validate category
                if not isinstance(category, str) or category not in [c.value for c in Category]:
                    category = 'other'
                
                item_data = {
                    "description": str(item['description']),
                    "category": category,
                    "receipt_id": receipt_id,
                    "normalized_description": normalized_description
                }
                
                # Add item to vector database if not dry run
                if not args.dry_run:
                    vector_store.add_item_embedding(item_data)
                added_items += 1
                
                # Log sample of added items
                if logger.isEnabledFor(logging.DEBUG) and added_items <= 5:
                    logger.debug(f"Added item: {item['description']}")
        
        # Summary statistics
        logger.info(f"Found {total_items} total items in JSON files")
        logger.info(f"Found {len(unique_descriptions)} unique descriptions in JSON files")
        logger.info(f"Found {len(all_descriptions)} normalized unique descriptions in JSON files")
        
        if args.dry_run:
            logger.info(f"Would have added {added_items} new items to vector database (dry run)")
        else:
            logger.info(f"Added {added_items} new items to vector database")
        
        logger.info(f"Skipped {skipped_items} items that already existed in vector database")
        
    except Exception as e:
        logger.error(f"Error extending vector database: {str(e)}", exc_info=True)
        raise

def parse_args():
    parser = argparse.ArgumentParser(description='Extend vector database with items from JSON files')
    parser.add_argument('--json-dir', type=str, default='/home/szysz3/Programming/projects/backups/sample_receipts_validation',
                        help='Directory containing JSON receipt files')
    parser.add_argument('--verbose', '-v', action='store_true', help='Enable verbose logging')
    parser.add_argument('--force', '-f', action='store_true', help='Force adding all items, ignore duplicates')
    parser.add_argument('--dry-run', '-d', action='store_true', help='Dry run, don\'t actually add items')
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    
    # Set log level based on verbosity
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        extend_vector_db(args)
        logger.info("Vector database extension completed successfully")
    except Exception as e:
        logger.error(f"Failed to extend vector database: {str(e)}")
        sys.exit(1)