"""Autocomplete endpoints backed by the vector store."""

from __future__ import annotations

from typing import Any, Dict, List

from fastapi import APIRouter, Depends, HTTPException, Query
from starlette.status import HTTP_400_BAD_REQUEST, HTTP_500_INTERNAL_SERVER_ERROR

from expense_flow.api.constants import ErrorMessages
from expense_flow.api.dependencies import get_vector_store_service
from expense_flow.api.security import verify_api_key
from expense_flow.services.autocomplete_service import AutoCompleteService
from expense_flow.services.vector_store_service import VectorStoreService

router = APIRouter(prefix="/api", tags=["autocomplete"])


@router.get("/autocomplete", response_model=List[Dict[str, Any]])
async def get_autocomplete_suggestions(
    text: str,
    limit: int = Query(8, ge=1, le=10, description="Maximum number of suggestions"),
    _: str = Depends(verify_api_key),
    vector_store_service: VectorStoreService | None = Depends(get_vector_store_service),
) -> List[Dict[str, Any]]:
    """Return autocomplete suggestions for receipt item descriptions."""
    if not text:
        raise HTTPException(
            status_code=HTTP_400_BAD_REQUEST,
            detail={"error": "Missing 'text' query parameter"},
        )

    if not vector_store_service:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": ErrorMessages.INTERNAL_ERROR, "detail": "Vector store unavailable"},
        )

    autocomplete_service = AutoCompleteService(vector_store_service)
    return autocomplete_service.get_suggestions(text, limit)
