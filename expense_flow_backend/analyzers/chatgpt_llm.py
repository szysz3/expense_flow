from typing import Dict, Any
from datetime import datetime
from rich.progress import Progress, SpinnerColumn, TextColumn, TimeElapsedColumn
from openai import OpenAI
from .base import BaseAnalyzer
from config import Config
from utils.validator import ResponseValidator
import json

class ChatGPTAnalyzer(BaseAnalyzer):
    def __init__(self, config: Config):
        super().__init__()
        self.config = config
        self.validator = ResponseValidator()

    def analyze(self, receipt_data: Dict[Any, Any]) -> Dict[Any, Any]:
        prompt = self._get_llm_prompt()
        self._display_input_data(receipt_data)
        
        max_retries = 5
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
                    task = progress.add_task(f"[cyan]Analyzing with ChatGPT (Attempt {attempt + 1}/{max_retries})...")
                    
                    client = OpenAI(api_key=self.config.chatgpt_key)
                    response = client.chat.completions.create(
                        model="gpt-4o",
                        messages=[
                            {"role": "system", "content": prompt},
                            {"role": "user", "content": json.dumps(receipt_data, indent=2)}
                        ],
                        temperature=0.7
                    )
                    result_text = response.choices[0].message.content
                
                try:
                    result = self._parse_llm_response(result_text)
                except (ValueError, json.JSONDecodeError):
                    raise ValueError("Invalid JSON response")

                if self.validator.validate(receipt_data, result):
                    self._display_output_data(result)
                    final_elapsed = (datetime.now() - total_start_time).total_seconds()
                    self.console.print(f"[green]✓ Analysis successful (Total time: {final_elapsed:.1f}s)[/]")
                    return result
                else:
                    raise ValueError("Validation failed: Result contains modified or invalid data")
                        
            except Exception as e:
                attempt += 1
                duration = (datetime.now() - start_time).total_seconds()
                total_elapsed = (datetime.now() - total_start_time).total_seconds()
                if attempt == max_retries:
                    raise ValueError(f"Failed after {max_retries} attempts ({total_elapsed:.1f}s): {str(e)}")
                self.console.print(f"[yellow]Attempt {attempt} failed after {duration:.1f}s (Total: {total_elapsed:.1f}s): {str(e)}. Retrying...[/]")