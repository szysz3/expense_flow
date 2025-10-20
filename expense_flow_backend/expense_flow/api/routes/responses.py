"""Common response payloads shared across routers."""

from __future__ import annotations

from pydantic import BaseModel


class OperationResponse(BaseModel):
    """Simple success acknowledgement."""

    status: str
