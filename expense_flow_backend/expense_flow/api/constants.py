from enum import Enum

class ErrorMessages:
    INVALID_FILE_TYPE = "Invalid file type"
    FILE_TYPE_DETAIL = "File must be JPEG, PNG or PDF"
    PROCESSING_FAILED = "Processing failed"
    DATABASE_ERROR = "Database error"
    INTERNAL_ERROR = "Internal server error"
    NOT_FOUND = "Not found"
    VALIDATION_ERROR = "Validation Error"
    INVALID_API_KEY = "Invalid or missing API Key"

class LogMessages:
    RECEIPT_PROCESSING_START = "Starting receipt processing with LLM type: {}"
    ANALYZER_USED = "Using analyzer: {}"
    PROCESSING_ATTEMPT = "Processing attempt {}"
    IMAGE_PREPROCESSING_FAILED = "Image preprocessing failed"
    IMAGE_PREPROCESSING_SUCCESS = "Image preprocessing successful"
    OCR_PROCESSING_SUCCESS = "OCR processing successful"
    ATTEMPT_FAILED = "Attempt {} failed: {}"
    WAITING_FOR_RETRY = "Waiting {} seconds before retry"
    NON_RETRYABLE_ERROR = "Non-retryable error encountered: {}"
    TEMP_FILE_REMOVAL_FAILED = "Warning: Failed to remove temporary file: {}"
    DB_STARTUP = "Ensuring database exists at: {}"
    DB_SHUTDOWN = "Closing database connection"
    REQUEST_RECEIVED = "Received request with LLM type: {}"

class FileTypes:
    JPEG = "image/jpeg"
    PNG = "image/png"
    PDF = "application/pdf"
    
    EXTENSIONS = {
        JPEG: ".jpg",
        PNG: ".png",
        PDF: ".pdf"
    }
    
    @classmethod
    def is_valid(cls, content_type: str) -> bool:
        return content_type in cls.EXTENSIONS

class APIHeaders:
    API_KEY = "X-API-Key"