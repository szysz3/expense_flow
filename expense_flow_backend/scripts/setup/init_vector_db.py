#!/usr/bin/env python3
import argparse
import asyncio
import logging
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
sys.path.insert(0, PROJECT_ROOT)

from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.config import get_config
from expense_flow.db import init_db, session_scope
from expense_flow.services.database_sync_service import DatabaseSyncService
from expense_flow.services.vector_store_service import VectorStoreService

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)


async def initialise_vector_db(sqlite_path: str, vector_db_path: str) -> None:
    """Populate the vector database using data stored in SQLite."""
    config = get_config()
    config.db_path = sqlite_path
    config.vector_db_path = vector_db_path

    await init_db(sqlite_path)

    vector_store = VectorStoreService(config)

    async with session_scope(sqlite_path) as session:
        repository = ReceiptRepository(session)
        sync_service = DatabaseSyncService(vector_store, repository)

        try:
            logger.info("Populating vector store from receipt database...")
            await sync_service.populate_vector_store_async()
            logger.info("Vector database initialized successfully")
        except Exception as exc:  # noqa: BLE001
            logger.error("Error initializing vector database: %s", exc)
            logger.info("Initializing empty vector collections as fallback...")
            vector_store._init_collections()
            logger.info("Empty vector database initialized")


def main() -> None:
    parser = argparse.ArgumentParser(description="Initialize vector database from SQLite data")
    parser.add_argument("--db-path", required=True, help="Path to the SQLite database file")
    parser.add_argument("--vector-db-path", required=True, help="Path to the vector database directory")

    args = parser.parse_args()

    logger.info("Starting vector database initialization")
    logger.info("Script directory: %s", SCRIPT_DIR)
    logger.info("Project root: %s", PROJECT_ROOT)
    logger.info("Database path: %s", args.db_path)
    logger.info("Vector database path: %s", args.vector_db_path)

    os.chdir(PROJECT_ROOT)
    logger.info("Changed working directory to: %s", os.getcwd())

    asyncio.run(initialise_vector_db(args.db_path, args.vector_db_path))


if __name__ == "__main__":
    main()
