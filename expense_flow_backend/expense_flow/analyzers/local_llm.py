from typing import Dict, Any, List
from datetime import datetime
from rich.progress import Progress, SpinnerColumn, TextColumn, TimeElapsedColumn
from ollama import Client
from .base import BaseAnalyzer
from expense_flow.config import Config
from expense_flow.utils.validator import ResponseValidator
import json
import math

class LocalLLMAnalyzer(BaseAnalyzer):
    def __init__(self, config: Config, chunk_size: int = 10):
        super().__init__()
        self.config = config
        self.client = Client(host=config.ollama_host)
        self.validator = ResponseValidator()
        self.chunk_size = chunk_size

    def _chunk_items(self, items: List[Dict[Any, Any]]) -> List[List[Dict[Any, Any]]]:
        return [items[i:i + self.chunk_size] for i in range(0, len(items), self.chunk_size)]

    def _process_chunk(self, chunk: List[Dict[Any, Any]], chunk_index: int, 
                      progress: Progress, task_id: int) -> List[Dict[Any, Any]]:
        max_retries = 5
        attempt = 0
        
        while attempt < max_retries:
            try:
                progress.update(task_id, description=f"Processing chunk {chunk_index + 1} (Attempt {attempt + 1}/{max_retries})")
            
                chunk_data = {"items": chunk}
                self._display_input_data(chunk_data)

                response = self.client.generate(
                    model=self.config.model,
                    prompt=f"{self._get_llm_prompt()}\n\nInput:\n{json.dumps(chunk, indent=2)}"
                )
                
                result = self._parse_llm_chunnk_response(response['response'])
                
                self._display_output_data(result)

                if len(result) != len(chunk):
                    raise ValueError(f"Result size mismatch. Expected {len(chunk)}, got {len(result)}")
                
                for orig_item, result_item in zip(chunk, result):
                    if not all(key in result_item for key in orig_item):
                        raise ValueError("Missing original fields in result item")
                    if 'category' not in result_item:
                        raise ValueError("Missing category field in result item")
                
                return result
                
            except Exception as e:
                attempt += 1
                if attempt == max_retries:
                    raise ValueError(f"Failed to process chunk {chunk_index + 1} after {max_retries} attempts: {str(e)}")
                self.console.print(f"[yellow]Chunk {chunk_index + 1} attempt {attempt} failed: {str(e)}. Retrying...[/]")

    def analyze(self, receipt_data: Dict[Any, Any]) -> Dict[Any, Any]:
        self._display_input_data(receipt_data)
        
        # Extract items and split into chunks
        items = receipt_data.get('items', [])
        chunks = self._chunk_items(items)
        
        total_start_time = datetime.now()
        processed_items = []
        
        try:
            with Progress(
                SpinnerColumn(),
                TimeElapsedColumn(),
                TextColumn("{task.description}"),
                refresh_per_second=4,
                console=self.console,
                transient=True
            ) as progress:
                task = progress.add_task("Processing chunks...", total=len(chunks))
                
                for i, chunk in enumerate(chunks):
                    chunk_result = self._process_chunk(chunk, i, progress, task)
                    processed_items.extend(chunk_result)
                    progress.advance(task)
            
            result = receipt_data.copy()
            result['items'] = processed_items
            
            self._display_output_data(result)
            
            if self.validator.validate(receipt_data, result):
                final_elapsed = (datetime.now() - total_start_time).total_seconds()
                self.console.print(f"[green]✓ Analysis successful (Total time: {final_elapsed:.1f}s)[/]")
                return result
            else:
                raise ValueError("Validation failed: Result contains modified or invalid data")
                
        except Exception as e:
            total_elapsed = (datetime.now() - total_start_time).total_seconds()
            raise ValueError(f"Analysis failed ({total_elapsed:.1f}s): {str(e)}")