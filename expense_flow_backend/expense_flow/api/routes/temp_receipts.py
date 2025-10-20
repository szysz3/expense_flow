"""Endpoints that operate on temporary receipts awaiting analysis."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException
from starlette.status import HTTP_404_NOT_FOUND, HTTP_500_INTERNAL_SERVER_ERROR

from expense_flow.api.constants import ErrorMessages
from expense_flow.api.dependencies import get_temp_receipt_repository
from expense_flow.api.models import TempReceipt, UnprocessedReceiptsResponse
from expense_flow.api.repository.base_repository import DatabaseError
from expense_flow.api.repository.temp_receipt_repository import TempReceiptRepository
from expense_flow.api.security import verify_api_key

logger = logging.getLogger("expense_flow")

router = APIRouter(prefix="/api", tags=["temp_receipts"])


def _db_failure(detail: str) -> HTTPException:
    return HTTPException(
        status_code=HTTP_500_INTERNAL_SERVER_ERROR,
        detail={"error": ErrorMessages.DATABASE_ERROR, "detail": detail},
    )


@router.get("/receipts/unprocessed", response_model=UnprocessedReceiptsResponse)
async def list_unprocessed_receipts(
    _: str = Depends(verify_api_key),
    repository: TempReceiptRepository = Depends(get_temp_receipt_repository),
) -> UnprocessedReceiptsResponse:
    """Return all receipts that are not yet fully processed."""
    try:
        receipts = await repository.get_unprocessed_receipts()
        return UnprocessedReceiptsResponse(
            receipts=receipts,
            total_count=len(receipts),
        )
    except DatabaseError as error:
        logger.error("Failed to fetch unprocessed receipts: %s", error)
        raise _db_failure(str(error)) from error


@router.put("/temp-receipts/{receipt_id}", response_model=TempReceipt)
async def update_temp_receipt(
    receipt_id: str,
    temp_receipt: TempReceipt,
    _: str = Depends(verify_api_key),
    repository: TempReceiptRepository = Depends(get_temp_receipt_repository),
) -> TempReceipt:
    """Update a temporary receipt by ID."""
    try:
        existing = await repository.get_temp_receipt(receipt_id)
        if not existing:
            raise HTTPException(
                status_code=HTTP_404_NOT_FOUND,
                detail={
                    "error": ErrorMessages.NOT_FOUND,
                    "detail": f"Temporary receipt {receipt_id} not found",
                },
            )

        temp_receipt.id = receipt_id
        if hasattr(existing, "created_at"):
            temp_receipt.created_at = existing.created_at

        success = await repository.update_receipt(temp_receipt)
        if not success:
            raise _db_failure(f"Failed to update temporary receipt {receipt_id}")
        return temp_receipt
    except DatabaseError as error:
        logger.error(
            "Database error while updating temporary receipt %s: %s",
            receipt_id,
            error,
        )
        raise _db_failure(str(error)) from error
    except Exception as exc:  # noqa: BLE001
        logger.exception(
            "Unexpected error while updating temporary receipt %s", receipt_id
        )
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": ErrorMessages.INTERNAL_ERROR, "detail": str(exc)},
        ) from exc


@router.delete("/temp-receipts/{receipt_id}", response_model=dict)
async def delete_temp_receipt(
    receipt_id: str,
    _: str = Depends(verify_api_key),
    repository: TempReceiptRepository = Depends(get_temp_receipt_repository),
) -> dict:
    """Delete a temporary receipt by ID."""
    try:
        temp_receipt = await repository.get_temp_receipt(receipt_id)
        if not temp_receipt:
            return {
                "success": True,
                "message": f"Temporary receipt {receipt_id} already removed",
            }

        success = await repository.delete_receipt(receipt_id)
        if not success:
            raise _db_failure(f"Failed to delete temporary receipt {receipt_id}")

        return {
            "success": True,
            "message": f"Temporary receipt {receipt_id} deleted successfully",
        }
    except DatabaseError as error:
        logger.error(
            "Database error while deleting temporary receipt %s: %s",
            receipt_id,
            error,
        )
        raise _db_failure(str(error)) from error
    except Exception as exc:  # noqa: BLE001
        logger.exception(
            "Unexpected error while deleting temporary receipt %s", receipt_id
        )
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": ErrorMessages.INTERNAL_ERROR, "detail": str(exc)},
        ) from exc
