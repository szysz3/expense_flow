from dataclasses import dataclass
from typing import Literal

@dataclass
class Config:
    endpoint: str
    key: str    
    model: str = 'hf.co/speakleash/Bielik-11B-v2.3-Instruct-GGUF:Q6_K_classifier'
    fallback_model: str = 'hf.co/unsloth/phi-4-GGUF:Q5_K_M'
    ollama_host: str = 'http://localhost:11434'
    chatgpt_key: str = ''
    llm_type: Literal['local', 'chatgpt'] = 'local' 