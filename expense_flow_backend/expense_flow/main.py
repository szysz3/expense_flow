import sys
import os
from datetime import datetime 
import json
from rich.console import Console
from expense_flow.config import get_config
from expense_flow.document_processor.azure_processor import AzureDocumentProcessor
from expense_flow.document_processor.image_processor import ImagePreprocessor
from expense_flow.analyzers.local_llm_analyzer import LocalLLMAnalyzer
from expense_flow.analyzers.chatgpt_analyzer import ChatGPTAnalyzer

def save_result(input_file: str, analysis_result: dict, console: Console):
    """
    Save analysis result to JSON file
    
    Args:
        input_file: Path to input file
        analysis_result: Analysis result dictionary
        console: Rich console instance
    """
    results_dir = ".data/analyzis"
    output_filename = os.path.basename(input_file)
    output_filename = os.path.splitext(output_filename)[0]

    os.makedirs(results_dir, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = os.path.join(results_dir, f"result_{output_filename}.json")
    
    with console.status("[bold green]Saving results..."):
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(analysis_result, f, indent=2, ensure_ascii=False)
        console.print(f"[bold green]✓[/] Results saved to [blue]{filename}[/]")

def load_json_data(filepath: str, console: Console) -> dict:
    """
    Load JSON data from file
    
    Args:
        filepath: Path to JSON file
        console: Rich console instance
        
    Returns:
        Loaded JSON data as dictionary
    """
    with console.status(f"[bold blue]Loading JSON from {filepath}..."):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
            console.print("[bold green]✓[/] JSON data loaded successfully")
            return data
        except json.JSONDecodeError as e:
            console.print(f"[bold red]Error: Invalid JSON file: {e}[/]")
            sys.exit(1)
        except Exception as e:
            console.print(f"[bold red]Error loading file: {e}[/]")
            sys.exit(1)

def analyze_with_fallback_chain(config, receipt_data: dict, console: Console) -> dict:
    """
    Attempt analysis with local LLM, fallback LLM, and finally ChatGPT
    
    Args:
        config: Application configuration
        receipt_data: Receipt data dictionary
        console: Rich console instance
        
    Returns:
        Analysis result dictionary
    """
    try:
        local_analyzer = LocalLLMAnalyzer(config)
        return local_analyzer.analyze(receipt_data)
    except Exception as e:
        console.print(f"[yellow]Primary local LLM failed: {str(e)}[/]")
        
        console.print("[yellow]Both local LLMs failed. Falling back to ChatGPT...[/]")
        
        if not config.chatgpt_key:
            console.print("[bold red]Error: ChatGPT API key not found in configuration[/]")
            console.print("Please set LLM_CHATGPT_KEY in your .env file for fallback functionality")
            raise
        
        try:
            chatgpt_analyzer = ChatGPTAnalyzer(config)
            return chatgpt_analyzer.analyze(receipt_data)
        except Exception as chatgpt_error:
            console.print("[bold red]ChatGPT analysis also failed[/]")
            raise Exception(f"All analysis attempts failed. Last error: {str(chatgpt_error)}")

def main():
    if len(sys.argv) < 2:
        Console().print("[bold red]Usage: python receipt_analyzer.py <receipt_file>[/]")
        sys.exit(1)
    
    # Load configuration
    config = get_config()
    console = Console()
    
    input_file = sys.argv[1]
    is_json = input_file.lower().endswith('.json')

    if not is_json:
        if not config.azure_endpoint or not config.azure_key:
            console.print("[bold red]Error: Azure credentials not found in configuration[/]")
            console.print("Please set AZURE_ENDPOINT and AZURE_KEY in your .env file")
            sys.exit(1)

    try:
        if is_json:
            receipt_data = load_json_data(input_file, console)
        else:
            image_preprocessor = ImagePreprocessor()
            processed_path, success = image_preprocessor.process(input_file)

            doc_processor = AzureDocumentProcessor(config)
            raw_data = doc_processor.process_image(processed_path if success else input_file)
            receipt_data = doc_processor.preprocess_receipt(raw_data)
                
        analysis_result = analyze_with_fallback_chain(config, receipt_data, console)
        
        save_result(input_file, analysis_result, console)

    except Exception as e:
        console.print(f"[bold red]Error: {e}[/]")
        sys.exit(1)

if __name__ == "__main__":
    main()