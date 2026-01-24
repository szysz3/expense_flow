import copy
from typing import Any, Dict, Tuple

from rich.console import Console

from expense_flow.api.models import DEFAULT_QUANTITY
from .text_processor import TextProcessor


class ResponseValidator:
    """Validates OCR results against original data.

    The validate method returns a tuple containing the validation result
    and a normalized copy of the result with defaults applied.
    The original input is never mutated.
    """

    def __init__(self):
        self.console = Console()
        self.text_processor = TextProcessor()
        self.optional_keys = {"merchant", "transaction_datetime"}
        self._reset_state()

    def _reset_state(self) -> None:
        """Reset validation state for a new validation run."""
        self._missing_merchant = False
        self._missing_transaction_datetime = False
        self._missing_item_quantities: set[int] = set()

    def validate(
        self, original_data: Dict[Any, Any], result: Dict[Any, Any]
    ) -> Tuple[bool, Dict[Any, Any]]:
        """Validate OCR result against original data.

        Args:
            original_data: The original OCR data to validate against.
            result: The result data to validate.

        Returns:
            A tuple of (is_valid, normalized_result) where normalized_result
            is a deep copy of result with defaults applied for missing fields.
            The original result dict is never modified.
        """
        self._reset_state()
        self.console.print("\n[bold]Validation Results:[/]")

        # Create a deep copy to avoid mutating the input
        normalized_result = copy.deepcopy(result)

        self._missing_merchant = (
            normalized_result.get("merchant") is None or "merchant" not in normalized_result
        )
        self._missing_transaction_datetime = (
            "transaction_datetime" not in normalized_result
            or normalized_result.get("transaction_datetime") in (None, "")
        )
        self._missing_item_quantities = {
            idx
            for idx, item in enumerate(normalized_result.get("items", []))
            if "quantity" not in item or item.get("quantity") is None
        }

        self._apply_defaults(normalized_result)

        if not self._validate_structure(original_data, normalized_result):
            return False, normalized_result

        if not self._validate_merchant_data(original_data, normalized_result):
            return False, normalized_result

        if not self._validate_transaction_data(original_data, normalized_result):
            return False, normalized_result

        if not self._validate_items(original_data, normalized_result):
            return False, normalized_result

        self.console.print("\n[green]✓ All validation checks passed[/]")
        return True, normalized_result

    def _validate_structure(self, original_data: Dict[Any, Any], result: Dict[Any, Any]) -> bool:
        for key in original_data.keys():
            if key == "similar_items":
                continue
            if key in self.optional_keys and key not in result:
                continue
            if key not in result:
                self.console.print(f"[red]❌ Missing key '{key}' in result[/]")
                return False
        return True

    def _validate_merchant_data(self, original_data: Dict[Any, Any], result: Dict[Any, Any]) -> bool:
        orig_merchant = original_data.get('merchant', {})
        result_merchant = result.get('merchant')

        if result_merchant is None or self._missing_merchant:
            self.console.print("[yellow]⚠ Missing merchant in result; using defaults[/]")
            return True

        result_name = result_merchant.get('name')
        result_address = result_merchant.get('address')

        if not result_name and not result_address:
            self.console.print("[yellow]⚠ Partial merchant data in result; using defaults for missing fields[/]")
            return True
        
        if result_name and not self.text_processor.compare_text_ignore_polish(orig_merchant.get('name', ''), result_name):
            self.console.print("[red]❌ Merchant name mismatch[/]")
            self.console.print(f"Expected: {orig_merchant.get('name')}")
            self.console.print(f"Got: {result_name}")
            return False

        if result_address and not self.text_processor.compare_text_ignore_polish(orig_merchant.get('address', ''), result_address):
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

        if self._missing_transaction_datetime:
            self.console.print("[yellow]⚠ Missing transaction_datetime in result; using default[/]")
            return True

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
                
        result_quantity = result_item.get('quantity')
        if idx in self._missing_item_quantities:
            self.console.print(f"[yellow]⚠ Missing quantity for item {idx + 1}; using default[/]")
        elif orig_item.get('quantity') is not None and orig_item.get('quantity') != result_quantity:
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

    def _apply_defaults(self, result: Dict[Any, Any]) -> None:
        """Apply default values for missing optional fields.

        This method modifies the provided dictionary (which should be a copy).
        Empty strings are used for missing merchant fields so downstream models
        accept missing merchant data.
        """
        if result.get("merchant") is None:
            result["merchant"] = {"name": "", "address": ""}
        else:
            merchant = result["merchant"]
            if merchant.get("name") is None:
                merchant["name"] = ""
            if merchant.get("address") is None:
                merchant["address"] = ""

        if "transaction_datetime" not in result or result.get("transaction_datetime") in ("", None):
            result["transaction_datetime"] = None

        for item in result.get("items", []):
            if item.get("quantity") is None:
                item["quantity"] = DEFAULT_QUANTITY
