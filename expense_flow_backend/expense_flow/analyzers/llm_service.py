from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, List
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, TimeElapsedColumn
from datetime import datetime
import json
from expense_flow.utils.validator import ResponseValidator


class LLMProvider(ABC):
    """Interface for LLM providers"""
    
    @abstractmethod
    def generate(self, prompt: str, content: str) -> str:
        """
        Generate response from LLM
        
        Args:
            prompt: System prompt
            content: User content/input
            
        Returns:
            LLM response as string
        """
        pass
    
    @property
    @abstractmethod
    def name(self) -> str:
        """Name of the LLM provider"""
        pass


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
        
    def analyze_with_retry(
        self, 
        provider: LLMProvider, 
        prompt: str, 
        data: Dict[Any, Any], 
        max_retries: int = 5
    ) -> Dict[Any, Any]:
        """
        Analyze data with retry logic
        
        Args:
            provider: LLM provider
            prompt: System prompt
            data: Data to analyze
            max_retries: Maximum number of retry attempts
            
        Returns:
            Analysis result
            
        Raises:
            ValueError: If analysis fails after max retries
        """
        attempt = 0
        total_start_time = datetime.now()
        
        while attempt < max_retries:
            try:
                start_time = datetime.now()
                
                with Progress(
                    SpinnerColumn(),
                    TimeElapsedColumn(),
                    TextColumn("{task.description}"),
                    refresh_per_second=4,
                    console=self.console,
                    transient=True
                ) as progress:
                    task = progress.add_task(
                        f"[cyan]Analyzing with {provider.name} (Attempt {attempt + 1}/{max_retries})..."
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
                        raise ValueError(f"Invalid JSON response: {str(e)}")
                
                if self.validator.validate(data, result):
                    final_elapsed = (datetime.now() - total_start_time).total_seconds()
                    self.console.print(f"[green]✓ Analysis successful with {provider.name} (Total time: {final_elapsed:.1f}s)[/]")
                    return result
                else:
                    raise ValueError("Validation failed: Result contains modified or invalid data")
                    
            except Exception as e:
                attempt += 1
                duration = (datetime.now() - start_time).total_seconds()
                total_elapsed = (datetime.now() - total_start_time).total_seconds()
                
                if attempt == max_retries:
                    raise ValueError(f"Failed after {max_retries} attempts ({total_elapsed:.1f}s): {str(e)}")
                
                self.console.print(
                    f"[yellow]Attempt {attempt} failed after {duration:.1f}s "
                    f"(Total: {total_elapsed:.1f}s): {str(e)}. Retrying...[/]"
                )
                
    def analyze_with_fallback(
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
                result = self.analyze_with_retry(provider, prompt, data)
                
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