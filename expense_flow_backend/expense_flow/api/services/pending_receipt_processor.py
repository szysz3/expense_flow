"""Background processing for pending temporary receipts."""

from __future__ import annotations

import logging
from typing import List, Optional

from expense_flow.analyzers.chatgpt_analyzer import ChatGPTAnalyzer
from expense_flow.analyzers.local_llm_analyzer import LocalLLMAnalyzer
from expense_flow.api.models import Receipt, ReceiptStatus, TempReceipt
from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.api.repository.temp_receipt_repository import TempReceiptRepository
from expense_flow.config import get_config
from expense_flow.db import session_scope

logger = logging.getLogger("expense_flow")


class PendingReceiptProcessor:
    """Coordinates moving temporary receipts through LLM analysis and storage."""

    def __init__(self, *, config=None) -> None:
        self.config = config or get_config()

    async def run(self) -> None:
        """Process all receipts currently pending in the temporary store."""
        try:
            receipts = await self._fetch_unprocessed()
        except Exception as exc:  # noqa: BLE001
            logger.error("Failed to fetch unprocessed receipts: %s", exc, exc_info=True)
            return

        for temp_receipt in receipts:
            if temp_receipt.status == ReceiptStatus.PROCESSING:
                continue

            status_updated = await self._update_status(
                temp_receipt.id, ReceiptStatus.PROCESSING
            )
            if not status_updated:
                logger.info(
                    "Skipping temporary receipt %s because status update failed "
                    "(likely processed elsewhere)",
                    temp_receipt.id,
                )
                continue

            try:
                receipt_payload = await self._analyze(temp_receipt)
                await self._store_receipt(Receipt(**receipt_payload))
                deleted = await self._delete_temp_receipt(temp_receipt.id)
                if not deleted:
                    logger.warning(
                        "Processed receipt %s but failed to delete temp copy",
                        temp_receipt.id,
                    )
                    await self._update_status(
                        temp_receipt.id, ReceiptStatus.COMPLETED
                    )
            except Exception as exc:  # noqa: BLE001
                logger.error(
                    "Error processing receipt %s: %s",
                    temp_receipt.id,
                    exc,
                    exc_info=True,
                )
                await self._update_status(
                    temp_receipt.id, ReceiptStatus.ERROR, str(exc)
                )

    async def _analyze(self, temp_receipt: TempReceipt) -> dict:
        try:
            logger.info(
                "Processing receipt %s with LocalLLMAnalyzer", temp_receipt.id
            )
            return await LocalLLMAnalyzer(self.config).analyze(
                temp_receipt.raw_data
            )
        except Exception as local_error:
            logger.warning(
                "LocalLLMAnalyzer failed for receipt %s: %s. Falling back to "
                "ChatGPTAnalyzer.",
                temp_receipt.id,
                local_error,
            )
            try:
                return await ChatGPTAnalyzer(self.config).analyze(
                    temp_receipt.raw_data
                )
            except Exception as fallback_error:
                raise Exception(
                    "Both LocalLLM and ChatGPT analyzers failed. "
                    f"Local error: {local_error}. "
                    f"Fallback error: {fallback_error}"
                ) from fallback_error

    async def _fetch_unprocessed(self) -> List[TempReceipt]:
        async with session_scope(self.config.temp_db_path) as session:
            repository = TempReceiptRepository(session)
            return await repository.get_unprocessed_receipts()

    async def _update_status(
        self, receipt_id: str, status: ReceiptStatus, error: Optional[str] = None
    ) -> bool:
        async with session_scope(self.config.temp_db_path) as session:
            repository = TempReceiptRepository(session)
            return await repository.update_status(receipt_id, status, error)

    async def _delete_temp_receipt(self, receipt_id: str) -> bool:
        async with session_scope(self.config.temp_db_path) as session:
            repository = TempReceiptRepository(session)
            return await repository.delete_receipt(receipt_id)

    async def _store_receipt(self, receipt: Receipt) -> None:
        async with session_scope(self.config.db_path) as session:
            repository = ReceiptRepository(session)
            await repository.insert_receipt(receipt)


async def process_pending_receipts() -> None:
    """Convenience wrapper for background-task usage."""
    await PendingReceiptProcessor().run()
