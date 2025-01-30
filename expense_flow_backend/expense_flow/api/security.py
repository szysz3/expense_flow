from fastapi import Security, HTTPException, Depends
from fastapi.security.api_key import APIKeyHeader
from starlette.status import HTTP_403_FORBIDDEN
import os
from functools import lru_cache

class SecurityConfig:
    """Security configuration using environment variables"""
    def __init__(self):
        self.api_key = os.getenv('EXPENSE_FLOW_API_KEY')
        if not self.api_key:
            raise EnvironmentError("EXPENSE_FLOW_API_KEY environment variable is not set")

@lru_cache()
def get_security_config():
    return SecurityConfig()

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

async def verify_api_key(
    api_key: str = Security(api_key_header),
    config: SecurityConfig = Depends(get_security_config)
):
    if not api_key or api_key != config.api_key:
        raise HTTPException(
            status_code=HTTP_403_FORBIDDEN,
            detail="Invalid or missing API Key"
        )
    return api_key