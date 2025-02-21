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
    temp_db_path: str
    azure_endpoint: str
    azure_key: str
    ollama_host: str
    ollama_model: str
    ollama_fallback_model: str
    chatgpt_key: Optional[str]
    
    @classmethod
    def from_env(cls) -> 'APIConfig':
        return cls(
            # max_retries=int(os.getenv('MAX_RETRIES', '3')),
            # retry_delay=float(os.getenv('RETRY_DELAY', '1.0')),
            # db_path=os.getenv('DB_PATH', '.data/serve/receipts.db'),
            # temp_db_path=os.getenv('TEMP_DB_PATH', '.data/serve/temp_receipts.db'),
            # azure_endpoint=os.getenv('AZURE_DOCUMENT_ENDPOINT', ''),
            # azure_key=os.getenv('AZURE_DOCUMENT_KEY', ''),
            # ollama_host=os.getenv('OLLAMA_HOST', 'http://localhost:11434'),
            # ollama_model=os.getenv('OLLAMA_MODEL', 'hf.co/speakleash/Bielik-11B-v2.3-Instruct-GGUF:Q6_K_low_temp'),
            # ollama_fallback_model=os.getenv('OLLAMA_FALLBACK_MODEL', 'hf.co/unsloth/phi-4-GGUF:Q5_K_M'),
            # chatgpt_key=os.getenv('CHATGPT_KEY')
            max_retries=3,
            retry_delay=1.0,
            db_path='.data/serve/receipts.db',
            temp_db_path='.data/serve/temp_receipts.db',
            azure_endpoint=os.getenv('AZURE_DOCUMENT_ENDPOINT', ''),
            azure_key=os.getenv('AZURE_DOCUMENT_KEY', ''),
            ollama_host='http://localhost:11434',
            ollama_model='hf.co/speakleash/Bielik-11B-v2.3-Instruct-GGUF:Q6_K_low_temp',
            ollama_fallback_model='hf.co/unsloth/phi-4-GGUF:Q5_K_M',
            chatgpt_key=os.getenv('CHATGPT_KEY')            
        )

@lru_cache()
def get_api_config() -> APIConfig:
    """Get cached API configuration instance"""
    return APIConfig.from_env()