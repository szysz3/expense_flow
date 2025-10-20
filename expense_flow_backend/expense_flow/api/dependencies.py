"""Dependency providers shared across API routers."""

from __future__ import annotations

from typing import AsyncIterator, Callable

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from expense_flow.analyzers.chatgpt_analyzer import ChatGPTAnalyzer
from expense_flow.analyzers.local_llm_analyzer import LocalLLMAnalyzer
from expense_flow.api.models import LLMType
from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.api.repository.temp_receipt_repository import TempReceiptRepository
from expense_flow.config import get_config
from expense_flow.db import get_async_session
from expense_flow.services.chat_service import ChatService
from expense_flow.services.vector_store_service import VectorStoreService


async def get_db_session() -> AsyncIterator[AsyncSession]:
    """Yield a session for the primary receipt database."""
    async for session in get_async_session():
        yield session


async def get_temp_db_session() -> AsyncIterator[AsyncSession]:
    """Yield a session scoped to the temporary receipt database."""
    config = get_config()
    async for session in get_async_session(config.temp_db_path):
        yield session


async def get_receipt_repository(
    session: AsyncSession = Depends(get_db_session),
) -> ReceiptRepository:
    """Provide a receipt repository instance."""
    return ReceiptRepository(session)


async def get_temp_receipt_repository(
    session: AsyncSession = Depends(get_temp_db_session),
) -> TempReceiptRepository:
    """Provide a temporary receipt repository instance."""
    return TempReceiptRepository(session)


def get_chat_service() -> ChatService:
    """Create a chat service bound to current configuration."""
    return ChatService(get_config())


def get_vector_store_service() -> VectorStoreService | None:
    """Return a vector store service if the backend is configured for it."""
    config = get_config()
    try:
        return VectorStoreService(config)
    except Exception:  # pragma: no cover - optional dependency
        return None


def get_analyzer_factory() -> Callable[[LLMType], LocalLLMAnalyzer | ChatGPTAnalyzer]:
    """Return a factory that instantiates analyzers based on the requested LLM type."""
    config = get_config()
    mapping = {
        LLMType.LOCAL: LocalLLMAnalyzer,
        LLMType.CHATGPT: ChatGPTAnalyzer,
    }

    def factory(llm_type: LLMType):
        analyzer_class = mapping.get(llm_type)
        if not analyzer_class:
            raise ValueError(f"Unsupported LLM type: {llm_type}")
        return analyzer_class(config)

    return factory
