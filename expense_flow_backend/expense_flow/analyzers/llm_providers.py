from typing import Dict, List
from openai import OpenAI
from ollama import Client, AsyncClient
from expense_flow.config import Config
from ..services.llm_service import LLMProvider

class ChatGPTProvider(LLMProvider):
    """ChatGPT provider using OpenAI API"""
    
    def __init__(self, api_key: str, model: str = "gpt-4o"):
        """
        Initialize ChatGPT provider
        
        Args:
            api_key: OpenAI API key
            model: Model name
        """
        self.api_key = api_key
        self.model = model
        self._client = OpenAI(api_key=api_key)
        
    def generate(self, prompt: str, content: str) -> str:
        """
        Generate response from ChatGPT
        
        Args:
            prompt: System prompt
            content: User content
            
        Returns:
            ChatGPT response
        """
        response = self._client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": content}
            ],
            temperature=0.7
        )
        return response.choices[0].message.content
    
    @property
    def name(self) -> str:
        """Name of the provider"""
        return f"ChatGPT ({self.model})"


class OllamaProvider(LLMProvider):
    """Ollama provider for local LLMs"""
    
    def __init__(self, host: str, model: str):
        """
        Initialize Ollama provider
        
        Args:
            host: Ollama host
            model: Model name
        """
        self.host = host
        self.model = model
        self._client = Client(host=host)
        self._async_client = AsyncClient(host=host)
        
    def generate(self, prompt: str, content: str) -> str:
        """
        Generate response from Ollama
        
        Args:
            prompt: System prompt
            content: User content
            
        Returns:
            Ollama response
        """        
        response = self._client.generate(
            model=self.model,
            prompt=f"{prompt}\n\nInput:\n{content}",
            options={"num_ctx": 16000}
        )
        return response['response']
    
    async def chat_stream(self, messages: List[Dict[str, str]]):
        """
        Generate streaming chat response from Ollama
        
        Args:
            messages: List of message dictionaries with 'role' and 'content' keys
            
        Yields:
            Response chunks with message content
        """
        response = await self._async_client.chat(
            model=self.model,
            messages=messages,
            stream=True
        )
        
        async for chunk in response:
            yield chunk
    
    @property
    def name(self) -> str:
        """Name of the provider"""
        return f"Ollama ({self.model})"


def create_provider_from_config(config: Config, provider_type: str) -> LLMProvider:
    """
    Create an LLM provider from configuration
    
    Args:
        config: Application configuration
        provider_type: Type of provider ('chatgpt' or 'ollama')
        
    Returns:
        LLM provider
        
    Raises:
        ValueError: If provider type is invalid or required config is missing
    """
    if provider_type == 'chatgpt':
        if not config.chatgpt_key:
            raise ValueError("ChatGPT API key not configured. "
                            "Please set LLM_CHATGPT_KEY in your .env file.")
        return ChatGPTProvider(api_key=config.chatgpt_key)
        
    elif provider_type == 'ollama':
        if not config.ollama_host:
            raise ValueError("Ollama host not configured. "
                            "Please set LLM_OLLAMA_HOST in your .env file.")
        return OllamaProvider(host=config.ollama_host, model=config.ollama_model)
        
    else:
        raise ValueError(f"Invalid provider type: {provider_type}")