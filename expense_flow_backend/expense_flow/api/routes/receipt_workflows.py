"""Endpoints responsible for receipt ingestion and analyzer coordination."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from pydantic import ValidationError
from starlette.status import HTTP_400_BAD_REQUEST, HTTP_500_INTERNAL_SERVER_ERROR

from expense_flow.api.constants import ErrorMessages
from expense_flow.api.dependencies import get_temp_receipt_repository
from expense_flow.api.models import ReceiptStatus, TempReceipt, TempReceiptPayload
from expense_flow.api.repository.temp_receipt_repository import TempReceiptRepository
from expense_flow.api.routes.responses import OperationResponse
from expense_flow.api.security import verify_api_key
from expense_flow.api.services.pending_receipt_processor import (
    schedule_pending_receipt_processing,
)
from expense_flow.api.services.receipt_ingestion_service import (
    AzureConfigurationError,
    ReceiptIngestionService,
)

logger = logging.getLogger("expense_flow")

router = APIRouter(tags=["receipt_workflows"])


@router.post("/api/receipts/analyze", response_model=TempReceipt)
async def analyze_receipt(
    file: UploadFile = File(...),
    _: str = Depends(verify_api_key),
    temp_repository: TempReceiptRepository = Depends(get_temp_receipt_repository),
    ingestion_service: ReceiptIngestionService = Depends(ReceiptIngestionService),
):
    """Process a raw receipt upload and store it for deferred LLM analysis."""
    try:
        content = await file.read()
        receipt_data = ingestion_service.ingest(
            file_bytes=content,
            content_type=file.content_type or "",
        )
    except ValueError as exc:
        logger.warning("Invalid receipt upload: %s", exc)
        raise HTTPException(
            status_code=HTTP_400_BAD_REQUEST,
            detail={"error": ErrorMessages.INVALID_FILE_TYPE},
        ) from exc
    except AzureConfigurationError as exc:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": str(exc)},
        ) from exc
    except Exception as exc:  # noqa: BLE001
        logger.error("Error processing receipt: %s", exc, exc_info=True)
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": str(exc)},
        ) from exc

    try:
        TempReceiptPayload.model_validate(receipt_data)
    except ValidationError as exc:
        logger.warning("Invalid OCR payload rejected: %s", exc)
        raise HTTPException(
            status_code=HTTP_400_BAD_REQUEST,
            detail={
                "error": ErrorMessages.VALIDATION_ERROR,
                "detail": "OCR output failed validation",
                "issues": exc.errors(),
            },
        ) from exc

    temp_receipt_id = await temp_repository.insert_temp_receipt(receipt_data)
    schedule_pending_receipt_processing()
    return TempReceipt(
        id=temp_receipt_id,
        raw_data=receipt_data,
        status=ReceiptStatus.PENDING,
    )


@router.post("/api/analyzer/register", response_model=OperationResponse)
async def register_analyzer(
    _: str = Depends(verify_api_key),
) -> OperationResponse:
    """
    Notify the backend that an analyzer worker is available.

    Scheduling is idempotent; if processing is already running it will be left in place.
    """
    schedule_pending_receipt_processing()
    return OperationResponse(status="registered")
