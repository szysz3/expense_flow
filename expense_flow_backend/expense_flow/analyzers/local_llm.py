from typing import Dict, Any
from datetime import datetime
from rich.progress import Progress, SpinnerColumn, TextColumn, TimeElapsedColumn
from ollama import Client
from .base import BaseAnalyzer
from expense_flow.config import Config
from expense_flow.utils.validator import ResponseValidator
import json

class LocalLLMAnalyzer(BaseAnalyzer):
    """
    Receipt analyzer using local LLM with Ollama
    """
    def __init__(self, config: Config):
        """
        Initialize the local LLM analyzer
        
        Args:
            config: Application configuration
        """
        super().__init__()
        self.config = config
        
        if not config.ollama_host:
            raise ValueError("Ollama host not configured. "
                             "Please set LLM_OLLAMA_HOST in your .env file.")
        
        self.client = Client(host=config.ollama_host)
        self.validator = ResponseValidator()
        
    def _try_model(self, model: str, receipt_data: Dict[Any, Any], max_retries: int = 3) -> Dict[Any, Any]:
        """
        Attempt analysis with a specific model
        
        Args:
            model: Model name
            receipt_data: Receipt data to analyze
            max_retries: Maximum number of retry attempts
            
        Returns:
            Analysis result dictionary
            
        Raises:
            ValueError: If analysis fails after max retries
        """
        prompt = self._get_llm_prompt()
        attempt = 0
        start_time = datetime.now()
        while attempt < max_retries:
            try:
                with Progress(
                    SpinnerColumn(),
                    TimeElapsedColumn(),
                    TextColumn("{task.description}"),
                    refresh_per_second=4,
                    console=self.console,
                    transient=True
                ) as progress:
                    task = progress.add_task(
                        f"[cyan]Analyzing with model {model} (Attempt {attempt + 1}/{max_retries})..."
                    )
                    
                    response = self.client.generate(
                        model=model,
                        prompt=f"{prompt}\n\nInput:\n{json.dumps(receipt_data, indent=2)}",
                        options={"num_ctx": 8192}
                    )
                    
                    try:
                        result = self._parse_llm_response(response['response'])
                    except (ValueError, json.JSONDecodeError):
                        raise ValueError(f"Invalid JSON response from model {model}")
                        
                    if self.validator.validate(receipt_data, result):
                        duration = (datetime.now() - start_time).total_seconds()
                        self.console.print(f"[green]✓ Analysis successful with {model} ({duration:.1f}s)[/]")
                        return result
                    else:
                        raise ValueError(f"Validation failed for model {model}: Result contains modified or invalid data")
                        
            except Exception as e:
                attempt += 1
                duration = (datetime.now() - start_time).total_seconds()
                if attempt == max_retries:
                    self.console.print(f"[red]Model {model} failed after {max_retries} attempts ({duration:.1f}s)[/]")
                    raise ValueError(f"Model {model} failed: {str(e)}")
                self.console.print(f"[yellow]Attempt {attempt} with {model} failed ({duration:.1f}s): {str(e)}. Retrying...[/]")
                
        raise ValueError(f"All attempts failed for model {model}")

    def analyze(self, receipt_data: Dict[Any, Any]) -> Dict[Any, Any]:
        """
        Analyze receipt data with fallback to different models if needed
        
        Args:
            receipt_data: Receipt data to analyze
            
        Returns:
            Analysis result dictionary
            
        Raises:
            ValueError: If all models fail
        """
        self._display_input_data(receipt_data)
        
        models_to_try = [self.config.ollama_model, self.config.ollama_fallback_model]
        total_start_time = datetime.now()
        
        for i, model in enumerate(models_to_try, 1):
            try:
                result = self._try_model(model, receipt_data)
                self._display_output_data(result)
                
                total_duration = (datetime.now() - total_start_time).total_seconds()
                self.console.print(f"[green]✓ Analysis completed successfully with {model} (Total time: {total_duration:.1f}s)[/]")
                return result
                
            except Exception as e:
                if i == len(models_to_try):
                    total_duration = (datetime.now() - total_start_time).total_seconds()
                    raise ValueError(
                        f"All models failed after {total_duration:.1f}s. "
                        f"Last error: {str(e)}"
                    )
                self.console.print(f"[yellow]Model {model} failed, trying next model...[/]")
                
        raise ValueError("No models succeeded in analyzing the receipt")