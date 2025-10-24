from dataclasses import dataclass, field
from typing import Literal, Optional
import os
from dotenv import load_dotenv
from pathlib import Path

@dataclass
class Config:
    """
    Centralized configuration class for ExpenseFlow application.
    
    This class loads configuration from .env file and provides
    typed access to all configuration settings used across the application.
    """
    base_dir: Path = field(default_factory=lambda: Path(os.path.expanduser("~")))
    data_dir: Path = field(default_factory=lambda: Path(".data"))
    
    # API settings
    api_key: str = ""
    max_retries: int = 3
    retry_delay: float = 1.0
    
    # Database paths
    db_path: str = field(default_factory=lambda: str(Path(".data/serve/receipts.sqlite3")))
    temp_db_path: str = field(default_factory=lambda: str(Path(".data/serve/temp_receipts.sqlite3")))
    
    # Azure Document Intelligence settings
    azure_endpoint: str = ""
    azure_key: str = ""
    
    # LLM settings
    llm_type: Literal['local', 'chatgpt'] = 'local'
    ollama_host: str = 'http://localhost:11434'
    ollama_model: str = 'hf.co/speakleash/Bielik-11B-v2.3-Instruct-GGUF:Q6_K_low_temp'
    ollama_fallback_model: str = 'hf.co/unsloth/phi-4-GGUF:Q5_K_M'
    chatgpt_key: str = ''
    
    # Vector database settings
    vector_db_path: Path = field(default_factory=lambda: Path(".data/vector_db"))
    embedding_model: str = "all-MiniLM-L6-v2"

    # Firebase Cloud Messaging
    firebase_credentials_path: Optional[str] = None
    firebase_credentials_json: Optional[str] = None
    firebase_app_name: str = "expense_flow_fcm"

    @classmethod
    def from_env(cls, env_file: Optional[str] = None) -> 'Config':
        """
        Create configuration by loading from .env file
        
        Args:
            env_file: Optional path to .env file. If None, tries to find .env in current directory
                      and parent directories.
            
        Returns:
            Config object with loaded settings
        """
        if env_file:
            load_dotenv(env_file, override=False)  # Don't override existing env vars
        else:
            load_dotenv(override=False)  # Don't override existing env vars
        
        config = cls()
        
        mappings = {
            # DATABASE section
            'DATABASE_DB_PATH': ('db_path', str),
            'DATABASE_TEMP_DB_PATH': ('temp_db_path', str),
            
            # AZURE section
            'AZURE_ENDPOINT': ('azure_endpoint', str),
            'AZURE_KEY': ('azure_key', str),
            
            # LLM section
            'LLM_TYPE': ('llm_type', str),
            'LLM_OLLAMA_HOST': ('ollama_host', str),
            'LLM_OLLAMA_MODEL': ('ollama_model', str),
            'LLM_OLLAMA_FALLBACK_MODEL': ('ollama_fallback_model', str),
            'LLM_CHATGPT_KEY': ('chatgpt_key', str),
            
            # API section
            'API_API_KEY': ('api_key', str),
            'API_MAX_RETRIES': ('max_retries', int),
            'API_RETRY_DELAY': ('retry_delay', float),

            # Vector DB section
            'VECTOR_DB_PATH': ('vector_db_path', str),
            'VECTOR_DB_EMBEDDING_MODEL': ('embedding_model', str),

            # Firebase section
            'FIREBASE_CREDENTIALS_PATH': ('firebase_credentials_path', str),
            'FIREBASE_CREDENTIALS_JSON': ('firebase_credentials_json', str),
            'FIREBASE_APP_NAME': ('firebase_app_name', str),
        }
        
        for env_var, (attr_name, type_func) in mappings.items():
            if env_var in os.environ and os.environ[env_var]:
                setattr(config, attr_name, type_func(os.environ[env_var]))
        
        if config.db_path and '~' in config.db_path:
            config.db_path = os.path.expanduser(config.db_path)
        if config.temp_db_path and '~' in config.temp_db_path:
            config.temp_db_path = os.path.expanduser(config.temp_db_path) 
        if config.firebase_credentials_path and '~' in config.firebase_credentials_path:
            config.firebase_credentials_path = os.path.expanduser(config.firebase_credentials_path)
            
        return config

_config_instance = None

def get_config(env_file: Optional[str] = None) -> Config:
    """
    Get the singleton Config instance
    
    Args:
        env_file: Optional path to .env file
        
    Returns:
        Config singleton instance
    """
    global _config_instance
    if _config_instance is None:
        _config_instance = Config.from_env(env_file)
    return _config_instance
