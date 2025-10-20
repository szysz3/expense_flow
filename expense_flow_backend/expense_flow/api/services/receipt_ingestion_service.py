"""Services for ingesting uploaded receipts into the temporary store."""

from __future__ import annotations

import logging
import os
import tempfile
from contextlib import contextmanager
from typing import Dict

from expense_flow.api.constants import ErrorMessages, FileTypes, LogMessages
from expense_flow.config import get_config
from expense_flow.document_processor.azure_processor import AzureDocumentProcessor
from expense_flow.document_processor.image_processor import ImagePreprocessor

logger = logging.getLogger("expense_flow")


class AzureConfigurationError(RuntimeError):
    """Raised when the Azure OCR stack is not configured."""


@contextmanager
def managed_temp_file(suffix: str):
    """Create a temporary file and ensure it is removed afterwards."""
    temp_file = tempfile.NamedTemporaryFile(suffix=suffix, delete=False)
    try:
        yield temp_file
    finally:
        try:
            temp_file.close()
        finally:
            if os.path.exists(temp_file.name):
                try:
                    os.remove(temp_file.name)
                except Exception as error:  # pragma: no cover - best effort cleanup
                    logger.warning(LogMessages.TEMP_FILE_REMOVAL_FAILED.format(error))


class ReceiptIngestionService:
    """Coordinates image preprocessing and OCR via Azure Document Intelligence."""

    def __init__(self) -> None:
        self.config = get_config()
        if not self.config.azure_endpoint or not self.config.azure_key:
            raise AzureConfigurationError(
                "Azure credentials not configured. "
                "Please set AZURE_ENDPOINT and AZURE_KEY in your environment."
            )

        self.image_preprocessor = ImagePreprocessor()
        self.document_processor = AzureDocumentProcessor(self.config)

    def ingest(self, *, file_bytes: bytes, content_type: str) -> Dict:
        """
        Prepare raw receipt data suitable for downstream LLM analysis.

        Args:
            file_bytes: Uploaded file contents.
            content_type: MIME type of the uploaded file.

        Returns:
            Structured receipt payload extracted from OCR.
        """
        if not FileTypes.is_valid(content_type):
            raise ValueError(ErrorMessages.INVALID_FILE_TYPE)

        suffix = FileTypes.EXTENSIONS[content_type]
        with managed_temp_file(suffix) as temp_file:
            temp_file.write(file_bytes)
            temp_file.flush()
            return self._process_file(temp_file.name)

    def _process_file(self, file_path: str) -> Dict:
        processed_path = None
        try:
            processed_path, success = self.image_preprocessor.process(file_path)
            path_to_process = processed_path if success else file_path
            if not os.path.exists(path_to_process):
                raise FileNotFoundError(f"Image file not found at {path_to_process}")

            raw_data = self.document_processor.process_image(path_to_process)
            return self.document_processor.preprocess_receipt(raw_data)
        finally:
            if processed_path and os.path.exists(processed_path):
                try:
                    os.remove(processed_path)
                except Exception as error:  # pragma: no cover - best effort cleanup
                    logger.warning(LogMessages.TEMP_FILE_REMOVAL_FAILED.format(error))
