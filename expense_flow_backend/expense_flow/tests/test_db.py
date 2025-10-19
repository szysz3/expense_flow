import asyncio
from datetime import datetime
from decimal import Decimal
from pathlib import Path

import pytest

from expense_flow.api.models import Category, Receipt
from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.config import get_config
from expense_flow.db import init_db, session_scope
from .mock_data import MOCK_RECEIPTS


@pytest.fixture
async def repository(tmp_path):
    """Provide an async receipt repository backed by a temporary SQLite database."""
    db_path = tmp_path / "test_receipts.sqlite3"
    await init_db(str(db_path))

    config = get_config()
    original_db_path = config.db_path
    original_vector_path = getattr(config, "vector_db_path", "")
    config.db_path = str(db_path)
    config.vector_db_path = ""

    async with session_scope(str(db_path)) as session:
        yield ReceiptRepository(session)

    config.db_path = original_db_path
    config.vector_db_path = original_vector_path


@pytest.fixture
async def populated_repository(repository: ReceiptRepository):
    """Populate the repository with test receipts."""
    for receipt_data in MOCK_RECEIPTS.values():
        await repository.insert_receipt(Receipt(**receipt_data))
    return repository


@pytest.mark.asyncio
async def test_insert_and_get_receipt(repository: ReceiptRepository):
    receipt_data = MOCK_RECEIPTS["smazalnia_receipt"]
    receipt = Receipt(**receipt_data)

    receipt_id = await repository.insert_receipt(receipt)
    assert receipt_id

    stored_receipt = await repository.get_receipt(receipt_id)
    assert stored_receipt is not None
    assert stored_receipt.merchant.name == receipt.merchant.name
    assert stored_receipt.total == Decimal(receipt.total)
    assert len(stored_receipt.items) == len(receipt.items)


@pytest.mark.asyncio
async def test_get_nonexistent_receipt(repository: ReceiptRepository):
    assert await repository.get_receipt("nonexistent-id") is None


@pytest.mark.asyncio
async def test_search_by_merchant(populated_repository: ReceiptRepository):
    results = await populated_repository.search_receipts(merchant_name="Rossmann")
    assert results.items
    total = sum(Decimal(item.total_price) for item in results.items)
    assert Decimal(results.total) == total


@pytest.mark.asyncio
async def test_search_by_category(populated_repository: ReceiptRepository):
    results = await populated_repository.search_receipts(categories=[Category.ALCOHOLIC_BEVERAGES])
    assert results.items
    assert all(item.category == Category.ALCOHOLIC_BEVERAGES.value for item in results.items)


@pytest.mark.asyncio
async def test_get_receipt_count(populated_repository: ReceiptRepository):
    count = await populated_repository.get_receipt_count()
    assert count == len(MOCK_RECEIPTS)


@pytest.mark.asyncio
async def test_get_daily_expenses(populated_repository: ReceiptRepository):
    sample_receipt = MOCK_RECEIPTS["smazalnia_receipt"]
    timestamp = datetime.fromisoformat(sample_receipt["transaction_datetime"])
    year = timestamp.year
    month = timestamp.month

    expenses = await populated_repository.get_daily_expenses(year, month)
    assert expenses
    assert any(expense.total > 0 for expense in expenses)
