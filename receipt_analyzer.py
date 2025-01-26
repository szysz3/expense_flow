#!/usr/bin/env python3
import json
import sys
import os
from ollama import Client
from typing import Dict, Any
from datetime import datetime
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.syntax import Syntax
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.core.credentials import AzureKeyCredential

console = Console()

def analyze_receipt_image(image_path: str, endpoint: str, key: str) -> Dict[Any, Any]:
    try:
        with console.status("[bold green]Analyzing receipt image..."):
            client = DocumentIntelligenceClient(endpoint=endpoint, credential=AzureKeyCredential(key))
            
            with open(image_path, "rb") as image:
                poller = client.begin_analyze_document("prebuilt-receipt", image)
            result = poller.result()
            
            if not result.documents:
                raise ValueError("No receipt data found in the image")

            doc = result.documents[0]
            receipt_dict = {
                'analyzeResult': {
                    'documents': [{
                        'fields': {
                            'MerchantName': {'content': doc.fields.get('MerchantName', {}).value_string if doc.fields.get('MerchantName') else ''},
                            'MerchantAddress': {'content': doc.fields.get('MerchantAddress', {}).value_string if doc.fields.get('MerchantAddress') else ''},
                            'TransactionDate': {'valueDate': doc.fields.get('TransactionDate', {}).value_date if doc.fields.get('TransactionDate') else ''},
                            'TransactionTime': {'valueTime': doc.fields.get('TransactionTime', {}).value_time if doc.fields.get('TransactionTime') else ''},
                            'Items': {'valueArray': [
                                {'valueObject': {
                                    'Description': {'content': item.value_object.get('Description', {}).value_string if item.value_object.get('Description') else ''},
                                    'Quantity': {'valueNumber': item.value_object.get('Quantity', {}).value_number if item.value_object.get('Quantity') else 0},
                                    'TotalPrice': {'valueCurrency': {'amount': item.value_object.get('TotalPrice', {}).value_currency.amount if item.value_object.get('TotalPrice') else 0}}
                                }} for item in doc.fields.get('Items', {}).value_array
                            ]},
                            'Total': {'valueCurrency': {'amount': doc.fields.get('Total', {}).value_currency.amount if doc.fields.get('Total') else 0}}
                        }
                    }]
                }
            }
            return receipt_dict
    except Exception as e:
        console.print(f"[bold red]Error analyzing receipt: {e}[/]")
        sys.exit(1)

def preprocess_receipt(raw_data: Dict[Any, Any]) -> Dict[Any, Any]:
    result = raw_data['analyzeResult']
    docs = result.get('documents', [])
    if not docs:
        return {}
    
    doc = docs[0]
    fields = doc.get('fields', {})
    
    date = fields.get('TransactionDate', {}).get('valueDate', '')
    time = fields.get('TransactionTime', {}).get('valueTime', '')
    transaction_datetime = f"{date} {time}" if date and time else ""
    
    return {
        "merchant": {
            "name": fields.get('MerchantName', {}).get('content', ''),
            "address": fields.get('MerchantAddress', {}).get('content', '')
        },
        "items": [
            {
                "description": item['valueObject'].get('Description', {}).get('content', ''),
                "quantity": item['valueObject'].get('Quantity', {}).get('valueNumber', 0),
                "total_price": item['valueObject'].get('TotalPrice', {}).get('valueCurrency', {}).get('amount', 0)
            }
            for item in fields.get('Items', {}).get('valueArray', [])
        ],
        "total": fields.get('Total', {}).get('valueCurrency', {}).get('amount', 0),
        "transaction_datetime": transaction_datetime
    }

def analyze_with_llm(receipt_data: Dict[Any, Any]) -> Dict[Any, Any]:
    client = Client(host='http://localhost:11434')
    prompt = """
    Task: Enhance receipt JSON with item categories
    
    Input: JSON with merchant and receipt items
    Output: Same structure with added "category" field for each item.
    
    Categories:
    - groceries (examples: food, non-alcoholic drinks, ingredients, species, meat, fish, chicken, turkey, pork and similar)
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
    4. Add category field to each item in items array.
    
    IMPORTANT! Please output ONLY extended JSON no other text. ONLY JSON ALLOWED. ANY OTHER TEXT PROHIBITED!
    
    IMPORTANT! Double check if there are no null values or placeholders in output JSON and repeat if needed 
    """   
    
    try:
        console.print("\n[bold]Processing Receipt Data[/]")
        console.print(Panel(
            Syntax(json.dumps(receipt_data, indent=2), "json", theme="monokai"),
            title="Input Data",
            border_style="blue"
        ))

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task("[cyan]Analyzing with LLM...", total=None)
            response = client.generate(
                model='deepseek-r1:8b',
                prompt=f"{prompt}\n\nInput:\n{json.dumps(receipt_data, indent=2)}"
            )
            progress.update(task, completed=True)

        try:
            result = json.loads(response['response'])
            console.print("[bold green]✓[/] Analysis completed successfully")
            return result
        except json.JSONDecodeError:
            console.print("[yellow]Direct parsing failed, attempting to extract JSON...[/]")
            start = response['response'].find('{')
            end = response['response'].rfind('}') + 1
            if start >= 0 and end > start:
                json_str = response['response'][start:end]
                result = json.loads(json_str)
                console.print("[bold green]✓[/] JSON extracted successfully")
                return result
            raise ValueError("No valid JSON found in response")
            
    except Exception as e:
        console.print(f"[bold red]Error with Ollama: {e}[/]")
        console.print("[red]Make sure Ollama is running and the model is installed[/]")
        sys.exit(1)

def save_result(analysis_result: Dict[Any, Any], original_filename: str):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"result_{timestamp}.json"
    try:
        with console.status("[bold green]Saving results..."):
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(analysis_result, f, indent=2, ensure_ascii=False)
            console.print(f"[bold green]✓[/] Results saved to [blue]{filename}[/]")
    except Exception as e:
        console.print(f"[bold red]Error saving results: {e}[/]")
        sys.exit(1)

def main():
    if len(sys.argv) != 2:
        console.print("[bold red]Usage: python receipt_analyzer.py <receipt_image_file>[/]")
        sys.exit(1)
        
    endpoint = os.getenv("AZURE_DOCUMENT_ENDPOINT")
    key = os.getenv("AZURE_DOCUMENT_KEY")
    
    if not endpoint or not key:
        console.print("[bold red]Error: Azure credentials not found in environment variables[/]")
        console.print("Please set AZURE_DOCUMENT_ENDPOINT and AZURE_DOCUMENT_KEY")
        sys.exit(1)
    
    image_path = sys.argv[1]
    raw_data = analyze_receipt_image(image_path, endpoint, key)
    receipt_data = preprocess_receipt(raw_data)
    
    try:
        analysis_result = analyze_with_llm(receipt_data)
        save_result(analysis_result, image_path)
    except Exception as e:
        console.print(f"[bold red]Error during analysis: {e}[/]")
        sys.exit(1)

if __name__ == "__main__":
    main()