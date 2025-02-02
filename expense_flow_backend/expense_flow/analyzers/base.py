from abc import ABC, abstractmethod
from typing import Dict, Any
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax
import json
from typing import Dict, Any, List

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

        Categories:
        - groceries
        - alcoholic_beverages
        - personal_care
        - household
        - clothing
        - entertainment
        - transportation
        - pet
        - other

        Category Definitions and Examples:
        1. groceries: food, fruits, vegetables, non-alcoholic beverages, soft drinks, ingredients, spices, meat, fish, dairy, bread, coffee, tea
        2. alcoholic_beverages: beer, wine, whisky, vodka, gin and other alcoholic drinks
        3. personal_care: hygiene products, cosmetics, medications, medical items, soap, deodorant
        4. household: cleaning supplies, decorative items, home decor, tools, maintenance items, shopping bags, storage containers, plants
        5. clothing: apparel, shoes, accessories, bags for wearing
        6. entertainment: books, electronics, games, toys (non-pet)
        7. transportation: gas, parking tickets, car supplies
        8. pet: pet food, pet supplies, pet toys
        9. other: items not fitting above categories or with empty descriptions

        Category Decision Process:
        1. Is item a discount (OPUST, rabat)? → Use same category as original item
        2. Is item a carrying/storage solution (reklamówka, torba)? → household
        3. Is item food/drink? → If contains alcohol → alcoholic_beverages, else → groceries
        4. Is description empty or unclear? → other
        5. Does item clearly match another category? → Use that category

        Rules:
        1. Analyze each item description to determine correct category
        2. Use ONLY the main categories listed above - do not use examples as categories
        3. Preserve all original fields and values - do not modify existing data
        4. Null values, placeholders or empty strings NOT ALLOWED for category field
        5. Add category field to each item in items array
        6. Keep original item order - do not modify item positions
        7. Consider item's primary purpose, not its location or packaging
        8. Discounts must match category of original item
        9. Shopping bags and packaging belong to "household" category
        10. Empty descriptions must use "other" category

        Validation Requirements:
        1. Every item MUST have exactly one category assigned
        2. Category names must exactly match the main categories listed
        3. Related items (item + its discount) must share the same category
        4. Categories must reflect item's primary purpose
        5. Double-check categorizations against real-world shop context

        IMPORTANT:
        - Output ONLY the extended JSON
        - No additional text allowed
        - Only JSON in response
        - Maintain exact JSON structure with added categories      
        """

    def _parse_llm_chunnk_response(self, response: str) -> List[Dict[Any, Any]]:
        if response.startswith('```json'):
            response = response[7:]
        if response.endswith('```'):
            response = response[:-3]
        
        parsed_data = self._parse_llm_response(response)
        
        # Handle both single item and list responses
        if isinstance(parsed_data, dict):
            # Single item case
            if 'items' in parsed_data:
                # Response includes the 'items' wrapper
                return parsed_data['items']
            else:
                # Single item without wrapper
                return [parsed_data]
        elif isinstance(parsed_data, list):
            # List of items case
            return parsed_data
        else:
            raise ValueError("Invalid response format")


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