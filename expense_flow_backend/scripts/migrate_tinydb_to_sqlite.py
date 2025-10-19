#!/usr/bin/env python3
"""Migrate legacy TinyDB data files to the new SQLite storage."""

import argparse
import asyncio
import logging
import os
import sys
from datetime import datetime
from typing import Iterable

from tinydb import TinyDB

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
sys.path.insert(0, PROJECT_ROOT)

from expense_flow.api.models import Receipt, ReceiptStatus, TempReceipt
from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.config import get_config
from expense_flow.db import init_db, session_scope
from expense_flow.db.models import TempReceiptORM

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("expense_flow.migrate")


def load_tinydb_records(path: str) -> Iterable[dict]:
    db = TinyDB(path)
    try:
        return list(db.all())
    finally:
        db.close()


async def migrate_receipts(tinydb_path: str, sqlite_path: str) -> None:
    logger.info("Migrating receipts from %s to %s", tinydb_path, sqlite_path)
    await init_db(sqlite_path)

    records = load_tinydb_records(tinydb_path)
    config = get_config()
    original_db_path = config.db_path
    original_vector_path = getattr(config, "vector_db_path", "")
    config.db_path = sqlite_path
    config.vector_db_path = ""  # Disable vector sync during migration

    async with session_scope(sqlite_path) as session:
        repository = ReceiptRepository(session)
        for record in records:
            receipt = Receipt(**record)
            await repository.insert_receipt(receipt)

    config.db_path = original_db_path
    config.vector_db_path = original_vector_path


async def migrate_temp_receipts(tinydb_path: str, sqlite_path: str) -> None:
    logger.info("Migrating temporary receipts from %s to %s", tinydb_path, sqlite_path)
    await init_db(sqlite_path)

    records = load_tinydb_records(tinydb_path)

    async with session_scope(sqlite_path) as session:
        for record in records:
            created_at_raw = record.get("created_at")
            created_at = (
                datetime.fromisoformat(created_at_raw)
                if isinstance(created_at_raw, str)
                else datetime.utcnow()
            )

            model = TempReceiptORM(
                id=record["id"],
                raw_data=record["raw_data"],
                status=record.get("status", ReceiptStatus.PENDING.value),
                created_at=created_at,
                error_message=record.get("error_message"),
            )
            session.add(model)

        await session.commit()


async def run_migration(args) -> None:
    if args.receipts_tinydb:
        await migrate_receipts(args.receipts_tinydb, args.receipts_sqlite)

    if args.temp_tinydb:
        target_temp_sqlite = args.temp_sqlite or args.receipts_sqlite
        await migrate_temp_receipts(args.temp_tinydb, target_temp_sqlite)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Migrate TinyDB data to SQLite")
    parser.add_argument("--receipts-tinydb", required=True, help="Path to the legacy receipts TinyDB file")
    parser.add_argument("--receipts-sqlite", required=True, help="Destination SQLite database for receipts")
    parser.add_argument("--temp-tinydb", help="Path to the legacy temporary receipts TinyDB file")
    parser.add_argument("--temp-sqlite", help="Destination SQLite database for temporary receipts")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    os.chdir(PROJECT_ROOT)
    asyncio.run(run_migration(args))


if __name__ == "__main__":
    main()
