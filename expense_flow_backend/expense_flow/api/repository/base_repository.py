from __future__ import annotations

from typing import Callable
from decimal import Decimal
from datetime import datetime
from functools import wraps
from difflib import SequenceMatcher
import re

from sqlalchemy.ext.asyncio import AsyncSession


class DatabaseError(Exception):
    """Exception for database operations with additional context."""

    def __init__(self, operation: str, details: str, original_exception: Exception | None = None):
        self.operation = operation
        self.details = details
        self.original_exception = original_exception
        message = f"Database operation '{operation}' failed: {details}"
        if original_exception:
            message += f" Original error: {original_exception}"
        super().__init__(message)


def handle_db_errors(func: Callable):
    """Decorator that wraps repository methods with error handling."""

    @wraps(func)
    async def wrapper(*args, **kwargs):
        session = None
        if args:
            candidate = getattr(args[0], "session", None)
            if isinstance(candidate, AsyncSession):
                session = candidate
        try:
            return await func(*args, **kwargs)
        except DatabaseError:
            raise
        except Exception as exc:
            if session is not None:
                await session.rollback()
            operation = func.__name__.replace("_", " ")
            raise DatabaseError(operation, "Operation failed", exc) from exc

    return wrapper


class BaseRepository:
    """Common helpers for repositories."""

    def __init__(self, session: AsyncSession):
        self.session = session

    @staticmethod
    def _normalize_text(text: str) -> str:
        normalized = text.lower().strip()
        normalized = re.sub(r"\s+", " ", normalized)
        normalized = re.sub(r"[,\s]+[a-zA-Z]$", "", normalized)
        normalized = re.sub(r"[^\w\s\dx,.]", "", normalized)
        return normalized

    @classmethod
    def _are_similar(cls, text1: str, text2: str, threshold: float = 0.9) -> bool:
        normalized1 = cls._normalize_text(text1)
        normalized2 = cls._normalize_text(text2)

        if SequenceMatcher(None, normalized1, normalized2).ratio() >= threshold:
            return True

        tokens1 = normalized1.split()
        tokens2 = normalized2.split()

        if len(tokens1) == len(tokens2):
            exact_matches = 0
            similar_tokens = 0

            for t1, t2 in zip(tokens1, tokens2):
                if t1 == t2:
                    exact_matches += 1
                elif SequenceMatcher(None, t1, t2).ratio() >= 0.8:
                    similar_tokens += 1

            total_tokens = len(tokens1)
            if exact_matches == total_tokens - 1 and similar_tokens == 1:
                return True
            if exact_matches + similar_tokens == total_tokens and exact_matches >= total_tokens * 0.7:
                return True

        def extract_product_core(text: str) -> str:
            match = re.match(r"^(.*?)(?:\d+\s*(?:[a-z]+))", text, re.IGNORECASE)
            return match.group(1).strip() if match else text

        core1 = extract_product_core(normalized1)
        core2 = extract_product_core(normalized2)

        if SequenceMatcher(None, core1, core2).ratio() >= 0.9:
            quantity1 = normalized1[len(core1):].strip()
            quantity2 = normalized2[len(core2):].strip()
            if SequenceMatcher(None, quantity1, quantity2).ratio() >= 0.9:
                return True

        return False
