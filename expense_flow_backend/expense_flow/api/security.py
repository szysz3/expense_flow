from fastapi import Security, HTTPException, Depends
from fastapi.security.api_key import APIKeyHeader
from starlette.status import HTTP_403_FORBIDDEN
from expense_flow.config import get_config

# API key header
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

async def verify_api_key(api_key: str = Security(api_key_header)):
    """
    Verify that the provided API key matches the one in configuration
    
    Args:
        api_key: API key from request header
        
    Returns:
        API key if valid
        
    Raises:
        HTTPException: If API key is invalid or missing
    """
    config = get_config()
    
    if not config.api_key:
        raise RuntimeError("API key not configured. Set API_API_KEY in your .env file")
    
    if not api_key or api_key != config.api_key:
        raise HTTPException(
            status_code=HTTP_403_FORBIDDEN,
            detail="Invalid or missing API Key"
        )
    return api_key