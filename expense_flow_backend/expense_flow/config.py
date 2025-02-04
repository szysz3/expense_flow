from dataclasses import dataclass
from typing import Literal

@dataclass
class Config:
    endpoint: str
    key: str
    # model: str = 'hf.co/unsloth/phi-4-GGUF:Q5_K_M'
    model: str = 'hf.co/unsloth/DeepSeek-R1-Distill-Llama-8B-GGUF:Q8_0'
    ollama_host: str = 'http://localhost:11434'
    chatgpt_key: str = ''
    llm_type: Literal['local', 'chatgpt'] = 'local' 