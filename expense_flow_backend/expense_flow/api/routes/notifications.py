"""Endpoints for managing Firebase Cloud Messaging registrations."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, status

from expense_flow.api.constants import ErrorMessages
from expense_flow.api.dependencies import get_notification_service
from expense_flow.api.models import RegisterDeviceRequest, UnregisterDeviceRequest
from expense_flow.api.routes.responses import OperationResponse
from expense_flow.api.security import verify_api_key
from expense_flow.services.notification_service import NotificationService

logger = logging.getLogger("expense_flow")

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


@router.post(
    "/devices",
    response_model=OperationResponse,
    status_code=status.HTTP_200_OK,
)
async def register_device(
    payload: RegisterDeviceRequest,
    _: str = Depends(verify_api_key),
    notification_service: NotificationService = Depends(get_notification_service),
) -> OperationResponse:
    """Register a mobile client for receipt notifications."""
    await notification_service.register_device(
        token=payload.token,
        platform=payload.platform,
    )
    logger.debug(
        "Registered device for platform %s.",
        payload.platform.value,
    )
    return OperationResponse(status="registered")


@router.delete(
    "/devices",
    response_model=OperationResponse,
    status_code=status.HTTP_200_OK,
)
async def unregister_device(
    payload: UnregisterDeviceRequest,
    _: str = Depends(verify_api_key),
    notification_service: NotificationService = Depends(get_notification_service),
) -> OperationResponse:
    """Unregister a mobile client from receipt notifications."""
    removed = await notification_service.unregister_device(token=payload.token)
    if not removed:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": ErrorMessages.DEVICE_NOT_REGISTERED},
        )

    logger.debug("Unregistered device token.")
    return OperationResponse(status="unregistered")
