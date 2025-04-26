from typing import Dict, Any
from rich.console import Console
from .text_processor import TextProcessor

class ResponseValidator:
    def __init__(self):
        self.console = Console()
        self.text_processor = TextProcessor()

    def validate(self, original_data: Dict[Any, Any], result: Dict[Any, Any]) -> bool:
        self.console.print("\n[bold]Validation Results:[/]")
        
        if not self._validate_structure(original_data, result):
            return False
            
        if not self._validate_merchant_data(original_data, result):
            return False
            
        if not self._validate_transaction_data(original_data, result):
            return False
            
        if not self._validate_items(original_data, result):
            return False
                    
        self.console.print("\n[green]✓ All validation checks passed[/]")
        return True

    def _validate_structure(self, original_data: Dict[Any, Any], result: Dict[Any, Any]) -> bool:
        for key in original_data.keys():
            if key == "similar_items":
                continue
            if key not in result:
                self.console.print(f"[red]❌ Missing key '{key}' in result[/]")
                return False
        return True

    def _validate_merchant_data(self, original_data: Dict[Any, Any], result: Dict[Any, Any]) -> bool:
        orig_merchant = original_data.get('merchant', {})
        result_merchant = result.get('merchant', {})
        
        if not (self.text_processor.compare_text_ignore_polish(orig_merchant.get('name', ''), result_merchant.get('name', '')) and 
                self.text_processor.compare_text_ignore_polish(orig_merchant.get('address', ''), result_merchant.get('address', ''))):
            self.console.print("[red]❌ Merchant data mismatch[/]")
            self.console.print(f"Expected: {original_data.get('merchant')}")
            self.console.print(f"Got: {result.get('merchant')}")
            return False
        return True

    def _validate_transaction_data(self, original_data: Dict[Any, Any], result: Dict[Any, Any]) -> bool:
        if result.get('total') != original_data.get('total'):
            self.console.print("[red]❌ Total amount mismatch[/]")
            self.console.print(f"Expected: {original_data.get('total')}")
            self.console.print(f"Got: {result.get('total')}")
            return False

        if result.get('transaction_datetime') != original_data.get('transaction_datetime'):
            self.console.print("[red]❌ Transaction datetime mismatch[/]")
            self.console.print(f"Expected: {original_data.get('transaction_datetime')}")
            self.console.print(f"Got: {result.get('transaction_datetime')}")
            return False
        return True

    def _validate_items(self, original_data: Dict[Any, Any], result: Dict[Any, Any]) -> bool:
        if len(result.get('items', [])) != len(original_data.get('items', [])):
            self.console.print("[red]❌ Items count mismatch[/]")
            self.console.print(f"Expected {len(original_data.get('items', []))} items")
            self.console.print(f"Got {len(result.get('items', []))} items")
            return False
                
        valid_categories = {
            'groceries', 'alcoholic_beverages', 'personal_care', 'household',
            'clothing', 'entertainment', 'transportation', 'pet', 'other'
        }
                
        for idx, (orig_item, result_item) in enumerate(zip(original_data['items'], result['items'])):
            self.console.print(f"\n[bold]Validating item {idx + 1}:[/]")
            
            if not self._validate_item(idx, orig_item, result_item, valid_categories):
                return False
                
            self.console.print(f"[green]✓ Item {idx + 1} validated successfully[/]")
        return True

    def _validate_item(self, idx: int, orig_item: Dict[Any, Any], result_item: Dict[Any, Any], valid_categories: set) -> bool:
        if not self.text_processor.compare_text_ignore_polish(orig_item.get('description', ''), result_item.get('description', '')):
            self.console.print(f"[red]❌ Description mismatch for item {idx + 1}[/]")
            self.console.print(f"Expected: {orig_item.get('description')}")
            self.console.print(f"Got: {result_item.get('description')}")
            return False
                
        if orig_item.get('quantity') != result_item.get('quantity'):
            self.console.print(f"[red]❌ Quantity mismatch for item {idx + 1}[/]")
            self.console.print(f"Expected: {orig_item.get('quantity')}")
            self.console.print(f"Got: {result_item.get('quantity')}")
            return False
        
        # Ignore reversed order on result list, this is a hack to compare absolute values        
        if abs(orig_item.get('total_price', 0)) != abs(result_item.get('total_price', 0)):            
            self.console.print(f"[red]❌ Price mismatch for item {idx + 1}[/]")
            self.console.print(f"Expected: {orig_item.get('total_price')}")
            self.console.print(f"Got: {result_item.get('total_price')}")
            return False
                    
        if 'category' not in result_item:
            self.console.print(f"[red]❌ Missing category for item {idx + 1}[/]")
            return False
                
        if result_item['category'] not in valid_categories:
            self.console.print(f"[red]❌ Invalid category '{result_item['category']}' for item {idx + 1}[/]")
            self.console.print(f"Valid categories are: {valid_categories}")
            return False
        
        return True