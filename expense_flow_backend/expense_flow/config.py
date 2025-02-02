from dataclasses import dataclass
from typing import Literal

@dataclass
class Config:
    endpoint: str
    key: str
    model: str = 'phi4'
    ollama_host: str = 'http://localhost:11434'
    chatgpt_key: str = ''
    llm_type: Literal['local', 'chatgpt'] = 'local'