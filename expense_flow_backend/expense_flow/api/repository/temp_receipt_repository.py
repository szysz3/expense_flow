from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from sqlalchemy import delete, select, update

from expense_flow.api.models import ReceiptStatus, TempReceipt
from expense_flow.db.models import TempReceiptORM

from .base_repository import BaseRepository, handle_db_errors


class TempReceiptRepository(BaseRepository):
    """Repository for managing temporary receipts during background processing."""

    def _map_temp_receipt(self, model: TempReceiptORM) -> TempReceipt:
        return TempReceipt(
            id=model.id,
            raw_data=model.raw_data,
            status=ReceiptStatus(model.status),
            created_at=model.created_at,
            error_message=model.error_message,
        )

    @handle_db_errors
    async def insert_temp_receipt(self, receipt_data: Dict[str, Any]) -> str:
        receipt_id = str(uuid.uuid4())
        model = TempReceiptORM(
            id=receipt_id,
            raw_data=receipt_data,
            status=ReceiptStatus.PENDING.value,
            created_at=datetime.utcnow(),
        )
        self.session.add(model)
        await self.session.commit()
        return receipt_id

    async def _fetch_by_status(self, statuses: List[ReceiptStatus]) -> List[TempReceipt]:
        stmt = (
            select(TempReceiptORM)
            .where(TempReceiptORM.status.in_([status.value for status in statuses]))
            .order_by(TempReceiptORM.created_at.asc())
        )
        result = await self.session.execute(stmt)
        return [self._map_temp_receipt(model) for model in result.scalars().all()]

    @handle_db_errors
    async def get_unprocessed_receipts(self) -> List[TempReceipt]:
        statuses = [ReceiptStatus.PENDING, ReceiptStatus.PROCESSING, ReceiptStatus.ERROR]
        return await self._fetch_by_status(statuses)

    @handle_db_errors
    async def get_pending_receipts(self) -> List[TempReceipt]:
        return await self._fetch_by_status([ReceiptStatus.PENDING])

    @handle_db_errors
    async def get_temp_receipt(self, receipt_id: str) -> Optional[TempReceipt]:
        stmt = select(TempReceiptORM).where(TempReceiptORM.id == receipt_id)
        result = await self.session.execute(stmt)
        model = result.scalar_one_or_none()
        if not model:
            return None
        return self._map_temp_receipt(model)

    @handle_db_errors
    async def update_status(
        self,
        receipt_id: str,
        status: ReceiptStatus,
        error_message: Optional[str] = None,
    ) -> bool:
        stmt = (
            update(TempReceiptORM)
            .where(TempReceiptORM.id == receipt_id)
            .values(status=status.value, error_message=error_message)
        )
        result = await self.session.execute(stmt)
        await self.session.commit()
        return result.rowcount > 0

    @handle_db_errors
    async def delete_receipt(self, receipt_id: str) -> bool:
        stmt = delete(TempReceiptORM).where(TempReceiptORM.id == receipt_id)
        result = await self.session.execute(stmt)
        await self.session.commit()
        return result.rowcount > 0

    @handle_db_errors
    async def update_receipt(self, temp_receipt: TempReceipt) -> bool:
        stmt = (
            update(TempReceiptORM)
            .where(TempReceiptORM.id == temp_receipt.id)
            .values(
                raw_data=temp_receipt.raw_data,
                status=temp_receipt.status.value,
                created_at=temp_receipt.created_at,
                error_message=temp_receipt.error_message,
            )
        )
        result = await self.session.execute(stmt)
        await self.session.commit()
        return result.rowcount > 0
