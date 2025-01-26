#!/usr/bin/env python3
import json
import sys
from ollama import Client
from typing import Dict, Any
from datetime import datetime
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.syntax import Syntax

console = Console()

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

def load_receipt_data(file_path: str) -> Dict[Any, Any]:
    try:
        with console.status("[bold green]Loading receipt data..."):
            with open(file_path, 'r', encoding='utf-8') as f:
                raw_data = json.load(f)
                processed_data = preprocess_receipt(raw_data)
                console.print("[bold green]✓[/] Receipt data loaded successfully")
                return processed_data
    except Exception as e:
        console.print(f"[bold red]Error loading receipt data: {e}[/]")
        sys.exit(1)

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
        console.print("[bold red]Usage: python receipt_analyzer.py <receipt_json_file>[/]")
        sys.exit(1)
    
    receipt_data = load_receipt_data(sys.argv[1])
    try:
        analysis_result = analyze_with_llm(receipt_data)
        save_result(analysis_result, sys.argv[1])
    except Exception as e:
        console.print(f"[bold red]Error during analysis: {e}[/]")
        sys.exit(1)

if __name__ == "__main__":
    main()