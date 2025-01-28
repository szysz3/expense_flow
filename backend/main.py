import sys
import os
from datetime import datetime 
import json
from rich.console import Console
from config import Config
from document_processor.azure_processor import AzureDocumentProcessor
from document_processor.image_processor import ImagePreprocessor
from analyzers.local_llm import LocalLLMAnalyzer
from analyzers.chatgpt_llm import ChatGPTAnalyzer

def save_result(analysis_result: dict, console: Console):
    results_dir = "results"
    os.makedirs(results_dir, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = os.path.join(results_dir, f"result_{timestamp}.json")
    
    with console.status("[bold green]Saving results..."):
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(analysis_result, f, indent=2, ensure_ascii=False)
        console.print(f"[bold green]✓[/] Results saved to [blue]{filename}[/]")

def main():
    if len(sys.argv) < 2:
        Console().print("[bold red]Usage: python receipt_analyzer.py <receipt_image_file> [--llm-type local|chatgpt][/]")
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
    
    if not config.endpoint or not config.key:
        console.print("[bold red]Error: Azure credentials not found in environment variables[/]")
        console.print("Please set AZURE_DOCUMENT_ENDPOINT and AZURE_DOCUMENT_KEY")
        sys.exit(1)

    if llm_type == 'chatgpt' and not config.chatgpt_key:
        console.print("[bold red]Error: ChatGPT API key not found in environment variables[/]")
        console.print("Please set CHATGPT_KEY")
        sys.exit(1)

    try:
        image_path = sys.argv[1]
        
        # Prepare image
        image_preprocessor = ImagePreprocessor()
        processed_path, success = image_preprocessor.process(image_path)

        # Run OCR
        doc_processor = AzureDocumentProcessor(config)
        raw_data = doc_processor.process_image(processed_path if success else image_path)
        receipt_data = doc_processor.preprocess_receipt(raw_data)
        
        # Analyze with selected LLM
        analyzer = LocalLLMAnalyzer(config) if llm_type == 'local' else ChatGPTAnalyzer(config)
        analysis_result = analyzer.analyze(receipt_data)
        
        # Save results
        save_result(analysis_result, console)

    except Exception as e:
        console.print(f"[bold red]Error: {e}[/]")
        sys.exit(1)

if __name__ == "__main__":
    main()