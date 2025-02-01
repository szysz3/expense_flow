import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import json
from datetime import datetime
import tempfile
import os
from decimal import Decimal

from ..api.app import app, get_repository
from ..api.models import Receipt, Category, LLMType
from ..api.constants import ErrorMessages, FileTypes
from .mock_data import MOCK_RECEIPTS

pytestmark = pytest.mark.asyncio

def get_test_repository():
    """Test repository dependency override"""
    return MagicMock()

@pytest.fixture
def test_client():
    """Test client with overridden dependencies"""
    app.dependency_overrides[get_repository] = get_test_repository
    client = TestClient(app)
    yield client
    app.dependency_overrides = {}

@pytest.fixture
def mock_api_key():
    return "test_api_key"

@pytest.fixture
def api_headers(mock_api_key):
    return {"X-API-Key": mock_api_key}

@pytest.fixture(autouse=True)
def mock_security():
    """Mock the security verification"""
    with patch("api.security.verify_api_key", return_value="test_api_key"):
        yield

@pytest.fixture(autouse=True)
def mock_security_config():
    with patch("api.security.get_security_config") as mock:
        mock.return_value = MagicMock(api_key="test_api_key")
        yield mock

@pytest.fixture(autouse=True)
def mock_image_preprocessor():
    """Mock image preprocessing"""
    with patch("expense_flow.document_processor.image_processor.ImagePreprocessor.process") as mock:
        mock.return_value = ("/tmp/mock_processed.jpg", True)
        yield mock

@pytest.fixture(autouse=True)
def mock_process_image():
    """Mock document processor's process_image method"""
    mock_result = {
        "analyzeResult": {
            "documents": [{
                "fields": {
                    "merchant": {"content": "Test Store"},
                    "total": {"content": "100.00"},
                    "items": {"content": "Test Item"}
                }
            }]
        }
    }
    with patch("expense_flow.document_processor.azure_processor.AzureDocumentProcessor.process_image") as mock:
        mock.return_value = mock_result
        yield mock

@pytest.fixture(autouse=True)
def mock_preprocess_receipt():
    """Mock document processor's preprocess_receipt method"""
    mock_result = {
        "merchant": {
            "name": "Test Store",
            "address": "Test Address"
        },
        "items": [
            {
                "description": "Test Item",
                "quantity": 1,
                "total_price": "10.00",
                "category": "groceries"
            }
        ],
        "total": "10.00",
        "transaction_datetime": datetime.now().isoformat()
    }
    with patch("expense_flow.document_processor.azure_processor.AzureDocumentProcessor.preprocess_receipt") as mock:
        mock.return_value = mock_result
        yield mock

@pytest.fixture(autouse=True)
def mock_env_vars():
    """Mock environment variables needed for tests"""
    with patch.dict(os.environ, {
        'EXPENSE_FLOW_API_KEY': 'test_api_key',
        'AZURE_DOCUMENT_ENDPOINT': 'http://test-endpoint',
        'AZURE_DOCUMENT_KEY': 'test-key',
        'CHATGPT_KEY': 'test-key'
    }):
        yield

@pytest.mark.integration
async def test_analyze_receipt_success(
    test_client,
    api_headers
):
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp_file:
        temp_file.write(b"fake image data")
        temp_file_path = temp_file.name

    try:
        # Configure mock repository through dependency override
        receipt_data = MOCK_RECEIPTS["smazalnia_receipt"]
        app.dependency_overrides[get_repository] = lambda: MagicMock(
            insert_receipt=MagicMock(return_value=receipt_data["id"])
        )
        
        with open(temp_file_path, "rb") as f:
            response = test_client.post(
                "/api/receipts/analyze",
                headers=api_headers,
                files={"file": ("test.jpg", f, FileTypes.JPEG)},
                data={"llm_type": LLMType.LOCAL.value}
            )
        
        assert response.status_code == 200
        data = response.json()
        assert "receipt_id" in data
        assert data["receipt"]["merchant"]["name"] == "Test Store"
            
    finally:
        if os.path.exists(temp_file_path):
            os.unlink(temp_file_path)

@pytest.mark.integration
async def test_analyze_receipt_invalid_file_type(
    test_client,
    api_headers
):
    with tempfile.NamedTemporaryFile(suffix=".txt", delete=False) as temp_file:
        temp_file.write(b"invalid file")
        temp_file_path = temp_file.name

    try:
        with open(temp_file_path, "rb") as f:
            response = test_client.post(
                "/api/receipts/analyze",
                headers=api_headers,
                files={"file": ("test.txt", f, "text/plain")},
                data={"llm_type": LLMType.LOCAL.value}
            )
        
        assert response.status_code == 400
        data = response.json()
        assert data["detail"]["error"] == ErrorMessages.INVALID_FILE_TYPE
        
    finally:
        if os.path.exists(temp_file_path):
            os.unlink(temp_file_path)

@pytest.mark.integration
async def test_get_receipt_success(
    test_client,
    api_headers
):
    receipt_data = MOCK_RECEIPTS["rossmann_receipt"]
    
    # Configure mock repository through dependency override
    app.dependency_overrides[get_repository] = lambda: MagicMock(
        get_receipt=MagicMock(return_value=Receipt(**receipt_data))
    )
    
    response = test_client.get(
        f"/api/receipts/{receipt_data['id']}",
        headers=api_headers
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == receipt_data["id"]
    assert data["merchant"]["name"] == receipt_data["merchant"]["name"]

@pytest.mark.integration
async def test_get_receipt_not_found(
    test_client,
    api_headers
):
    # Configure mock repository through dependency override
    app.dependency_overrides[get_repository] = lambda: MagicMock(
        get_receipt=MagicMock(return_value=None)
    )
    
    response = test_client.get(
        "/api/receipts/nonexistent-id",
        headers=api_headers
    )
    
    assert response.status_code == 404
    data = response.json()
    assert data["detail"]["error"] == ErrorMessages.NOT_FOUND

@pytest.mark.integration
async def test_search_receipts(
    test_client,
    api_headers
):
    mock_items = []
    total = Decimal("0")
    
    for receipt in MOCK_RECEIPTS.values():
        for item in receipt["items"]:
            if item["category"] == Category.ALCOHOLIC_BEVERAGES.value:
                mock_items.append(item)
                total += Decimal(item["total_price"])
    
    # Configure mock repository through dependency override
    app.dependency_overrides[get_repository] = lambda: MagicMock(
        search_receipts=MagicMock(return_value={
            "items": mock_items,
            "total": str(total)
        })
    )
    
    response = test_client.post(
        "/api/receipts/search",
        headers=api_headers,
        json={
            "categories": [Category.ALCOHOLIC_BEVERAGES.value],
            "start_date": "2025-02-01T00:00:00",
            "end_date": "2025-02-02T00:00:00"
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == len(mock_items)
    assert all(
        item["category"] == Category.ALCOHOLIC_BEVERAGES.value 
        for item in data["items"]
    )

@pytest.mark.integration
async def test_search_receipts_invalid_category(
    test_client,
    api_headers
):
    response = test_client.post(
        "/api/receipts/search",
        headers=api_headers,
        json={
            "categories": ["invalid_category"]
        }
    )
    
    assert response.status_code == 422
    data = response.json()
    assert any(
        "Input should be" in error["msg"] and error["type"] == "enum"
        for error in data["detail"]
    )

@pytest.mark.integration
async def test_search_receipts_invalid_date_range(
    test_client,
    api_headers
):
    response = test_client.post(
        "/api/receipts/search",
        headers=api_headers,
        json={
            "start_date": "2025-02-02T00:00:00",
            "end_date": "2025-02-01T00:00:00"  # End date before start date
        }
    )
    
    assert response.status_code == 422
    data = response.json()
    assert "end_date must be after start_date" in str(data["detail"])

@pytest.mark.integration
async def test_unauthorized_access(test_client):
    response = test_client.get("/api/receipts/some-id")
    assert response.status_code == 403
    
    response = test_client.post("/api/receipts/search", json={})
    assert response.status_code == 403

@pytest.mark.integration
async def test_process_receipt_error_handling(
    test_client,
    api_headers
):
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp_file:
        temp_file.write(b"fake image data")
        temp_file_path = temp_file.name

    try:
        # Force a processing error
        with patch("expense_flow.document_processor.azure_processor.AzureDocumentProcessor.process_image") as mock:
            mock.side_effect = Exception("Processing failed")
            
            with open(temp_file_path, "rb") as f:
                response = test_client.post(
                    "/api/receipts/analyze",
                    headers=api_headers,
                    files={"file": ("test.jpg", f, FileTypes.JPEG)},
                    data={"llm_type": LLMType.LOCAL.value}
                )
            
            assert response.status_code == 500
            data = response.json()
            assert data["detail"]["error"] == ErrorMessages.INTERNAL_ERROR
            
    finally:
        if os.path.exists(temp_file_path):
            os.unlink(temp_file_path)

@pytest.mark.integration
async def test_database_error_handling(
    test_client,
    api_headers
):
    # Configure mock repository to raise a DatabaseError
    from ..api.db import DatabaseError
    
    def mock_get_receipt(*args, **kwargs):
        raise DatabaseError("Database error occurred")
    
    app.dependency_overrides[get_repository] = lambda: MagicMock(
        get_receipt=MagicMock(side_effect=mock_get_receipt)
    )
    
    response = test_client.get(
        "/api/receipts/some-id",
        headers=api_headers
    )
    
    assert response.status_code == 500
    data = response.json()
    assert data["detail"]["error"] == ErrorMessages.DATABASE_ERROR
    assert "Database error occurred" in data["detail"]["detail"]