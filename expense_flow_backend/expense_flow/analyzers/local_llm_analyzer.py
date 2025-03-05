from typing import Dict, Any, List
from .base_analyzer import BaseAnalyzer
from expense_flow.config import Config
from expense_flow.utils.validator import ResponseValidator
from .llm_service import LLMService
from .llm_providers import OllamaProvider


class LocalLLMAnalyzer(BaseAnalyzer):
    """Receipt analyzer using local LLM with Ollama"""
    
    def __init__(self, config: Config):
        """
        Initialize the local LLM analyzer
        
        Args:
            config: Application configuration
        """
        super().__init__()
        
        if not config.ollama_host:
            raise ValueError("Ollama host not configured. "
                             "Please set LLM_OLLAMA_HOST in your .env file.")
        
        self.validator = ResponseValidator()
        self.service = LLMService(self.console, self.validator)
        
        self.providers = []
        
        if config.ollama_model:
            self.providers.append(
                OllamaProvider(host=config.ollama_host, model=config.ollama_model)
            )
            
        if config.ollama_fallback_model and config.ollama_fallback_model != config.ollama_model:
            self.providers.append(
                OllamaProvider(host=config.ollama_host, model=config.ollama_fallback_model)
            )

    def analyze(self, receipt_data: Dict[Any, Any]) -> Dict[Any, Any]:
        """
        Analyze receipt data with fallback to different models if needed
        
        Args:
            receipt_data: Receipt data to analyze
            
        Returns:
            Analysis result
            
        Raises:
            ValueError: If all models fail
        """
        if not self.providers:
            raise ValueError("No Ollama models configured")
            
        prompt = self.load_prompt("receipt_analyzer")
        self.display_input_data(receipt_data)
        
        result = self.service.analyze_with_fallback(
            providers=self.providers,
            prompt=prompt,
            data=receipt_data
        )
        
        self.display_output_data(result)
        return result