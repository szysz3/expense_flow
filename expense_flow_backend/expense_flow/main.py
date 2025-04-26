import sys
import os
import asyncio
from datetime import datetime 
import json
import uuid
from rich.console import Console
from expense_flow.config import get_config
from expense_flow.document_processor.azure_processor import AzureDocumentProcessor
from expense_flow.document_processor.image_processor import ImagePreprocessor
from expense_flow.analyzers.local_llm_analyzer import LocalLLMAnalyzer
from expense_flow.analyzers.chatgpt_analyzer import ChatGPTAnalyzer
from expense_flow.services.vector_store_service import VectorStoreService
from expense_flow.api.models import Receipt, Category

def update_vector_db(analysis_result: dict, console: Console, input_file: str):
    """
    Update vector database with processed receipt items
    
    Args:
        analysis_result: Analysis result dictionary
        console: Rich console instance
        input_file: Path to input file
    """
    try:
        config = get_config()
        vector_store = VectorStoreService(config)
        
        # Generate a unique ID for this receipt
        receipt_id = str(uuid.uuid4())
        
        # Use filename if available
        if input_file:
            base_name = os.path.basename(input_file)
            filename = os.path.splitext(base_name)[0]
            receipt_id = f"{filename}_{receipt_id}"
        
        console.print("[bold blue]Updating vector database...[/]")
        
        for item in analysis_result.get('items', []):
            item_data = {
                "description": item.get('description', ''),
                "category": item.get('category', 'other'),
                "receipt_id": receipt_id
            }
            vector_store.add_item_embedding(item_data)
        
        console.print(f"[bold green]✓[/] Added {len(analysis_result.get('items', []))} items to vector database")
    except Exception as e:
        console.print(f"[bold yellow]Warning: Failed to update vector database: {str(e)}[/]")

def save_result(input_file: str, analysis_result: dict, console: Console, use_rag: bool = False):
    """
    Save analysis result to JSON file
    
    Args:
        input_file: Path to input file
        analysis_result: Analysis result dictionary
        console: Rich console instance
        use_rag: Whether to update vector database with results
    """
    results_dir = ".data/analyzis"
    output_filename = os.path.basename(input_file)
    output_filename = os.path.splitext(output_filename)[0]

    os.makedirs(results_dir, exist_ok=True)
    
    filename = os.path.join(results_dir, f"result_{output_filename}.json")
    
    with console.status("[bold green]Saving results..."):
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(analysis_result, f, indent=2, ensure_ascii=False)
        console.print(f"[bold green]✓[/] Results saved to [blue]{filename}[/]")
    
    if use_rag:
        update_vector_db(analysis_result, console, input_file)

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

async def analyze_with_fallback_chain(config, receipt_data: dict, console: Console, use_rag: bool = False) -> dict:
    """
    Attempt analysis with local LLM, fallback LLM, and finally ChatGPT
    
    Args:
        config: Application configuration
        receipt_data: Receipt data dictionary
        console: Rich console instance
        use_rag: Whether to use RAG for analysis
        
    Returns:
        Analysis result dictionary
    """
    try:
        local_analyzer = LocalLLMAnalyzer(config)
        
        if use_rag:
            # Use RAG if enabled
            from expense_flow.services.vector_store_service import VectorStoreService
            from expense_flow.services.rag_service import RAGService
            
            vector_store = VectorStoreService(config)
            rag_service = RAGService(vector_store)
            return await local_analyzer.analyze_with_rag(receipt_data, rag_service)
        else:
            return await local_analyzer.analyze(receipt_data)
    except Exception as e:
        console.print(f"[yellow]Primary local LLM failed: {str(e)}[/]")
        
        console.print("[yellow]Both local LLMs failed. Falling back to ChatGPT...[/]")
        
        if not config.chatgpt_key:
            console.print("[bold red]Error: ChatGPT API key not found in configuration[/]")
            console.print("Please set LLM_CHATGPT_KEY in your .env file for fallback functionality")
            raise
        
        try:
            chatgpt_analyzer = ChatGPTAnalyzer(config)
            return await chatgpt_analyzer.analyze(receipt_data)
        except Exception as chatgpt_error:
            console.print("[bold red]ChatGPT analysis also failed[/]")
            raise Exception(f"All analysis attempts failed. Last error: {str(chatgpt_error)}")

async def async_main():
    import argparse
    parser = argparse.ArgumentParser(description='Analyze receipt data')
    parser.add_argument('input_file', help='Path to receipt image or JSON file')
    parser.add_argument('--llm-type', choices=['local', 'chatgpt'], default='local', help='Type of LLM to use')
    parser.add_argument('--use-rag', action='store_true', help='Use RAG feature for analysis')
    args = parser.parse_args()
    
    config = get_config()
    console = Console()
    
    input_file = args.input_file
    is_json = input_file.lower().endswith('.json')
    use_rag = args.use_rag

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
                
        analysis_result = await analyze_with_fallback_chain(config, receipt_data, console, use_rag)
        
        save_result(input_file, analysis_result, console, use_rag)

    except Exception as e:
        console.print(f"[bold red]Error: {e}[/]")
        sys.exit(1)

def main():
    """
    Entry point that runs the async main function
    """
    asyncio.run(async_main())

if __name__ == "__main__":
    main()