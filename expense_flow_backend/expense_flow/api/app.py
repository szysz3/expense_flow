from decimal import Decimal
from fastapi import FastAPI, File, Form, Request, UploadFile, Depends, HTTPException, BackgroundTasks
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.params import Query
from fastapi.responses import JSONResponse
from starlette.status import HTTP_400_BAD_REQUEST, HTTP_500_INTERNAL_SERVER_ERROR, HTTP_422_UNPROCESSABLE_ENTITY
import tempfile
import os
from typing import List, Optional
from datetime import datetime
import logging
from contextlib import contextmanager

from expense_flow.config import get_config
from expense_flow.api.repository.base_repository import DatabaseError
from expense_flow.api.repository.receipt_repository import ReceiptRepository
from expense_flow.api.repository.temp_receipt_repository import TempReceiptRepository
from expense_flow.utils.retry import retry_async

from .models import (
    CategoryResponse, CreateReceiptRequest, CreateReceiptResponse, DailyExpense, LLMType, Merchant, MerchantResponse, MonthSummaryResponse, ProcessReceiptRequest, ProcessReceiptResponse, ErrorDetail,
    Receipt, ReceiptItem, ReceiptItemResponse, ReceiptQuery, ReceiptResponse, ReceiptStatus, SearchResult, TempReceipt, UnprocessedReceiptsResponse
)
from .security import verify_api_key
from .constants import ErrorMessages, LogMessages, FileTypes
from .logging_config import setup_logging
from expense_flow.document_processor.azure_processor import AzureDocumentProcessor
from expense_flow.document_processor.image_processor import ImagePreprocessor
from expense_flow.analyzers.local_llm_analyzer import LocalLLMAnalyzer
from expense_flow.analyzers.chatgpt_analyzer import ChatGPTAnalyzer

setup_logging()
logger = logging.getLogger("expense_flow")

class ProcessingError(Exception):
    def __init__(self, message: str, retry_count: Optional[int] = None):
        self.message = message
        self.retry_count = retry_count
        super().__init__(message)

def get_repository():
    """
    Get receipt repository instance
    
    Returns:
        ReceiptRepository instance
    """
    config = get_config()
    return ReceiptRepository(db_path=config.db_path)

def get_temp_repository() -> TempReceiptRepository:
    """
    Get temporary receipt repository instance
    
    Returns:
        TempReceiptRepository instance
    """
    config = get_config()
    return TempReceiptRepository(config=config)

def get_analyzer(llm_type: LLMType):
    """
    Create the appropriate analyzer based on LLM type
    
    Args:
        llm_type: Type of LLM to use
        
    Returns:
        Analyzer instance
        
    Raises:
        ValueError: If LLM type is invalid
    """
    config = get_config()
    
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
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

async def process_receipt_with_retries(
    file_path: str,
    llm_type: LLMType
) -> Receipt:
    """Process a receipt image with retries"""
    async def _process():
        config = get_config()
        image_preprocessor = ImagePreprocessor()
        doc_processor = AzureDocumentProcessor(config)
        analyzer = get_analyzer(llm_type)
        
        logger.info(LogMessages.ANALYZER_USED.format(analyzer.__class__.__name__))
        processed_path = None
        
        try:
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
            analysis_result = await analyzer.analyze(receipt_data)
            return Receipt(**analysis_result)
            
        finally:
            if processed_path and os.path.exists(processed_path):
                try:
                    os.remove(processed_path)
                except Exception as e:
                    logger.warning(LogMessages.TEMP_FILE_REMOVAL_FAILED.format(e))
    
    logger.info(LogMessages.RECEIPT_PROCESSING_START.format(llm_type.value))
    config = get_config()
    
    return await retry_async(
        _process,
        max_retries=config.max_retries,
        retry_delay=config.retry_delay,
        logger=logger
    )

async def get_request_form(
    llm_type: str = Form(default='local')
) -> ProcessReceiptRequest:
    """Parse form data into ProcessReceiptRequest"""
    return ProcessReceiptRequest(llm_type=llm_type)

@app.post("/api/receipts/analyze", response_model=TempReceipt)
async def analyze_receipt(
    file: UploadFile = File(...),
    api_key: str = Depends(verify_api_key),
    temp_repository: TempReceiptRepository = Depends(get_temp_repository)
):
    """Process receipt with Azure OCR and store in temp database"""
    config = get_config()
    
    if not config.azure_endpoint or not config.azure_key:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": "Azure credentials not configured. Please set AZURE_ENDPOINT and AZURE_KEY in your .env file."}
        )

    if not FileTypes.is_valid(file.content_type):
        raise HTTPException(
            status_code=HTTP_400_BAD_REQUEST,
            detail={"error": ErrorMessages.INVALID_FILE_TYPE}
        )

    try:
        # Read file content first
        content = await file.read()
        
        # Create temp file with proper suffix
        with tempfile.NamedTemporaryFile(suffix=FileTypes.EXTENSIONS[file.content_type], delete=False) as temp_file:
            temp_file.write(content)
            temp_file_path = temp_file.name

        try:
            # Process image after file is written but before cleanup
            image_preprocessor = ImagePreprocessor()
            doc_processor = AzureDocumentProcessor(config)
            
            processed_path, success = image_preprocessor.process(temp_file_path)
            path_to_process = processed_path if success else temp_file_path
            
            # Make sure the file exists
            if not os.path.exists(path_to_process):
                raise ValueError(f"Image file not found at {path_to_process}")
                
            raw_data = doc_processor.process_image(path_to_process)
            receipt_data = doc_processor.preprocess_receipt(raw_data)
            
            # Store in temp database
            temp_receipt_id = temp_repository.insert_temp_receipt(receipt_data)
            
            return TempReceipt(
                id=temp_receipt_id,
                raw_data=receipt_data,
                status=ReceiptStatus.PENDING
            )
            
        finally:
            # Clean up temporary files
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
            if success and processed_path and os.path.exists(processed_path):
                os.unlink(processed_path)
            
    except Exception as e:
        logger.error(f"Error processing receipt: {str(e)}")
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": str(e)}
        )

# Add endpoint for Ollama PC registration
@app.post("/api/analyzer/register")
async def register_analyzer(
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key),
    temp_repository: TempReceiptRepository = Depends(get_temp_repository),
    receipt_repository: ReceiptRepository = Depends(get_repository)
):
    """
    Endpoint for Ollama PC to register its availability.
    Triggers processing of pending receipts.
    """
    # Start processing pending receipts in background
    background_tasks.add_task(
        process_pending_receipts,
        temp_repository,
        receipt_repository
    )
    return {"status": "registered"}

# Add endpoint to get unprocessed receipts
@app.get("/api/receipts/unprocessed", response_model=UnprocessedReceiptsResponse)
async def get_unprocessed_receipts(
    api_key: str = Depends(verify_api_key),
    temp_repository: TempReceiptRepository = Depends(get_temp_repository)
):
    """Get all receipts that haven't been fully processed yet"""
    unprocessed = temp_repository.get_unprocessed_receipts()
    return UnprocessedReceiptsResponse(
        receipts=unprocessed,
        total_count=len(unprocessed)
    )

# Add background processing function
async def process_pending_receipts(
    temp_repository: TempReceiptRepository,
    receipt_repository: ReceiptRepository
):
    """Process pending and failed receipts when Ollama is available"""
    config = get_config()
    unprocessed_receipts = temp_repository.get_unprocessed_receipts()    

    for temp_receipt in unprocessed_receipts:
        try:
            if temp_receipt.status == ReceiptStatus.PROCESSING:
                    continue

            # Update status to processing
            temp_repository.update_status(
                temp_receipt.id, 
                ReceiptStatus.PROCESSING
            )
            
            # Process with Ollama
            analyzer = LocalLLMAnalyzer(config)
            result = await analyzer.analyze(temp_receipt.raw_data)
            
            # Store final receipt
            receipt = Receipt(**result)
            receipt_id = receipt_repository.insert_receipt(receipt)
            
            # Remove from temp storage
            temp_repository.delete_receipt(temp_receipt.id)
            
        except Exception as e:
            logger.error(f"Error processing receipt {temp_receipt.id}: {str(e)}")
            temp_repository.update_status(
                temp_receipt.id,
                ReceiptStatus.ERROR,
                str(e)
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
    
@app.get(
    "/api/months/{year}/{month}/daily-expenses",
    response_model=List[DailyExpense],
    responses={
        500: {"model": ErrorDetail}
    }
)
async def get_daily_expenses(
    year: int,
    month: int,
    api_key: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_repository)
):
    """Get daily expenses for a specific month"""
    try:
        results = repository.get_daily_expenses(year, month)
        return results
    except DatabaseError as e:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": ErrorMessages.DATABASE_ERROR,
                "detail": str(e)
            }
        )

@app.get(
    "/api/receipts",
    response_model=dict,
    responses={
        500: {"model": ErrorDetail}
    }
)
async def get_receipts(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=100, description="Items per page"),
    api_key: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_repository)
):
    """Get paginated receipts"""
    try:
        receipts = repository.get_receipts(page, page_size)
        total_count = repository.get_receipt_count()
        
        return {
            "receipts": receipts,
            "total_count": total_count,
            "page": page,
            "page_size": page_size
        }
        
    except DatabaseError as e:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": ErrorMessages.DATABASE_ERROR,
                "detail": str(e)
            }
        )

@app.on_event("startup")
async def startup_event():
    """Ensure databases exist on startup"""
    config = get_config()
    
    # Ensure both database directories exist
    for db_path in [config.db_path, config.temp_db_path]:
        if not db_path:
            continue
            
        db_dir = os.path.dirname(db_path)
        if db_dir:
            logger.info(f"Ensuring database directory exists at: {db_dir}")
            os.makedirs(db_dir, exist_ok=True)

@app.on_event("shutdown")
async def shutdown_event():
    """Clean up database connections on shutdown"""
    logger.info("Closing database connections")
    receipt_repository = get_repository()
    temp_repository = get_temp_repository()
    receipt_repository.close()
    temp_repository.close()