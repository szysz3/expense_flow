from abc import ABC, abstractmethod
from typing import Dict, Any
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
        
        Input: JSON with receipt items.
        Output: Same structure and values with added "category" field for each item.
        
        Categories and examples:
        - groceries (examples: food, fruits, vegetables, non-alcoholic beverages, soft drinks like cola, ingredients, species, meat, fish, chicken, turkey, pork, coffee, tea and similar)
        - alcoholic_beverages (examples: beer, wine, whisky, vodka, gin, only drinks with alcohol)
        - personal_care (examples: hygiene, cosmetics, medications, medical care, soap, deodorant and everything used for personal care)
        - household (examples: cleaning, decorative items, home decor, plants, utilities, tools, maintenance items, soil, feritilizer, home and garden maintenance)
        - clothing (examples: apparel, shoes, bags, sneakers, shirt, scarf, everything to wear)
        - entertainment (examples: books, electronics, games and similar entertaniment related)
        - transportation (examples: gas, parking tickets, car wash and similar)
        - pet (examples: cat food, pet toys)
        - other
        
        Rules:
        1. Go through items array and analyze each item description to determine category. 
        2. Use exact category names as listed. IMPORTANT: use only main categories! Do not choose from examples like: gas, food, fish or apparel!
        3. Preserve all original fields and values IMPORTANT! DO NOT CHANGE ANY ALERADY EXISTING FIELDS, FOCUS ON ADDING CATEGORIES ONLY!
        4. Null values, placeholders or empty values NOT ALLOWED!
        5. Add category field to each item in items array.
        6. Be strict and carefull. Do not change order.
        7. Double check whether categories match item description taking into account this is a shop receipt. Use your common sense.
        
        IMPORTANT! Please output ONLY extended JSON no other text. ONLY JSON ALLOWED. ANY OTHER TEXT PROHIBITED!        
        """

    def _parse_llm_chunnk_response(self, response: str) -> Dict[Any, Any]:
            if response.startswith('```json'):
                response = response[7:]
            if response.endswith('```'):
                response = response[:-3]
            return self._parse_llm_response(response)


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