from typing import Dict, Any
from .base_analyzer import BaseAnalyzer
from expense_flow.config import Config
from expense_flow.utils.validator import ResponseValidator
from .llm_service import LLMService
from .llm_providers import ChatGPTProvider


class ChatGPTAnalyzer(BaseAnalyzer):
    """Receipt analyzer using ChatGPT via OpenAI API"""
    
    def __init__(self, config: Config):
        """
        Initialize the ChatGPT analyzer
        
        Args:
            config: Application configuration
        """
        super().__init__()
        
        if not config.chatgpt_key:
            raise ValueError("ChatGPT API key not configured. "
                             "Please set LLM_CHATGPT_KEY in your .env file.")
        
        self.validator = ResponseValidator()
        self.provider = ChatGPTProvider(api_key=config.chatgpt_key)
        self.service = LLMService(self.console, self.validator)

    def analyze(self, receipt_data: Dict[Any, Any]) -> Dict[Any, Any]:
        """
        Analyze receipt data using ChatGPT
        
        Args:
            receipt_data: Receipt data to analyze
            
        Returns:
            Analysis result
            
        Raises:
            ValueError: If analysis fails
        """
        prompt = self.load_prompt("receipt_analyzer")
        self.display_input_data(receipt_data)
        
        result = self.service.analyze_with_retry(
            provider=self.provider,
            prompt=prompt,
            data=receipt_data
        )
        
        self.display_output_data(result)
        return result