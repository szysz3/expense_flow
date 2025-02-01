import pytest
from datetime import datetime, timedelta
from decimal import Decimal
from ..api.db import ReceiptRepository, DatabaseError
from ..api.models import Receipt, Category
from .mock_data import MOCK_RECEIPTS

@pytest.fixture
def repository():
    """Create a new repository instance with in-memory database"""
    return ReceiptRepository(db_path=":memory:")

@pytest.fixture
def populated_repository(repository):
    """Create a repository pre-populated with test data"""
    for receipt_data in MOCK_RECEIPTS.values():
        receipt = Receipt(**receipt_data)
        repository.insert_receipt(receipt)
    return repository

@pytest.mark.unit
def test_insert_and_get_receipt(repository):
    """Test inserting and retrieving a receipt"""
    receipt_data = MOCK_RECEIPTS["smazalnia_receipt"]
    receipt = Receipt(**receipt_data)
    
    # Insert receipt
    receipt_id = repository.insert_receipt(receipt)
    assert receipt_id is not None
    
    # Retrieve and verify
    stored_receipt = repository.get_receipt(receipt_id)
    assert stored_receipt is not None
    assert stored_receipt.merchant.name == receipt.merchant.name
    assert stored_receipt.total == Decimal(receipt.total)
    assert len(stored_receipt.items) == len(receipt.items)

@pytest.mark.unit
def test_get_nonexistent_receipt(repository):
    """Test retrieving a non-existent receipt"""
    assert repository.get_receipt("nonexistent-id") is None

@pytest.mark.unit
def test_search_by_merchant(populated_repository):
    """Test searching receipts by merchant name"""
    results = populated_repository.search_receipts(merchant_name="Rossmann")
    
    assert results is not None
    assert len(results["items"]) > 0  # Changed from results.items to results["items"]
    total = sum(Decimal(item["total_price"]) for item in results["items"])
    assert Decimal(results["total"]) == total

@pytest.mark.unit
def test_search_by_date_range(populated_repository):
    """Test searching receipts by date range"""
    start_date = datetime(2025, 2, 1)
    end_date = datetime(2025, 2, 2)
    
    results = populated_repository.search_receipts(
        start_date=start_date,
        end_date=end_date
    )
    
    assert results is not None
    assert len(results["items"]) > 0  # Changed from results.items
    
    # Verify all results are within date range
    for receipt in populated_repository.db.all():
        receipt_date = datetime.fromisoformat(receipt["transaction_datetime"])
        if start_date <= receipt_date <= end_date:
            assert any(
                item["description"] in str(receipt["items"]) 
                for item in results["items"]
            )

@pytest.mark.unit
def test_search_by_category(populated_repository):
    """Test searching receipts by category"""
    results = populated_repository.search_receipts(
        categories=[Category.ALCOHOLIC_BEVERAGES]
    )
    
    assert results is not None
    assert len(results["items"]) > 0
    
    # Verify all results are of the correct category
    for item in results["items"]:
        assert item["category"] == Category.ALCOHOLIC_BEVERAGES.value

@pytest.mark.unit
def test_search_by_item_description(populated_repository):
    """Test searching receipts by item description"""
    results = populated_repository.search_receipts(item_description="PIWO")
    
    assert results is not None
    assert len(results["items"]) > 0
    assert any("PIWO" in item["description"] for item in results["items"])

@pytest.mark.unit
def test_combined_search(populated_repository):
    """Test searching with multiple criteria"""
    results = populated_repository.search_receipts(
        merchant_name="Lidi",
        categories=[Category.ALCOHOLIC_BEVERAGES],
        start_date=datetime(2025, 2, 1),
        end_date=datetime(2025, 2, 2)
    )
    
    assert results is not None
    assert len(results["items"]) > 0
    assert any("Tyskie" in item["description"] for item in results["items"])

@pytest.mark.unit
def test_empty_search_results(populated_repository):
    """Test search with criteria that should return no results"""
    results = populated_repository.search_receipts(
        merchant_name="NonexistentStore"
    )
    
    assert results is not None
    assert len(results["items"]) == 0
    assert results["total"] == "0"