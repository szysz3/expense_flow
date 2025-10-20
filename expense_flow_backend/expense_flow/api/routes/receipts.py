"""Receipt CRUD and analytics endpoints."""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Dict, List

from fastapi import APIRouter, Depends, HTTPException, Query
from starlette.status import HTTP_500_INTERNAL_SERVER_ERROR, HTTP_404_NOT_FOUND

from expense_flow.api.constants import ErrorMessages
from expense_flow.api.dependencies import get_receipt_repository
from expense_flow.api.models import (
    CategoryResponse,
    CreateReceiptRequest,
    CreateReceiptResponse,
    DailyExpense,
    Merchant,
    MerchantResponse,
    MonthSummaryResponse,
    Receipt,
    ReceiptItem,
    ReceiptItemResponse,
    ReceiptQuery,
    ReceiptResponse,
    SearchResult,
)
from expense_flow.api.repository.base_repository import DatabaseError
from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.api.security import verify_api_key

logger = logging.getLogger("expense_flow")

router = APIRouter(prefix="/api", tags=["receipts"])


def _handle_database_error(error: DatabaseError) -> HTTPException:
    return HTTPException(
        status_code=HTTP_500_INTERNAL_SERVER_ERROR,
        detail={"error": ErrorMessages.DATABASE_ERROR, "detail": str(error)},
    )


@router.get(
    "/receipts/{receipt_id}",
    response_model=Receipt,
    responses={HTTP_404_NOT_FOUND: {"model": Dict[str, str]}},
)
async def get_receipt(
    receipt_id: str,
    _: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_receipt_repository),
) -> Receipt:
    """Retrieve a specific receipt by ID."""
    try:
        receipt = await repository.get_receipt(receipt_id)
        if not receipt:
            raise HTTPException(
                status_code=HTTP_404_NOT_FOUND,
                detail={
                    "error": ErrorMessages.NOT_FOUND,
                    "detail": f"Receipt {receipt_id} not found",
                },
            )
        return receipt
    except DatabaseError as error:
        raise _handle_database_error(error) from error


@router.get("/receipts", response_model=Dict[str, object])
async def list_receipts(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=100, description="Items per page"),
    _: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_receipt_repository),
) -> Dict[str, object]:
    """Paginated receipt listing."""
    try:
        receipts = await repository.get_receipts(page, page_size)
        total_count = await repository.get_receipt_count()
        return {
            "receipts": receipts,
            "total_count": total_count,
            "page": page,
            "page_size": page_size,
        }
    except DatabaseError as error:
        raise _handle_database_error(error) from error


@router.post("/receipts/search", response_model=SearchResult)
async def search_receipts(
    query: ReceiptQuery,
    _: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_receipt_repository),
) -> SearchResult:
    """Search receipts with various filters."""
    try:
        return await repository.search_receipts(
            merchant_name=query.merchant_name,
            start_date=query.start_date,
            end_date=query.end_date,
            categories=query.categories,
            item_description=query.item_description,
        )
    except DatabaseError as error:
        raise _handle_database_error(error) from error


@router.get("/categories", response_model=CategoryResponse)
async def get_categories(
    _: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_receipt_repository),
) -> CategoryResponse:
    """Retrieve categories with aggregated spend."""
    try:
        return await repository.get_categories_with_items()
    except DatabaseError as error:
        raise _handle_database_error(error) from error


@router.get("/months/summary", response_model=MonthSummaryResponse)
async def get_months_summary(
    _: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_receipt_repository),
) -> MonthSummaryResponse:
    """Get monthly spending summaries."""
    try:
        return await repository.get_monthly_summaries()
    except DatabaseError as error:
        raise _handle_database_error(error) from error


@router.get(
    "/months/{year}/{month}/daily-expenses",
    response_model=List[DailyExpense],
)
async def get_daily_expenses(
    year: int,
    month: int,
    _: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_receipt_repository),
) -> List[DailyExpense]:
    """Daily expenses for a particular month."""
    try:
        return await repository.get_daily_expenses(year, month)
    except DatabaseError as error:
        raise _handle_database_error(error) from error


@router.post("/receipts/create", response_model=CreateReceiptResponse)
async def create_receipt(
    request: CreateReceiptRequest,
    _: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_receipt_repository),
) -> CreateReceiptResponse:
    """Create a receipt manually from a single item."""
    try:
        receipt = Receipt(
            merchant=request.merchant or Merchant(),
            items=[
                ReceiptItem(
                    description=request.description,
                    quantity=request.quantity,
                    total_price=request.total_price,
                    category=request.category,
                )
            ],
            total=request.total_price,
            transaction_datetime=request.transaction_datetime
            or datetime.utcnow(),
            added_datetime=datetime.utcnow(),
        )

        receipt_id = await repository.insert_receipt(receipt)
        receipt_response = ReceiptResponse(
            id=receipt_id,
            merchant=MerchantResponse(
                name=receipt.merchant.name,
                address=receipt.merchant.address,
            ),
            items=[
                ReceiptItemResponse(
                    description=item.description,
                    quantity=float(item.quantity),
                    total_price=float(item.total_price),
                    category=item.category.value,
                )
                for item in receipt.items
            ],
            total=float(receipt.total),
            transaction_datetime=receipt.transaction_datetime,
            added_datetime=receipt.added_datetime,
        )
        return CreateReceiptResponse(receipt_id=receipt_id, receipt=receipt_response)
    except DatabaseError as error:
        raise _handle_database_error(error) from error
    except Exception as exc:  # noqa: BLE001
        logger.exception("Unexpected error in create_receipt")
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc)
        ) from exc


@router.put("/receipts/{receipt_id}", response_model=Receipt)
async def update_receipt(
    receipt_id: str,
    receipt: Receipt,
    _: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_receipt_repository),
) -> Receipt:
    """Update an existing receipt."""
    try:
        existing = await repository.get_receipt(receipt_id)
        if not existing:
            raise HTTPException(
                status_code=HTTP_404_NOT_FOUND,
                detail={
                    "error": ErrorMessages.NOT_FOUND,
                    "detail": f"Receipt {receipt_id} not found",
                },
            )

        receipt.id = receipt_id
        if hasattr(existing, "added_datetime"):
            receipt.added_datetime = existing.added_datetime

        success = await repository.update_receipt(receipt)
        if not success:
            raise HTTPException(
                status_code=HTTP_500_INTERNAL_SERVER_ERROR,
                detail={
                    "error": ErrorMessages.DATABASE_ERROR,
                    "detail": f"Failed to update receipt {receipt_id}",
                },
            )
        return receipt
    except DatabaseError as error:
        raise _handle_database_error(error) from error
    except Exception as exc:  # noqa: BLE001
        logger.exception("Unexpected error while updating receipt %s", receipt_id)
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": ErrorMessages.INTERNAL_ERROR,
                "detail": str(exc),
            },
        ) from exc


@router.delete("/receipts/{receipt_id}", response_model=Dict[str, str])
async def delete_receipt(
    receipt_id: str,
    _: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_receipt_repository),
) -> Dict[str, str]:
    """Delete a receipt by ID."""
    try:
        receipt = await repository.get_receipt(receipt_id)
        if not receipt:
            raise HTTPException(
                status_code=HTTP_404_NOT_FOUND,
                detail={
                    "error": ErrorMessages.NOT_FOUND,
                    "detail": f"Receipt {receipt_id} not found",
                },
            )

        success = await repository.delete_receipt(receipt_id)
        if not success:
            raise HTTPException(
                status_code=HTTP_500_INTERNAL_SERVER_ERROR,
                detail={
                    "error": ErrorMessages.DATABASE_ERROR,
                    "detail": f"Failed to delete receipt {receipt_id}",
                },
            )

        return {
            "success": True,
            "message": f"Receipt {receipt_id} deleted successfully",
        }
    except DatabaseError as error:
        raise _handle_database_error(error) from error
    except Exception as exc:  # noqa: BLE001
        logger.exception("Unexpected error while deleting receipt %s", receipt_id)
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": ErrorMessages.INTERNAL_ERROR,
                "detail": str(exc),
            },
        ) from exc
