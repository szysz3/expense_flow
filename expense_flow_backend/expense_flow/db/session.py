"""Database session utilities."""

from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path
from typing import AsyncIterator, Dict

from sqlalchemy import event
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from expense_flow.config import get_config

from .models import Base

_ENGINE_CACHE: Dict[str, AsyncEngine] = {}
_SESSION_FACTORY_CACHE: Dict[str, async_sessionmaker[AsyncSession]] = {}


def _normalise_path(path: str) -> str:
    return str(Path(path).expanduser().resolve())


def get_engine(db_path: str | None = None) -> AsyncEngine:
    config = get_config()
    resolved_path = _normalise_path(db_path or config.db_path)

    engine = _ENGINE_CACHE.get(resolved_path)
    if engine is not None:
        return engine

    Path(resolved_path).parent.mkdir(parents=True, exist_ok=True)

    url = f"sqlite+aiosqlite:///{resolved_path}"
    engine = create_async_engine(url, echo=False, future=True)

    @event.listens_for(engine.sync_engine, "connect")
    def _set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA journal_mode=WAL;")
        cursor.execute("PRAGMA synchronous=NORMAL;")
        cursor.execute("PRAGMA foreign_keys=ON;")
        cursor.execute("PRAGMA busy_timeout=5000;")
        cursor.close()

    _ENGINE_CACHE[resolved_path] = engine
    return engine


def _get_session_factory(db_path: str | None = None) -> async_sessionmaker[AsyncSession]:
    config = get_config()
    resolved_path = _normalise_path(db_path or config.db_path)

    factory = _SESSION_FACTORY_CACHE.get(resolved_path)
    if factory is not None:
        return factory

    engine = get_engine(resolved_path)
    factory = async_sessionmaker(engine, expire_on_commit=False)
    _SESSION_FACTORY_CACHE[resolved_path] = factory
    return factory


async def get_async_session(db_path: str | None = None) -> AsyncIterator[AsyncSession]:
    factory = _get_session_factory(db_path)
    async with factory() as session:
        yield session


async def init_db(db_path: str | None = None) -> None:
    engine = get_engine(db_path)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


@asynccontextmanager
async def session_scope(db_path: str | None = None):
    factory = _get_session_factory(db_path)
    async with factory() as session:
        yield session
