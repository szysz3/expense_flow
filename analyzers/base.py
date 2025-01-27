from abc import ABC, abstractmethod
from typing import Dict, Any
from datetime import datetime
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax
import json

class BaseAnalyzer(ABC):
    def __init__(self):
        self.console = Console()

    @abstractmethod
    def analyze(self, receipt_data: Dict[Any, Any]) -> Dict[Any, Any]:
        pass

    def _get_llm_prompt(self) -> str:
        return """
        Task: Extend receipt JSON with item categories
        
        Input: JSON with merchant and receipt items. In Polish language.
        Output: Same structure and values with added "category" field for each item.
        
        Categories:
        - groceries (examples: food, fruits, vegetables, non-alcoholic beverages, ingredients, species, meat, fish, chicken, turkey, pork, coffee, tea and similar)
        - alcoholic_beverages (examples: beer, wine, whisky, vodka, gin and similar)
        - personal_care (examples: hygiene, cosmetics, medications, medical care, soap, deodorant and similar)
        - household (examples: cleaning, decorative items, plants, utilities, tools, maintenance items, soil, feritilizer and similar)
        - clothing (examples: apparel, shoes, bags, sneakers, shirt, scarf and similar)
        - entertainment (examples: books, electronics, games and similar)
        - transportation (examples: gas, parking tickets, car wash and similar)
        - pet (examples: cat food)
        - other
        
        Rules:
        1. Analyze item description to determine category.
        2. Use exact category names as listed. IMPORTANT: use only main categories, not examples like: gas, food, fish or apparel!
        3. Preserve all original fields and values IMPORTANT! DO NOT CHANGE ANY EXISTING FIELDS!
        4. Null values, placeholders or empty values NOT ALLOWED!
        5. Add category field to each item in items array.
        6. Be strict and carefull.
        
        IMPORTANT! Please output ONLY extended JSON no other text. ONLY JSON ALLOWED. ANY OTHER TEXT PROHIBITED!        
        """

    def _parse_llm_response(self, response: str) -> Dict[Any, Any]:
        try:
            return json.loads(response, strict=False) if isinstance(response, str) else json.loads(response.decode(), strict=False)
        except json.JSONDecodeError:
            start = response.find('{')
            end = response.rfind('}') + 1
            if start >= 0 and end > start:
                return json.loads(response[start:end], strict=False)
            raise ValueError("No valid JSON found in response")

    def _display_input_data(self, data: Dict[Any, Any]):
        self.console.print("\n[bold]Processing Receipt Data[/]")
        self.console.print(Panel(
            Syntax(json.dumps(data, indent=2), "json", theme="monokai"),
            title="Input Data",
            border_style="blue"
        ))

    def _display_output_data(self, data: Dict[Any, Any]):
        self.console.print(Panel(
            Syntax(json.dumps(data, indent=2), "json", theme="monokai"),
            title="LLM Analysis Result",
            border_style="green"
        ))