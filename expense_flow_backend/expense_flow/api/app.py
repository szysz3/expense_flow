from decimal import Decimal
from fastapi import FastAPI, File, Form, Request, UploadFile, Depends, HTTPException, BackgroundTasks
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.status import HTTP_400_BAD_REQUEST, HTTP_500_INTERNAL_SERVER_ERROR, HTTP_422_UNPROCESSABLE_ENTITY
import tempfile
import os
from typing import Optional, Union
from datetime import datetime
import asyncio
import logging
from contextlib import contextmanager

from .models import (
    CategoryResponse, CreateReceiptRequest, CreateReceiptResponse, LLMType, Merchant, MerchantResponse, MonthSummaryResponse, ProcessReceiptRequest, ProcessReceiptResponse, ErrorDetail,
    Receipt, ReceiptItem, ReceiptItemResponse, ReceiptQuery, ReceiptResponse, SearchResult
)
from .security import verify_api_key
from .db import ReceiptRepository, DatabaseError
from .api_config import APIConfig, get_api_config
from .constants import ErrorMessages, LogMessages, FileTypes
from .logging_config import setup_logging
from expense_flow.document_processor.azure_processor import AzureDocumentProcessor
from expense_flow.document_processor.image_processor import ImagePreprocessor
from expense_flow.analyzers.local_llm import LocalLLMAnalyzer
from expense_flow.analyzers.chatgpt_llm import ChatGPTAnalyzer
from expense_flow.config import Config

# Setup logging
setup_logging()
logger = logging.getLogger("expense_flow")

class ProcessingError(Exception):
    def __init__(self, message: str, retry_count: Optional[int] = None):
        self.message = message
        self.retry_count = retry_count
        super().__init__(message)

def get_repository(api_config: APIConfig = Depends(get_api_config)):
    return ReceiptRepository(db_path=api_config.db_path)

def get_analyzer(config: Config, llm_type: LLMType) -> Union[LocalLLMAnalyzer, ChatGPTAnalyzer]:
    """Create the appropriate analyzer based on LLM type"""
    analyzers = {
        LLMType.LOCAL: LocalLLMAnalyzer,
        LLMType.CHATGPT: ChatGPTAnalyzer
    }
    analyzer_class = analyzers.get(llm_type)
    if not analyzer_class:
        raise ValueError(f"Invalid LLM type: {llm_type}")
    return analyzer_class(config)

@contextmanager
def temp_file_handler(suffix: str):
    """Context manager for handling temporary files"""
    temp_file = tempfile.NamedTemporaryFile(suffix=suffix, delete=False)
    try:
        yield temp_file
    finally:
        if os.path.exists(temp_file.name):
            try:
                os.remove(temp_file.name)
            except Exception as e:
                logger.warning(LogMessages.TEMP_FILE_REMOVAL_FAILED.format(e))

app = FastAPI(
    title="Receipt Analysis API",
    description="API for analyzing and categorizing receipts",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Configure this for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

async def process_receipt_with_retries(
    file_path: str,
    config: Config,
    llm_type: LLMType,
    api_config: APIConfig
) -> Receipt:
    logger.info(LogMessages.RECEIPT_PROCESSING_START.format(llm_type.value))
    
    image_preprocessor = ImagePreprocessor()
    doc_processor = AzureDocumentProcessor(config)
    analyzer = get_analyzer(config, llm_type)
    
    logger.info(LogMessages.ANALYZER_USED.format(analyzer.__class__.__name__))
    
    retry_count = 0
    last_error = None
    processed_path = None
    
    while retry_count < api_config.max_retries:
        try:
            logger.info(LogMessages.PROCESSING_ATTEMPT.format(retry_count + 1))
            
            # Process image
            processed_path, success = image_preprocessor.process(file_path)
            if not success:
                raise ProcessingError(LogMessages.IMAGE_PREPROCESSING_FAILED)
            
            logger.info(LogMessages.IMAGE_PREPROCESSING_SUCCESS)
            
            # Run OCR
            raw_data = doc_processor.process_image(processed_path if success else file_path)
            receipt_data = doc_processor.preprocess_receipt(raw_data)
            
            logger.info(LogMessages.OCR_PROCESSING_SUCCESS)
            
            # Analyze with LLM
            analysis_result = analyzer.analyze(receipt_data)
            return Receipt(**analysis_result)
            
        except Exception as e:
            retry_count += 1
            last_error = str(e)
            logger.error(LogMessages.ATTEMPT_FAILED.format(retry_count, last_error))
            
            if isinstance(e, (ProcessingError, TimeoutError)):
                if retry_count < api_config.max_retries:
                    logger.info(LogMessages.WAITING_FOR_RETRY.format(api_config.retry_delay))
                    await asyncio.sleep(api_config.retry_delay)
            else:
                logger.error(LogMessages.NON_RETRYABLE_ERROR.format(type(e).__name__))
                raise
                
        finally:
            if processed_path and os.path.exists(processed_path):
                try:
                    os.remove(processed_path)
                except Exception as e:
                    logger.warning(LogMessages.TEMP_FILE_REMOVAL_FAILED.format(e))
    
    raise ProcessingError(f"Processing failed after {retry_count} attempts: {last_error}", retry_count)

async def get_request_form(
    llm_type: str = Form(default='local')
) -> ProcessReceiptRequest:
    """Parse form data into ProcessReceiptRequest"""
    return ProcessReceiptRequest(llm_type=llm_type)

@app.post(
    "/api/receipts/analyze",
    response_model=ProcessReceiptResponse,
    responses={
        400: {"model": ErrorDetail},
        500: {"model": ErrorDetail}
    }
)
async def analyze_receipt(
    request: ProcessReceiptRequest = Depends(get_request_form),
    file: UploadFile = File(...),
    api_key: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_repository),
    api_config: APIConfig = Depends(get_api_config)
):
    """Analyze receipt image and store results in database"""
    logger.info(LogMessages.REQUEST_RECEIVED.format(request.llm_type))
    
    if not FileTypes.is_valid(file.content_type):
        raise HTTPException(
            status_code=HTTP_400_BAD_REQUEST,
            detail={
                "error": ErrorMessages.INVALID_FILE_TYPE,
                "detail": ErrorMessages.FILE_TYPE_DETAIL
            }
        )
    
    ext = FileTypes.EXTENSIONS.get(file.content_type)
    with temp_file_handler(ext) as temp_file:
        content = await file.read()
        temp_file.write(content)
        temp_file.close()
        
        try:
            config = Config(
                endpoint=os.getenv("AZURE_DOCUMENT_ENDPOINT"),
                key=os.getenv("AZURE_DOCUMENT_KEY"),
                chatgpt_key=os.getenv("CHATGPT_KEY"),
                llm_type=request.llm_type.value
            )
            
            receipt = await process_receipt_with_retries(
                temp_file.name,
                config,
                request.llm_type,
                api_config
            )
            receipt_id = repository.insert_receipt(receipt)
            
            return ProcessReceiptResponse(
                receipt_id=receipt_id,
                receipt=receipt
            )
            
        except ProcessingError as e:
            raise HTTPException(
                status_code=HTTP_500_INTERNAL_SERVER_ERROR,
                detail={
                    "error": ErrorMessages.PROCESSING_FAILED,
                    "detail": e.message,
                    "retry_count": e.retry_count
                }
            )
        except DatabaseError as e:
            raise HTTPException(
                status_code=HTTP_500_INTERNAL_SERVER_ERROR,
                detail={
                    "error": ErrorMessages.DATABASE_ERROR,
                    "detail": str(e)
                }
            )
        except Exception as e:
            logger.exception("Unexpected error during receipt processing")
            raise HTTPException(
                status_code=HTTP_500_INTERNAL_SERVER_ERROR,
                detail={
                    "error": ErrorMessages.INTERNAL_ERROR,
                    "detail": str(e)
                }
            )

@app.get(
    "/api/receipts/{receipt_id}",
    response_model=Receipt,
    responses={
        404: {"model": ErrorDetail},
        500: {"model": ErrorDetail}
    }
)
async def get_receipt(
    receipt_id: str,
    api_key: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_repository)
):
    """Retrieve a specific receipt by ID"""
    try:            
        receipt = repository.get_receipt(receipt_id)
        if not receipt:
            raise HTTPException(
                status_code=404,
                detail={
                    "error": ErrorMessages.NOT_FOUND,
                    "detail": f"Receipt {receipt_id} not found"
                }
            )
            
        return receipt
        
    except DatabaseError as e:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": ErrorMessages.DATABASE_ERROR,
                "detail": str(e)
            }
        )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for error in exc.errors():
        if error["type"] == "value_error":
            errors.append({
                "loc": error.get("loc", []),
                "msg": error["msg"],
                "type": "value_error"
            })
        elif error["type"] == "type_error":
            field = error["loc"][-1] if error["loc"] else ""
            errors.append({
                "loc": error["loc"],
                "msg": f"Invalid type for field '{field}'. {error['msg']}",
                "type": "type_error"
            })
        else:
            errors.append({
                "loc": error["loc"],
                "msg": error["msg"],
                "type": error["type"]
            })

    return JSONResponse(
        status_code=HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": errors,
            "error": ErrorMessages.VALIDATION_ERROR,
            "body": exc.body 
        }
    )

@app.post(
    "/api/receipts/search",
    response_model=SearchResult,
    responses={
        422: {"model": ErrorDetail},
        500: {"model": ErrorDetail}
    }
)
async def search_receipts(
    query: ReceiptQuery,
    api_key: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_repository)
):
    """Search receipts with various filters"""
    try:
        receipts = repository.search_receipts(
            merchant_name=query.merchant_name,
            start_date=query.start_date,
            end_date=query.end_date,
            categories=query.categories,
            item_description=query.item_description
        )
        return receipts
        
    except DatabaseError as e:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": ErrorMessages.DATABASE_ERROR,
                "detail": str(e)
            }
        )
    
@app.get(
    "/api/categories",
    response_model=CategoryResponse,
    responses={
        500: {"model": ErrorDetail}
    }
)
async def get_categories(
    api_key: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_repository)
):
    """Get all categories with their actual items and spending from receipts"""
    try:
        return repository.get_categories_with_items()
        
    except DatabaseError as e:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": ErrorMessages.DATABASE_ERROR,
                "detail": str(e)
            }
        )

@app.get(
    "/api/months/summary",
    response_model=MonthSummaryResponse,
    responses={
        500: {"model": ErrorDetail}
    }
)
async def get_months_summary(
    api_key: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_repository)
):
    """Get spending summaries by month using actual receipt data"""
    try:
        return repository.get_monthly_summaries()
        
    except DatabaseError as e:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": ErrorMessages.DATABASE_ERROR,
                "detail": str(e)
            }
        )

@app.post(
    "/api/receipts/create",
    response_model=CreateReceiptResponse,
    response_model_exclude_none=True,
)
async def create_receipt(
    request: CreateReceiptRequest,
    api_key: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_repository)
):
    """Create a receipt manually"""
    try:
        # Create Receipt for database
        receipt = Receipt(
            merchant=request.merchant or Merchant(),
            items=[
                ReceiptItem(
                    description=request.description,
                    quantity=request.quantity,
                    total_price=request.total_price,
                    category=request.category
                )
            ],
            total=request.total_price,
            transaction_datetime=request.transaction_datetime or datetime.utcnow(),
            added_datetime=datetime.utcnow()
        )
        
        receipt_id = repository.insert_receipt(receipt)
        
        # Create response using response models
        receipt_response = ReceiptResponse(
            id=receipt_id,
            merchant=MerchantResponse(
                name=receipt.merchant.name,
                address=receipt.merchant.address
            ),
            items=[
                ReceiptItemResponse(
                    description=item.description,
                    quantity=float(item.quantity),
                    total_price=float(item.total_price),
                    category=item.category.value
                )
                for item in receipt.items
            ],
            total=float(receipt.total),
            transaction_datetime=receipt.transaction_datetime,
            added_datetime=receipt.added_datetime
        )
        
        return CreateReceiptResponse(
            receipt_id=receipt_id,
            receipt=receipt_response
        )
        
    except Exception as e:
        logger.exception("Error in create_receipt")
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    
@app.on_event("startup")
async def startup_event():
    """Ensure database exists on startup"""
    api_config = get_api_config()
    logger.info(LogMessages.DB_STARTUP.format(api_config.db_path))
    os.makedirs(os.path.dirname(api_config.db_path) or '.', exist_ok=True)

@app.on_event("shutdown")
async def shutdown_event():
    """Clean up database connection on shutdown"""
    logger.info(LogMessages.DB_SHUTDOWN)
    repository = get_repository()
    repository.close()