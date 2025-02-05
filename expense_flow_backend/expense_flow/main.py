import sys
import os
from datetime import datetime 
import json
from rich.console import Console
from expense_flow.config import Config
from expense_flow.document_processor.azure_processor import AzureDocumentProcessor
from expense_flow.document_processor.image_processor import ImagePreprocessor
from expense_flow.analyzers.local_llm import LocalLLMAnalyzer
from expense_flow.analyzers.chatgpt_llm import ChatGPTAnalyzer

def save_result(input_file: str, analysis_result: dict, console: Console):
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

def main():
    if len(sys.argv) < 2:
        Console().print("[bold red]Usage: python receipt_analyzer.py <receipt_file> [--llm-type local|chatgpt][/]")
        sys.exit(1)
        
    llm_type = 'local'
    if len(sys.argv) > 2 and sys.argv[2] == '--llm-type':
        if len(sys.argv) > 3 and sys.argv[3] in ['local', 'chatgpt']:
            llm_type = sys.argv[3]
        else:
            Console().print("[bold red]Invalid LLM type. Use 'local' or 'chatgpt'[/]")
            sys.exit(1)

    config = Config(
        endpoint=os.getenv("AZURE_DOCUMENT_ENDPOINT"),
        key=os.getenv("AZURE_DOCUMENT_KEY"),
        chatgpt_key=os.getenv("CHATGPT_KEY"),
        llm_type=llm_type
    )

    console = Console()
    
    input_file = sys.argv[1]
    is_json = input_file.lower().endswith('.json')

    # Only check Azure credentials if processing image files
    if not is_json:
        if not config.endpoint or not config.key:
            console.print("[bold red]Error: Azure credentials not found in environment variables[/]")
            console.print("Please set AZURE_DOCUMENT_ENDPOINT and AZURE_DOCUMENT_KEY")
            sys.exit(1)

    if llm_type == 'chatgpt' and not config.chatgpt_key:
        console.print("[bold red]Error: ChatGPT API key not found in environment variables[/]")
        console.print("Please set CHATGPT_KEY")
        sys.exit(1)

    try:
        if is_json:
            receipt_data = load_json_data(input_file, console)
        else:
            # Image preprocessing (scaling etc.)
            image_preprocessor = ImagePreprocessor()
            processed_path, success = image_preprocessor.process(input_file)

            # OCR
            doc_processor = AzureDocumentProcessor(config)
            raw_data = doc_processor.process_image(processed_path if success else input_file)
            receipt_data = doc_processor.preprocess_receipt(raw_data)
                
        # Analyze with selected LLM
        analyzer = LocalLLMAnalyzer(config) if llm_type == 'local' else ChatGPTAnalyzer(config)
        analysis_result = analyzer.analyze(receipt_data)
        
        # Save results
        save_result(input_file, analysis_result, console)

    except Exception as e:
        console.print(f"[bold red]Error: {e}[/]")
        sys.exit(1)

if __name__ == "__main__":
    main()