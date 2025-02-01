import pytest
from fastapi.testclient import TestClient
from ..api.app import app
from datetime import datetime
from decimal import Decimal

@pytest.fixture
def test_client():
    return TestClient(app)

@pytest.fixture
def mock_api_key():
    return "test_api_key"

@pytest.fixture
def api_headers(mock_api_key):
    return {"X-API-Key": mock_api_key}

@pytest.fixture
def sample_receipt_data():
    return {
        "merchant": {
            "name": "Test Store",
            "address": "123 Test St"
        },
        "items": [
            {
                "description": "Test Item",
                "quantity": 1,
                "total_price": Decimal("10.00"),
                "category": "groceries"
            }
        ],
        "total": Decimal("10.00"),
        "transaction_datetime": datetime.now(),
        "added_datetime": datetime.now()
    }
