from __future__ import annotations

import asyncio
import json
import logging
import threading
from dataclasses import dataclass
from typing import List, Optional

try:
    import firebase_admin
    from firebase_admin import credentials, initialize_app, messaging
    from firebase_admin.exceptions import FirebaseError
except ImportError as exc:  # pragma: no cover - gracefully handle optional dependency
    firebase_admin = None  # type: ignore[assignment]
    credentials = initialize_app = messaging = None  # type: ignore[assignment]
    FirebaseError = Exception  # type: ignore[assignment]
    _IMPORT_ERROR = exc
else:
    _IMPORT_ERROR = None

from expense_flow.api.models import DevicePlatform
from expense_flow.api.repository.notification_device_repository import (
    NotificationDeviceRepository,
)
from expense_flow.config import Config

logger = logging.getLogger("expense_flow")


class FirebaseConfigurationError(RuntimeError):
    """Raised when Firebase Cloud Messaging cannot be initialised."""


class FirebaseNotAvailableError(RuntimeError):
    """Raised when Firebase Cloud Messaging SDK is unavailable at runtime."""


@dataclass(frozen=True)
class NotificationDispatchResult:
    """Summary of a dispatch attempt."""

    total: int
    successes: int
    failures: int
    invalid_tokens: List[str]


class FCMClient:
    """Lazy Firebase app initialisation and messaging helpers."""

    def __init__(self, config: Config):
        self._config = config
        self._app = None
        self._lock = threading.Lock()

    @property
    def is_configured(self) -> bool:
        return bool(
            self._config.firebase_credentials_path
            or self._config.firebase_credentials_json
        )
    
    @property
    def is_available(self) -> bool:
        return firebase_admin is not None

    def _ensure_app(self):
        if self._app is not None:
            return self._app

        with self._lock:
            if self._app is not None:
                return self._app

            if firebase_admin is None:
                raise FirebaseNotAvailableError(
                    "firebase-admin package is not installed."
                ) from _IMPORT_ERROR

            if not self.is_configured:
                raise FirebaseConfigurationError(
                    "Firebase credentials not provided. "
                    "Set FIREBASE_CREDENTIALS_PATH or FIREBASE_CREDENTIALS_JSON."
                )

            creds = self._load_credentials()
            app_name = self._config.firebase_app_name or "expense_flow_fcm"

            logger.debug("Initialising Firebase app '%s'.", app_name)
            try:
                self._app = initialize_app(creds, name=app_name)
            except ValueError as exc:
                try:
                    self._app = firebase_admin.get_app(app_name)
                except ValueError as get_exc:  # pragma: no cover - defensive
                    raise FirebaseConfigurationError(
                        f"Failed to initialise Firebase app '{app_name}'."
                    ) from get_exc
                else:
                    logger.debug(
                        "Firebase app '%s' already initialised; reusing instance.",
                        app_name,
                    )
            return self._app

    def _load_credentials(self):
        if self._config.firebase_credentials_path:
            return credentials.Certificate(self._config.firebase_credentials_path)
        if self._config.firebase_credentials_json:
            try:
                payload = json.loads(self._config.firebase_credentials_json)
            except json.JSONDecodeError as exc:  # pragma: no cover - defensive
                raise FirebaseConfigurationError(
                    "Invalid FIREBASE_CREDENTIALS_JSON payload."
                ) from exc
            return credentials.Certificate(payload)
        raise FirebaseConfigurationError(
            "Firebase credentials not provided. "
            "Set FIREBASE_CREDENTIALS_PATH or FIREBASE_CREDENTIALS_JSON."
        )

    async def send_multicast(
        self,
        *,
        tokens: List[str],
        title: str,
        body: str,
        data: Optional[dict] = None,
    ) -> NotificationDispatchResult:
        """Send a notification to multiple devices."""
        if not tokens:
            return NotificationDispatchResult(total=0, successes=0, failures=0, invalid_tokens=[])

        app = self._ensure_app()
        message = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
        )

        batch_response = await asyncio.to_thread(
            messaging.send_multicast,
            message,
            app=app,
        )

        invalid_tokens: List[str] = []
        for token, response in zip(tokens, batch_response.responses):
            if not response.success and response.exception:
                if isinstance(response.exception, FirebaseError):
                    code = response.exception.code or ""
                else:  # pragma: no cover - SDK specific handling
                    code = getattr(response.exception, "code", "") or ""

                if code in {"registration-token-not-registered", "invalid-argument"}:
                    invalid_tokens.append(token)

        return NotificationDispatchResult(
            total=batch_response.success_count + batch_response.failure_count,
            successes=batch_response.success_count,
            failures=batch_response.failure_count,
            invalid_tokens=invalid_tokens,
        )


class NotificationService:
    """High-level notification orchestration."""

    def __init__(
        self,
        *,
        config: Config,
        repository: NotificationDeviceRepository,
    ) -> None:
        self._config = config
        self._repository = repository
        self._client = FCMClient(config)

    @property
    def enabled(self) -> bool:
        return (
            self._client.is_configured
            and self._client.is_available
        )

    async def register_device(
        self,
        *,
        token: str,
        platform: DevicePlatform,
    ) -> None:
        """Persist the device registration."""
        await self._repository.upsert_device(token=token, platform=platform)

    async def unregister_device(self, *, token: str) -> bool:
        """Remove a device registration."""
        return await self._repository.delete_by_token(token)

    async def send_receipt_processed_notification(
        self,
        *,
        receipt_id: str,
        merchant_name: Optional[str],
        total: Optional[str],
    ) -> Optional[NotificationDispatchResult]:
        """
        Notify all registered devices that receipt processing finished.

        Returns the dispatch result when notifications were attempted, otherwise None.
        """
        tokens = await self._repository.list_tokens()
        if not tokens:
            logger.debug("Skipping FCM dispatch: no registered devices.")
            return None

        if not self.enabled:
            logger.info(
                "Skipping FCM dispatch for receipt %s: Firebase not configured.",
                receipt_id,
            )
            return None

        title = "Receipt processed"
        merchant = merchant_name or "your receipt"
        total_fragment = f" totaling {total}" if total else ""
        body = f"We finished processing {merchant}{total_fragment}."

        try:
            result = await self._client.send_multicast(
                tokens=tokens,
                title=title,
                body=body,
                data={
                    "receipt_id": receipt_id,
                    "merchant_name": merchant_name or "",
                    "total": total or "",
                },
            )
        except (FirebaseConfigurationError, FirebaseNotAvailableError) as exc:
            logger.error("Failed to send FCM notification: %s", exc)
            return None

        if result.invalid_tokens:
            logger.info(
                "Removing %s invalid FCM tokens after dispatch.",
                len(result.invalid_tokens),
            )
            await self._repository.remove_tokens(result.invalid_tokens)

        if result.failures:
            logger.warning(
                "FCM dispatch completed with %s failures (successes: %s).",
                result.failures,
                result.successes,
            )
        else:
            logger.debug(
                "FCM dispatch succeeded for receipt %s (devices: %s).",
                receipt_id,
                result.successes,
            )

        return result
