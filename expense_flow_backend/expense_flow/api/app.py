from fastapi import FastAPI, File, Form, UploadFile, Depends, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from starlette.status import HTTP_400_BAD_REQUEST, HTTP_500_INTERNAL_SERVER_ERROR
import tempfile
import os
from typing import Optional, List, Union
from datetime import datetime
import asyncio
from functools import lru_cache
from pydantic import BaseModel, Field, validator

from .models import (
    LLMType, ProcessReceiptRequest, ProcessReceiptResponse, ErrorDetail,
    Receipt, ReceiptQuery, Category
)
from .security import verify_api_key
from .db import ReceiptRepository, DatabaseError
from .api_config import APIConfig, get_api_config
from expense_flow.document_processor.azure_processor import AzureDocumentProcessor
from expense_flow.document_processor.image_processor import ImagePreprocessor
from expense_flow.analyzers.local_llm import LocalLLMAnalyzer
from expense_flow.analyzers.chatgpt_llm import ChatGPTAnalyzer
from expense_flow.config import Config

class ProcessReceiptRequest(BaseModel):
    llm_type: LLMType = Field(default=LLMType.LOCAL)

    @validator('llm_type')
    def validate_llm_type(cls, v):
        if isinstance(v, str):
            try:
                return LLMType(v.lower())
            except ValueError:
                raise ValueError(f'Invalid LLM type: {v}')
        return v

class ProcessingError(Exception):
    def __init__(self, message: str, retry_count: Optional[int] = None):
        self.message = message
        self.retry_count = retry_count
        super().__init__(message)

@lru_cache()
def get_api_config():
    """Get cached API configuration instance"""
    return APIConfig.from_env()

def get_repository(api_config: APIConfig = Depends(get_api_config)):
    return ReceiptRepository(db_path=api_config.db_path)

def get_analyzer(config: Config, llm_type: str):
    return LocalLLMAnalyzer(config) if llm_type == 'local' else ChatGPTAnalyzer(config)

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
    config: Config,
    llm_type: LLMType,
    api_config: APIConfig
) -> Receipt:
    print(f"Starting receipt processing with LLM type: {llm_type.value}")
    
    image_preprocessor = ImagePreprocessor()
    doc_processor = AzureDocumentProcessor(config)
    analyzer = get_analyzer(config, llm_type.value)
    
    print(f"Using analyzer: {analyzer.__class__.__name__}")
    
    retry_count = 0
    last_error = None
    processed_path = None
    
    while retry_count < api_config.max_retries:
        try:
            print(f"Processing attempt {retry_count + 1}")
            
            # Process image
            processed_path, success = image_preprocessor.process(file_path)
            if not success:
                raise ProcessingError("Image preprocessing failed")
            
            print("Image preprocessing successful")
            
            # Run OCR
            raw_data = doc_processor.process_image(processed_path if success else file_path)
            receipt_data = doc_processor.preprocess_receipt(raw_data)
            
            print("OCR processing successful")
            
            # Analyze with LLM - Convert the dict to Receipt model
            analysis_result = analyzer.analyze(receipt_data)
            return Receipt(**analysis_result)
            
        except Exception as e:
            retry_count += 1
            last_error = str(e)
            print(f"Attempt {retry_count} failed: {last_error}")
            
            if isinstance(e, (ProcessingError, TimeoutError)):
                if retry_count < api_config.max_retries:
                    print(f"Waiting {api_config.retry_delay} seconds before retry")
                    await asyncio.sleep(api_config.retry_delay)
            else:
                print(f"Non-retryable error encountered: {type(e).__name__}")
                raise
                
        finally:
            if processed_path and os.path.exists(processed_path):
                try:
                    os.remove(processed_path)
                except Exception as e:
                    print(f"Warning: Failed to remove processed file: {e}")
    
    raise ProcessingError(f"Processing failed after {retry_count} attempts: {last_error}", retry_count)

def get_analyzer(config: Config, llm_type: str) -> Union[LocalLLMAnalyzer, ChatGPTAnalyzer]:
    """Create the appropriate analyzer based on LLM type string"""
    if llm_type == LLMType.LOCAL.value:
        return LocalLLMAnalyzer(config)
    elif llm_type == LLMType.CHATGPT.value:
        return ChatGPTAnalyzer(config)
    else:
        raise ValueError(f"Invalid LLM type: {llm_type}")

def get_analyzer(config: Config, llm_type: str) -> Union[LocalLLMAnalyzer, ChatGPTAnalyzer]:
    """Create the appropriate analyzer based on LLM type string"""
    if llm_type == LLMType.LOCAL.value:
        return LocalLLMAnalyzer(config)
    elif llm_type == LLMType.CHATGPT.value:
        return ChatGPTAnalyzer(config)
    else:
        raise ValueError(f"Invalid LLM type: {llm_type}")

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
    """
    Analyze receipt image and store results in database
    """
    print(f"Received request with LLM type: {request.llm_type}")
    
    if not file.content_type in ["image/jpeg", "image/png", "application/pdf"]:
        raise HTTPException(
            status_code=HTTP_400_BAD_REQUEST,
            detail={"error": "Invalid file type", "detail": "File must be JPEG, PNG or PDF"}
        )
    
    temp_file = None
    try:
        # Get appropriate file extension
        ext = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "application/pdf": ".pdf"
        }.get(file.content_type, ".jpg")
        
        temp_file = tempfile.NamedTemporaryFile(suffix=ext, delete=False)
        content = await file.read()
        temp_file.write(content)
        temp_file.close()
        
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
            detail={"error": "Processing failed", "detail": e.message, "retry_count": e.retry_count}
        )
    except DatabaseError as e:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": "Database error", "detail": str(e)}
        )
    except Exception as e:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": "Internal server error", "detail": str(e)}
        )
    finally:
        if temp_file and os.path.exists(temp_file.name):
            try:
                os.remove(temp_file.name)
            except Exception as e:
                print(f"Warning: Failed to remove temporary file: {e}")

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
    """
    Retrieve a specific receipt by ID
    """
    try:
        with repository.transaction() as repo:
            receipt = repo.get_receipt(receipt_id)
            
        if not receipt:
            raise HTTPException(
                status_code=404,
                detail={"error": "Not found", "detail": f"Receipt {receipt_id} not found"}
            )
            
        return receipt
        
    except DatabaseError as e:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": "Database error", "detail": str(e)}
        )

@app.post(
    "/api/receipts/search",
    response_model=List[Receipt],
    responses={
        500: {"model": ErrorDetail}
    }
)
async def search_receipts(
    query: ReceiptQuery,
    api_key: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_repository)
):
    """
    Search receipts with various filters
    """
    try:
        with repository.transaction() as repo:
            receipts = repo.search_receipts(
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
            detail={"error": "Database error", "detail": str(e)}
        )

@app.get(
    "/api/statistics/spending",
    responses={
        500: {"model": ErrorDetail}
    }
)
async def calculate_spending(
    start_date: datetime,
    end_date: datetime,
    categories: Optional[List[Category]] = None,
    item_description: Optional[str] = None,
    api_key: str = Depends(verify_api_key),
    repository: ReceiptRepository = Depends(get_repository)
):
    """
    Calculate total spending based on various filters
    """
    try:
        with repository.transaction() as repo:
            total = repo.calculate_spending(
                start_date=start_date,
                end_date=end_date,
                categories=categories,
                item_description=item_description
            )
        return {"total": str(total)}
        
    except DatabaseError as e:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": "Database error", "detail": str(e)}
        )

@app.on_event("startup")
async def startup_event():
    """Ensure database exists on startup"""
    api_config = get_api_config()
    os.makedirs(os.path.dirname(api_config.db_path) or '.', exist_ok=True)

@app.on_event("shutdown")
async def shutdown_event():
    """Clean up database connection on shutdown"""
    repository = get_repository()
    repository.close()