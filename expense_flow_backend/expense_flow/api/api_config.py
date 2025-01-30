import os
from functools import lru_cache
from typing import Optional
from dataclasses import dataclass

@dataclass
class APIConfig:
    """API configuration using environment variables"""
    max_retries: int
    retry_delay: float
    db_path: str
    
    @classmethod
    def from_env(cls) -> 'APIConfig':
        return cls(
            max_retries=int(os.getenv('MAX_RETRIES', '3')),
            retry_delay=float(os.getenv('RETRY_DELAY', '1.0')),
            db_path=os.getenv('DB_PATH', 'receipts.db')
        )

@lru_cache()
def get_api_config() -> APIConfig:
    """Get cached API configuration instance"""
    return APIConfig.from_env()