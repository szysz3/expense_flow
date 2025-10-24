import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock

from expense_flow.api.app import app
from expense_flow.api.dependencies import get_notification_service
from expense_flow.api.models import DevicePlatform
from expense_flow.api.security import verify_api_key


class _ServiceStub:
    def __init__(self):
        self.register_device = AsyncMock()
        self.unregister_device = AsyncMock(return_value=True)

    @property
    def enabled(self):
        return True


@pytest.fixture
def notification_service_mock():
    return _ServiceStub()


@pytest.fixture
def client(notification_service_mock):
    app.dependency_overrides[get_notification_service] = lambda: notification_service_mock
    app.dependency_overrides[verify_api_key] = lambda: "test"
    client = TestClient(app)
    yield client
    app.dependency_overrides = {}


def test_register_device(client, notification_service_mock):
    payload = {"token": "sample-token", "platform": "ios"}

    response = client.post("/api/notifications/devices", json=payload)

    assert response.status_code == 200
    assert response.json()["status"] == "registered"
    notification_service_mock.register_device.assert_awaited_once_with(
        token="sample-token",
        platform=DevicePlatform.IOS,
    )


def test_unregister_device_success(client, notification_service_mock):
    payload = {"token": "sample-token"}
    notification_service_mock.unregister_device.return_value = True

    response = client.delete("/api/notifications/devices", json=payload)

    assert response.status_code == 200
    assert response.json()["status"] == "unregistered"
    notification_service_mock.unregister_device.assert_awaited_once_with(
        token="sample-token"
    )


def test_unregister_device_not_found(client, notification_service_mock):
    payload = {"token": "missing-token"}
    notification_service_mock.unregister_device.return_value = False

    response = client.delete("/api/notifications/devices", json=payload)

    assert response.status_code == 404
    assert response.json()["detail"]["error"] == "Device not registered"
