"""Route modules bundled for inclusion in the FastAPI app."""

from . import (
    autocomplete,
    chat,
    notifications,
    receipt_workflows,
    receipts,
    temp_receipts,
)

__all__ = [
    "autocomplete",
    "chat",
    "notifications",
    "receipt_workflows",
    "receipts",
    "temp_receipts",
]
