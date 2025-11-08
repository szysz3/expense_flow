import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock, patch
import json
from datetime import datetime
import tempfile
import os
from decimal import Decimal

from ..api.app import app, get_repository, get_temp_repository
from ..api.models import Category, LLMType, Receipt, SearchResult, SearchResultItem
from ..api.constants import ErrorMessages, FileTypes
from ..api.services.receipt_ingestion_service import ReceiptIngestionService
from .mock_data import MOCK_RECEIPTS

pytestmark = pytest.mark.asyncio


@pytest.fixture
def repo_mock():
    mock = AsyncMock()
    mock.get_receipt = AsyncMock()
    mock.insert_receipt = AsyncMock()
    mock.search_receipts = AsyncMock()
    return mock


@pytest.fixture
def temp_repo_mock():
    mock = AsyncMock()
    mock.insert_temp_receipt = AsyncMock(return_value="temp-temp-id")
    mock.get_unprocessed_receipts = AsyncMock(return_value=[])
    return mock


@pytest.fixture
def test_client(repo_mock, temp_repo_mock):
    """Test client with overridden dependencies"""
    app.dependency_overrides[get_repository] = lambda: repo_mock
    app.dependency_overrides[get_temp_repository] = lambda: temp_repo_mock
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
    with patch("expense_flow.api.security.verify_api_key", return_value="test_api_key"):
        yield

@pytest.fixture(autouse=True)
def mock_security_config():
    with patch("expense_flow.api.security.get_security_config") as mock:
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
    api_headers,
    temp_repo_mock
):
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp_file:
        temp_file.write(b"fake image data")
        temp_file_path = temp_file.name

    try:
        receipt_data = MOCK_RECEIPTS["smazalnia_receipt"]
        temp_repo_mock.insert_temp_receipt.return_value = "temp-id"
        
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
async def test_analyze_receipt_invalid_ocr_payload(
    test_client,
    api_headers,
    temp_repo_mock,
):
    invalid_receipt_data = {
        "merchant": {"name": "", "address": ""},
        "items": [],
        "total": -1,
        "transaction_datetime": "not-a-date",
    }

    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp_file:
        temp_file.write(b"fake image data")
        temp_file_path = temp_file.name

    try:
        with patch.object(
            ReceiptIngestionService,
            "ingest",
            return_value=invalid_receipt_data,
        ):
            with open(temp_file_path, "rb") as f:
                response = test_client.post(
                    "/api/receipts/analyze",
                    headers=api_headers,
                    files={"file": ("test.jpg", f, FileTypes.JPEG)},
                )

        assert response.status_code == 400
        payload = response.json()
        assert payload["detail"]["error"] == ErrorMessages.VALIDATION_ERROR
        temp_repo_mock.insert_temp_receipt.assert_not_called()
    finally:
        if os.path.exists(temp_file_path):
            os.unlink(temp_file_path)

@pytest.mark.integration
async def test_get_receipt_success(
    test_client,
    api_headers,
    repo_mock
):
    receipt_data = MOCK_RECEIPTS["rossmann_receipt"]
    
    repo_mock.get_receipt.return_value = Receipt(**receipt_data)
    
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
    api_headers,
    repo_mock
):
    repo_mock.get_receipt.return_value = None
    
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
    api_headers,
    repo_mock
):
    mock_items = []
    total = Decimal("0")

    for receipt in MOCK_RECEIPTS.values():
        for item in receipt["items"]:
            if item["category"] == Category.ALCOHOLIC_BEVERAGES.value:
                mock_items.append(
                    SearchResultItem(
                        description=item["description"],
                        total_price=str(item["total_price"]),
                        category=item["category"],
                    )
                )
                total += Decimal(item["total_price"])
    
    repo_mock.search_receipts.return_value = SearchResult(
        items=mock_items,
        total=str(total)
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
    api_headers,
    temp_repo_mock
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
    api_headers,
    repo_mock
):
    from expense_flow.api.repository.base_repository import DatabaseError

    repo_mock.get_receipt.side_effect = DatabaseError("get receipt", "Database error occurred")
    
    response = test_client.get(
        "/api/receipts/some-id",
        headers=api_headers
    )
    
    assert response.status_code == 500
    data = response.json()
    assert data["detail"]["error"] == ErrorMessages.DATABASE_ERROR
    assert "Database error occurred" in data["detail"]["detail"]
