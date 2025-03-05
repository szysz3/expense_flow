from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax
import json
import os
from pathlib import Path


class BaseAnalyzer(ABC):
    """Base class for receipt analyzers"""
    
    def __init__(self):
        """Initialize the base analyzer"""
        self.console = Console()
        
    @abstractmethod
    def analyze(self, receipt_data: Dict[Any, Any]) -> Dict[Any, Any]:
        """
        Analyze receipt data
        
        Args:
            receipt_data: Receipt data to analyze
            
        Returns:
            Analysis result dictionary
        """
        pass
    
    def load_prompt(self, prompt_name: str) -> str:
        """
        Load a prompt from file
        
        Args:
            prompt_name: Name of the prompt file (without extension)
            
        Returns:
            Prompt content as string
        """

        package_dir = Path(__file__).parent.parent
        prompt_path = package_dir / "prompts" / f"{prompt_name}.txt"
        
        if not prompt_path.exists():
            raise FileNotFoundError(f"Prompt file not found: {prompt_path}")
            
        with open(prompt_path, "r", encoding="utf-8") as file:
            return file.read()
    
    def parse_json_response(self, response: str) -> Dict[Any, Any]:
        """
        Parse JSON from LLM response
        
        Args:
            response: LLM response string
            
        Returns:
            Parsed JSON as dictionary
            
        Raises:
            ValueError: If no valid JSON is found
        """

        if response.startswith('```json'):
            response = response[7:]
        if response.endswith('```'):
            response = response[:-3]
        
        response = response.strip()
        
        try:
            return json.loads(response, strict=False)
        except json.JSONDecodeError:
            start = response.find('{')
            end = response.rfind('}') + 1
            if start >= 0 and end > start:
                try:
                    return json.loads(response[start:end], strict=False)
                except json.JSONDecodeError:
                    pass
            
            raise ValueError("No valid JSON found in response")
    
    def extract_items(self, parsed_data: Dict[Any, Any]) -> List[Dict[Any, Any]]:
        """
        Extract items from parsed data
        
        Args:
            parsed_data: Parsed data
            
        Returns:
            List of items
        """
        if isinstance(parsed_data, dict):
            if 'items' in parsed_data:
                return parsed_data['items']
            else:
                return [parsed_data]
        elif isinstance(parsed_data, list):
            return parsed_data
        else:
            raise ValueError("Invalid response format")
            
    def display_input_data(self, data: Dict[Any, Any]):
        """
        Display input data
        
        Args:
            data: Input data to display
        """
        self.console.print("\n[bold]Processing Receipt Data[/]")
        self.console.print(Panel(
            Syntax(json.dumps(data, indent=2), "json", theme="monokai"),
            title="Input Data",
            border_style="blue"
        ))

    def display_output_data(self, data: Dict[Any, Any]):
        """
        Display output data
        
        Args:
            data: Output data to display
        """
        self.console.print(Panel(
            Syntax(json.dumps(data, indent=2), "json", theme="monokai"),
            title="LLM Analysis Result",
            border_style="green"
        ))