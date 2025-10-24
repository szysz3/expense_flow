from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import Iterable, List, Optional

from sqlalchemy import delete, select

from expense_flow.api.models import DevicePlatform
from expense_flow.db.models import NotificationDeviceORM

from .base_repository import BaseRepository, handle_db_errors


@dataclass
class NotificationDevice:
    """Registered device capable of receiving push notifications."""

    id: str
    token: str
    platform: DevicePlatform
    created_at: datetime
    updated_at: datetime


class NotificationDeviceRepository(BaseRepository):
    """Manage notification device registrations."""

    def _map_model(self, model: NotificationDeviceORM) -> NotificationDevice:
        return NotificationDevice(
            id=model.id,
            token=model.token,
            platform=DevicePlatform(model.platform),
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    @handle_db_errors
    async def upsert_device(
        self,
        *,
        token: str,
        platform: DevicePlatform,
    ) -> NotificationDevice:
        """Insert or update a device registration."""
        result = await self.session.execute(
            select(NotificationDeviceORM).where(NotificationDeviceORM.token == token)
        )
        model = result.scalar_one_or_none()
        now = datetime.utcnow()

        if model:
            model.platform = platform.value
            model.updated_at = now
        else:
            model = NotificationDeviceORM(
                id=str(uuid.uuid4()),
                token=token,
                platform=platform.value,
                created_at=now,
                updated_at=now,
            )
            self.session.add(model)

        await self.session.commit()
        await self.session.refresh(model)
        return self._map_model(model)

    @handle_db_errors
    async def delete_by_token(self, token: str) -> bool:
        """Remove a device registration by token."""
        result = await self.session.execute(
            delete(NotificationDeviceORM).where(NotificationDeviceORM.token == token)
        )
        await self.session.commit()
        return result.rowcount > 0

    @handle_db_errors
    async def remove_tokens(self, tokens: Iterable[str]) -> int:
        """Remove a collection of tokens, returning the count of deletions."""
        tokens = list(tokens)
        if not tokens:
            return 0

        result = await self.session.execute(
            delete(NotificationDeviceORM).where(NotificationDeviceORM.token.in_(tokens))
        )
        await self.session.commit()
        return result.rowcount or 0

    @handle_db_errors
    async def list_devices(self) -> List[NotificationDevice]:
        """Return all registered devices."""
        result = await self.session.execute(select(NotificationDeviceORM))
        return [self._map_model(model) for model in result.scalars().all()]

    @handle_db_errors
    async def list_tokens(
        self,
        platform: Optional[DevicePlatform] = None,
    ) -> List[str]:
        """Return registration tokens filtered by platform if provided."""
        stmt = select(NotificationDeviceORM.token)
        if platform:
            stmt = stmt.where(NotificationDeviceORM.platform == platform.value)

        result = await self.session.execute(stmt)
        return list(result.scalars().all())
