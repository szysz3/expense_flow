"""Application setup for the Expense Flow backend."""

from __future__ import annotations

import logging
from typing import Any, Dict, List

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.status import HTTP_422_UNPROCESSABLE_ENTITY

from expense_flow.api.constants import ErrorMessages
from expense_flow.api.logging_config import setup_logging
from expense_flow.config import get_config
from expense_flow.db import init_db

from .routes import (
    autocomplete,
    chat,
    receipt_workflows,
    receipts,
    temp_receipts,
)

setup_logging()
logger = logging.getLogger("expense_flow")

app = FastAPI(
    title="Receipt Analysis API",
    description="API for analyzing and categorizing receipts",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(receipt_workflows.router)
app.include_router(temp_receipts.router)
app.include_router(receipts.router)
app.include_router(autocomplete.router)
app.include_router(chat.router)


@app.on_event("startup")
async def on_startup() -> None:
    """Ensure databases are initialised before handling requests."""
    config = get_config()
    await init_db(config.db_path)
    if config.temp_db_path != config.db_path:
        await init_db(config.temp_db_path)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    """Customise validation errors to align with existing mobile expectations."""
    errors: List[Dict[str, Any]] = []
    for error in exc.errors():
        if error["type"] == "value_error":
            errors.append(
                {
                    "loc": error.get("loc", []),
                    "msg": error["msg"],
                    "type": "value_error",
                }
            )
        elif error["type"] == "type_error":
            field = error["loc"][-1] if error["loc"] else ""
            errors.append(
                {
                    "loc": error["loc"],
                    "msg": f"Invalid type for field '{field}'. {error['msg']}",
                    "type": "type_error",
                }
            )
        else:
            errors.append(
                {
                    "loc": error["loc"],
                    "msg": error["msg"],
                    "type": error["type"],
                }
            )

    return JSONResponse(
        status_code=HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": errors,
            "error": ErrorMessages.VALIDATION_ERROR,
            "body": exc.body,
        },
    )
