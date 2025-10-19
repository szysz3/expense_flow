"""SQLAlchemy ORM models for ExpenseFlow."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import (
    DateTime,
    Float,
    ForeignKey,
    Index,
    JSON,
    Numeric,
    String,
    Text,
    event,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    """Base declarative class."""

    type_annotation_map = {
        Decimal: Numeric(12, 2),
    }


class ReceiptORM(Base):
    """Receipt stored in SQLite."""

    __tablename__ = "receipts"
    __table_args__ = (
        Index("ix_receipts_transaction_datetime", "transaction_datetime"),
        Index("ix_receipts_merchant_name", "merchant_name"),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    merchant_name: Mapped[str] = mapped_column(String(255), default="", nullable=False)
    merchant_address: Mapped[str] = mapped_column(String(255), default="", nullable=False)
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    transaction_datetime: Mapped[datetime] = mapped_column(DateTime(timezone=False), nullable=False)
    added_datetime: Mapped[datetime] = mapped_column(DateTime(timezone=False), nullable=False)

    items: Mapped[list["ReceiptItemORM"]] = relationship(
        back_populates="receipt",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


class ReceiptItemORM(Base):
    """Receipt line item."""

    __tablename__ = "receipt_items"
    __table_args__ = (
        Index("ix_receipt_items_receipt_id", "receipt_id"),
        Index("ix_receipt_items_category", "category"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    receipt_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("receipts.id", ondelete="CASCADE"),
        nullable=False,
    )
    description: Mapped[str] = mapped_column(Text, nullable=False)
    quantity: Mapped[float] = mapped_column(Float, nullable=False)
    total_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    category: Mapped[str] = mapped_column(String(64), nullable=False)

    receipt: Mapped[ReceiptORM] = relationship(back_populates="items")


class TempReceiptORM(Base):
    """Temporary receipt awaiting asynchronous processing."""

    __tablename__ = "temp_receipts"
    __table_args__ = (
        Index("ix_temp_receipts_status_created_at", "status", "created_at"),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    raw_data: Mapped[dict] = mapped_column(JSON, nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=False), nullable=False)
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
