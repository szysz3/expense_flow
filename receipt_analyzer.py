#!/usr/bin/env python3
import json
import sys
import os
from dataclasses import dataclass
from typing import List, Dict, Any
from datetime import datetime
from ollama import Client
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.syntax import Syntax
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.core.credentials import AzureKeyCredential
from rich.progress import Progress, SpinnerColumn, TextColumn, TimeElapsedColumn

@dataclass
class Config:
    endpoint: str
    key: str
    model: str = 'llama3.1'
    # model: str = 'deepseek-r1:8b'
    ollama_host: str = 'http://localhost:11434'

class ReceiptAnalyzer:
    def __init__(self, config: Config):
        self.config = config
        self.console = Console()
        self.azure_client = DocumentIntelligenceClient(
            endpoint=config.endpoint,
            credential=AzureKeyCredential(config.key)
        )
        self.ollama_client = Client(host=config.ollama_host)

    def analyze_image(self, image_path: str) -> Dict[Any, Any]:
        with self.console.status("[bold green]Analyzing receipt image..."):
            with open(image_path, "rb") as image:
                poller = self.azure_client.begin_analyze_document("prebuilt-receipt", image)
            result = poller.result()
            
            if not result.documents:
                raise ValueError("No receipt data found in the image")

            return self._extract_receipt_data(result.documents[0])

    def _extract_receipt_data(self, doc) -> Dict[Any, Any]:
        return {
            'analyzeResult': {
                'documents': [{
                    'fields': {
                        'MerchantName': {'content': doc.fields.get('MerchantName', {}).value_string if doc.fields.get('MerchantName') else ''},
                        'MerchantAddress': {'content': doc.fields.get('MerchantAddress', {}).content if doc.fields.get('MerchantAddress') else ''},                        'TransactionDate': {'valueDate': doc.fields.get('TransactionDate', {}).value_date if doc.fields.get('TransactionDate') else ''},
                        'TransactionTime': {'valueTime': doc.fields.get('TransactionTime', {}).value_time if doc.fields.get('TransactionTime') else ''},
                        'Items': {'valueArray': [
                            self._extract_item_data(item) for item in doc.fields.get('Items', {}).value_array
                        ]},
                        'Total': {'valueCurrency': {'amount': doc.fields.get('Total', {}).value_currency.amount if doc.fields.get('Total') else 0}}
                    }
                }]
            }
        }

    def _extract_item_data(self, item) -> Dict[str, Any]:
        return {
            'valueObject': {
                'Description': {'content': item.value_object.get('Description', {}).value_string if item.value_object.get('Description') else ''},
                'Quantity': {'valueNumber': item.value_object.get('Quantity', {}).value_number if item.value_object.get('Quantity') else 0},
                'TotalPrice': {'valueCurrency': {'amount': item.value_object.get('TotalPrice', {}).value_currency.amount if item.value_object.get('TotalPrice') else 0}}
            }
        }

    def preprocess_receipt(self, raw_data: Dict[Any, Any]) -> Dict[Any, Any]:
        docs = raw_data['analyzeResult'].get('documents', [])
        if not docs:
            return {}
        
        fields = docs[0].get('fields', {})
        date = fields.get('TransactionDate', {}).get('valueDate', '')
        time = fields.get('TransactionTime', {}).get('valueTime', '')
        
        json_data = {
            "merchant": {
                "name": fields.get('MerchantName', {}).get('content', ''),
                "address": fields.get('MerchantAddress', {}).get('content', '')
            },
            "items": [
                self._process_item(item) for item in fields.get('Items', {}).get('valueArray', [])
            ],
            "total": fields.get('Total', {}).get('valueCurrency', {}).get('amount', 0),
            "transaction_datetime": f"{date} {time}" if date and time else ""
        }
        
        return json.loads(json.dumps(json_data, ensure_ascii=True))


    def _process_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "description": item['valueObject'].get('Description', {}).get('content', ''),
            "quantity": item['valueObject'].get('Quantity', {}).get('valueNumber', 0),
            "total_price": item['valueObject'].get('TotalPrice', {}).get('valueCurrency', {}).get('amount', 0)
        }

    def _is_polish_char(self, char: str) -> bool:
        polish_chars = {'Ż', 'Ź', 'Ą', 'Ę', 'Ś', 'Ć', 'Ń', 'Ó', 'Ł'}
        return char.upper() in polish_chars

    def _compare_text_ignore_polish(self, original: str, result: str) -> bool:
        if len(original) != len(result):
            return False
            
        for orig_char, result_char in zip(original.upper(), result.upper()):
            if not self._is_polish_char(orig_char) and orig_char != result_char:
                return False
        return True

    def _validate_analysis_result(self, original_data: Dict[Any, Any], result: Dict[Any, Any]) -> bool:
        self.console.print("\n[bold]Validation Results:[/]")
        
        # Check basic structure
        for key in original_data.keys():
            if key not in result:
                self.console.print(f"[red]❌ Missing key '{key}' in result[/]")
                return False
                
        # Validate merchant data
        orig_merchant = original_data.get('merchant', {})
        result_merchant = result.get('merchant', {})
        
        if not (self._compare_text_ignore_polish(orig_merchant.get('name', ''), result_merchant.get('name', '')) and 
                self._compare_text_ignore_polish(orig_merchant.get('address', ''), result_merchant.get('address', ''))):
            self.console.print("[red]❌ Merchant data mismatch[/]")
            self.console.print(f"Expected: {original_data.get('merchant')}")
            self.console.print(f"Got: {result.get('merchant')}")
            return False
                
        # Validate total and transaction_datetime
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
                
        # Validate items
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
            
            # Compare descriptions
            if not self._compare_text_ignore_polish(orig_item.get('description', ''), result_item.get('description', '')):
                self.console.print(f"[red]❌ Description mismatch for item {idx + 1}[/]")
                self.console.print(f"Expected: {orig_item.get('description')}")
                self.console.print(f"Got: {result_item.get('description')}")
                return False
                
            # Check quantity
            if orig_item.get('quantity') != result_item.get('quantity'):
                self.console.print(f"[red]❌ Quantity mismatch for item {idx + 1}[/]")
                self.console.print(f"Expected: {orig_item.get('quantity')}")
                self.console.print(f"Got: {result_item.get('quantity')}")
                return False
                
            # Check price
            if orig_item.get('total_price') != result_item.get('total_price'):
                self.console.print(f"[red]❌ Price mismatch for item {idx + 1}[/]")
                self.console.print(f"Expected: {orig_item.get('total_price')}")
                self.console.print(f"Got: {result_item.get('total_price')}")
                return False
                    
            # Verify category
            if 'category' not in result_item:
                self.console.print(f"[red]❌ Missing category for item {idx + 1}[/]")
                return False
                
            if result_item['category'] not in valid_categories:
                self.console.print(f"[red]❌ Invalid category '{result_item['category']}' for item {idx + 1}[/]")
                self.console.print(f"Valid categories are: {valid_categories}")
                return False
                
            self.console.print(f"[green]✓ Item {idx + 1} validated successfully[/]")
                    
        self.console.print("\n[green]✓ All validation checks passed[/]")
        return True

    def analyze_with_llm(self, receipt_data: Dict[Any, Any]) -> Dict[Any, Any]:
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
                    task = progress.add_task(f"[cyan]Analyzing with LLM (Attempt {attempt + 1}/{max_retries})...")
                    response = self.ollama_client.generate(
                        model=self.config.model,
                        prompt=f"{prompt}\n\nInput:\n{json.dumps(receipt_data, indent=2)}"
                    )
                
                duration = (datetime.now() - start_time).total_seconds()
                total_elapsed = (datetime.now() - total_start_time).total_seconds()

                try:
                    result = self._parse_llm_response(response['response'])
                except (ValueError, json.JSONDecodeError):
                    raise ValueError("Invalid JSON response")

                if self._validate_analysis_result(receipt_data, result):
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
        
        Example:
        {
        "merchant": {
        "name": "[STORE_NAME]",
        "address": "[ADDRESS]"
        },
        "items": [
        {
            "description": "[ITEM_DESCRIPTION]",
            "quantity": "[QUANTITY]",
            "total_price": "[PRICE]",
            "category": "[CATEGORY]"
        }
        ],
        "total": "[TOTAL]",
        "transaction_datetime": "[DATE_TIME]"
        }
        
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

    def save_result(self, analysis_result: Dict[Any, Any]):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"result_{timestamp}.json"
        
        with self.console.status("[bold green]Saving results..."):
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(analysis_result, f, indent=2, ensure_ascii=False)
            self.console.print(f"[bold green]✓[/] Results saved to [blue]{filename}[/]")

def main():
    if len(sys.argv) != 2:
        Console().print("[bold red]Usage: python receipt_analyzer.py <receipt_image_file>[/]")
        sys.exit(1)

    config = Config(
        endpoint=os.getenv("AZURE_DOCUMENT_ENDPOINT"),
        key=os.getenv("AZURE_DOCUMENT_KEY")
    )

    if not config.endpoint or not config.key:
        Console().print("[bold red]Error: Azure credentials not found in environment variables[/]")
        Console().print("Please set AZURE_DOCUMENT_ENDPOINT and AZURE_DOCUMENT_KEY")
        sys.exit(1)

    analyzer = ReceiptAnalyzer(config)
    
    try:
        image_path = sys.argv[1]
        raw_data = analyzer.analyze_image(image_path)
        receipt_data = analyzer.preprocess_receipt(raw_data)
        analysis_result = analyzer.analyze_with_llm(receipt_data)
        analyzer.save_result(analysis_result)
    except Exception as e:
        Console().print(f"[bold red]Error: {e}[/]")
        sys.exit(1)

if __name__ == "__main__":
    main()