"""Background processing for pending temporary receipts."""

from __future__ import annotations

import asyncio
import logging
from typing import List, Optional

from ollama import Client

from expense_flow.analyzers.chatgpt_analyzer import ChatGPTAnalyzer
from expense_flow.analyzers.local_llm_analyzer import LocalLLMAnalyzer
from expense_flow.api.models import Receipt, ReceiptStatus, TempReceipt
from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.api.repository.temp_receipt_repository import TempReceiptRepository
from expense_flow.config import get_config
from expense_flow.db import session_scope

logger = logging.getLogger("expense_flow")


_processing_task: asyncio.Task | None = None
_reschedule_requested: bool = False


class OllamaUnavailableError(Exception):
    """Raised when the Ollama host cannot be reached."""

    def __init__(self, message: str) -> None:
        super().__init__(message)


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

        if receipts:
            ollama_available = await self._is_ollama_available()
            if not ollama_available:
                logger.info(
                    "Ollama host unavailable; keeping %s temporary receipts pending.",
                    len(receipts),
                )
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
            except OllamaUnavailableError as exc:
                logger.info(
                    "Deferring receipt %s because Ollama host is unavailable: %s",
                    temp_receipt.id,
                    exc,
                )
                await self._update_status(temp_receipt.id, ReceiptStatus.PENDING)
                return
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
            if not await self._is_ollama_available(log_if_unavailable=False):
                raise OllamaUnavailableError("Ollama host unavailable") from local_error
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

    async def _is_ollama_available(self, *, log_if_unavailable: bool = True) -> bool:
        """Check whether the configured Ollama host is reachable."""
        host = getattr(self.config, "ollama_host", None)
        if not host:
            if log_if_unavailable:
                logger.warning(
                    "LLM_OLLAMA_HOST is not configured; skipping local LLM analysis."
                )
            return False

        def _probe_host() -> tuple[bool, Optional[str]]:
            try:
                Client(host=host).list()
                return True, None
            except Exception as exc:  # noqa: BLE001
                return False, str(exc)

        available, error = await asyncio.to_thread(_probe_host)
        if not available and log_if_unavailable:
            logger.warning(
                "Unable to connect to Ollama host %s: %s. Local analysis deferred.",
                host,
                error,
            )
        return available

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


def schedule_pending_receipt_processing() -> None:
    """
    Schedule background processing of pending receipts.

    If a run is in-flight, record that another pass is required so newly added
    receipts are processed immediately after the current cycle completes.
    """
    global _processing_task, _reschedule_requested

    if _processing_task and not _processing_task.done():
        _reschedule_requested = True
        logger.debug("Pending receipt processor running; marked for follow-up run.")
        return

    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:  # pragma: no cover - fallback for sync contexts
        loop = asyncio.get_event_loop()

    _reschedule_requested = False

    async def _runner() -> None:
        try:
            await process_pending_receipts()
        except Exception:  # noqa: BLE001 - surfaced via callback
            logger.exception("Pending receipt processor task failed.")
            raise

    _processing_task = loop.create_task(_runner())

    def _cleanup(task: asyncio.Task) -> None:
        global _processing_task, _reschedule_requested
        try:
            task.result()
        except Exception:  # noqa: BLE001 - already logged in _runner
            pass
        finally:
            _processing_task = None
            if _reschedule_requested:
                logger.debug("Scheduling follow-up pending receipt processing run.")
                _reschedule_requested = False
                schedule_pending_receipt_processing()

    _processing_task.add_done_callback(_cleanup)
