from datetime import datetime
from typing import Dict, Any, List
import json
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, TimeElapsedColumn
from rich.panel import Panel
from rich.syntax import Syntax
from rich.markdown import Markdown

from expense_flow.services.rag_service import RAGService
from expense_flow.utils.validator import ResponseValidator
from expense_flow.utils.retry import retry_async, ProcessingError

class LLMProvider:
    """Interface for LLM providers"""
    
    def generate(self, prompt: str, content: str) -> str:
        """
        Generate response from LLM
        
        Args:
            prompt: System prompt
            content: User content/input
            
        Returns:
            LLM response as string
        """
        raise NotImplementedError("LLM providers must implement generate method")
    
    @property
    def name(self) -> str:
        """Name of the LLM provider"""
        raise NotImplementedError("LLM providers must implement name property")


class LLMService:
    """Service for interacting with LLM providers"""
    
    def __init__(self, console: Console, validator: ResponseValidator):
        """
        Initialize LLM service
        
        Args:
            console: Rich console for output
            validator: Response validator
        """
        self.console = console
        self.validator = validator
        
    async def analyze_with_retry(
        self, 
        provider: LLMProvider, 
        prompt: str, 
        data: Dict[Any, Any], 
        max_retries: int = 5,
        retry_delay: float = 1.0
    ) -> Dict[Any, Any]:
        """
        Analyze data with retry logic
        
        Args:
            provider: LLM provider
            prompt: System prompt
            data: Data to analyze
            max_retries: Maximum number of retry attempts
            retry_delay: Delay between retries in seconds
            
        Returns:
            Analysis result
            
        Raises:
            ProcessingError: If analysis fails after max retries
        """
        
        async def _analyze():
            with Progress(
                SpinnerColumn(),
                TimeElapsedColumn(),
                TextColumn("{task.description}"),
                refresh_per_second=4,
                console=self.console,
                transient=True
            ) as progress:
                formatted_prompt = Markdown(f"{prompt}\n\nInput:\n{json.dumps(data, indent=2)}")
                self.console.print(Panel(
                    formatted_prompt,
                    title="Prompt",
                    border_style="blue"
                ))
            
                task = progress.add_task(
                    f"[cyan]Analyzing with {provider.name}..."
                )
                
                response_text = provider.generate(prompt, json.dumps(data, indent=2))
                
                try:
                    if isinstance(response_text, str):
                        result = self._parse_json(response_text)
                    elif isinstance(response_text, bytes):
                        result = self._parse_json(response_text.decode())
                    else:
                        raise ValueError(f"Unexpected response type: {type(response_text)}")
                except (ValueError, json.JSONDecodeError) as e:
                    raise ProcessingError(f"Invalid JSON response: {str(e)}")
            
            if not self.validator.validate(data, result):
                raise ProcessingError("Validation failed: Result contains modified or invalid data")
                
            return result
        
        total_start_time = datetime.now()
        result = await retry_async(
            _analyze,
            max_retries=max_retries,
            retry_delay=retry_delay
        )
        final_elapsed = (datetime.now() - total_start_time).total_seconds()
        self.console.print(f"[green]✓ Analysis successful with {provider.name} (Total time: {final_elapsed:.1f}s)[/]")
        return result
    
    async def analyze_with_fallback(
        self, 
        providers: List[LLMProvider], 
        prompt: str, 
        data: Dict[Any, Any]
    ) -> Dict[Any, Any]:
        """
        Analyze data with fallback to alternative providers
        
        Args:
            providers: List of LLM providers to try in order
            prompt: System prompt
            data: Data to analyze
            
        Returns:
            Analysis result
            
        Raises:
            ValueError: If all providers fail
        """
        total_start_time = datetime.now()
        
        for i, provider in enumerate(providers, 1):
            try:
                result = await self.analyze_with_retry(provider, prompt, data)
                
                total_duration = (datetime.now() - total_start_time).total_seconds()
                self.console.print(
                    f"[green]✓ Analysis completed successfully with {provider.name} "
                    f"(Total time: {total_duration:.1f}s)[/]"
                )
                return result
                
            except Exception as e:
                if i == len(providers):
                    total_duration = (datetime.now() - total_start_time).total_seconds()
                    raise ValueError(
                        f"All providers failed after {total_duration:.1f}s. "
                        f"Last error: {str(e)}"
                    )
                self.console.print(f"[yellow]Provider {provider.name} failed, trying next provider...[/]")
                
        raise ValueError("No providers succeeded in analyzing the data")
        
    async def analyze_with_rag(
        self, 
        providers: List[LLMProvider], 
        prompt: str,
        rag_service: RAGService, 
        data: Dict[Any, Any],
    ) -> Dict[Any, Any]:
        """
        Analyze data with RAG enhancement
        
        Args:
            provider: LLM provider
            prompt: Base system prompt
            rag_service: RAG service for retrieving similar items
            data: Data to analyze
            max_retries: Maximum number of retry attempts
            retry_delay: Delay between retries in seconds
            
        Returns:
            Analysis result
        """
        # Get similar items for each item in the receipt
        enhanced_data = data.copy()
        enhanced_data["similar_items"] = {}
        
        for idx, item in enumerate(data.get("items", [])):
            description = item.get("description", "")
            if description:
                examples = rag_service.get_examples_for_item(description, limit=2)
                enhanced_data["similar_items"][idx] = examples
    
        # Analyze with the enhanced prompt and data
        return await self.analyze_with_fallback(providers, prompt, enhanced_data)

    def _parse_json(self, response: str) -> Dict[Any, Any]:
        """
        Parse JSON from response
        
        Args:
            response: Response string
            
        Returns:
            Parsed JSON
            
        Raises:
            ValueError: If no valid JSON is found
        """
        if response.startswith('```json'):
            response = response[7:]
        if response.endswith('```'):
            response = response[:-3]
        
        try:
            return json.loads(response.strip(), strict=False)
        except json.JSONDecodeError:
            start = response.find('{')
            end = response.rfind('}') + 1
            if start >= 0 and end > start:
                try:
                    return json.loads(response[start:end], strict=False)
                except json.JSONDecodeError:
                    pass
            
            raise ValueError("No valid JSON found in response")