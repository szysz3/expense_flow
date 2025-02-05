#!/usr/bin/env python3
import json
import argparse
import os
import logging
from colorama import init, Fore, Style

init()

class Stats:
    def __init__(self):
        self.total_matches = 0
        self.total_mismatches = 0
        self.files_processed = 0
        self.files_with_errors = 0

    def print_summary(self):
        total = self.total_matches + self.total_mismatches
        success_rate = (self.total_matches / total * 100) if total > 0 else 0
        
        print(f"\n{Fore.CYAN}═══ Overall Summary ═══{Style.RESET_ALL}")
        print(f"{Fore.GREEN}✓ Matching categories:{Style.RESET_ALL} {self.total_matches}")
        print(f"{Fore.RED}✗ Mismatched categories:{Style.RESET_ALL} {self.total_mismatches}")
        print(f"{Fore.BLUE}◆ Files processed:{Style.RESET_ALL} {self.files_processed}")
        print(f"{Fore.RED}✗ Files with errors:{Style.RESET_ALL} {self.files_with_errors}")
        print(f"{Fore.CYAN}⚡ Success rate:{Style.RESET_ALL} {success_rate:.1f}%\n")

def setup_logging(verbose):
    format_str = '%(asctime)s %(message)s'
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(level=level, format=format_str)

def load_json(path):
    with open(path, 'r') as f:
        return json.load(f)

def compare_categories(source_path, result_path, stats):
    # Load both files
    source_data = load_json(source_path)
    result_data = load_json(result_path)
    
    # Create lookup dictionary for result items
    result_items = {item['description']: item.get('category') 
                   for item in result_data['items']}
    
    # Compare each source item
    for item in source_data['items']:
        desc = item['description']
        source_category = item.get('category')
        result_category = result_items.get(desc)
        
        if desc not in result_items:
            logging.warning(f"Item not found in result file: {desc[:50]}...")
            continue
            
        # Log comparison results
        logging.info(f"Checking: {desc[:70]}...")
        if source_category == result_category:
            stats.total_matches += 1
            logging.info(f"  ✓ Match: {source_category}")
        else:
            stats.total_mismatches += 1
            logging.warning(f"  ✗ Mismatch - Source: {source_category}, Result: {result_category}")

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Compare categories in JSON files')
    parser.add_argument('source_dir', help='Source JSON files directory')
    parser.add_argument('result_dir', help='Result JSON files directory')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    args = parser.parse_args()
    
    # Setup
    setup_logging(args.verbose)
    stats = Stats()
    
    # Validate directories exist
    if not os.path.isdir(args.source_dir) or not os.path.isdir(args.result_dir):
        logging.error("Source or result directory not found")
        return
    
    # Process each JSON file
    for source_file in os.listdir(args.source_dir):
        if not source_file.endswith('.json'):
            continue
            
        result_file = f"result_{source_file}"
        source_path = os.path.join(args.source_dir, source_file)
        result_path = os.path.join(args.result_dir, result_file)
        
        if not os.path.exists(result_path):
            logging.warning(f"No matching result file for: {source_file}")
            continue
            
        try:
            logging.info(f"\nProcessing: {source_file}")
            compare_categories(source_path, result_path, stats)
            stats.files_processed += 1
        except Exception as e:
            logging.error(f"Error processing {source_file}: {str(e)}")
            stats.files_with_errors += 1

    # Print final summary
    stats.print_summary()

if __name__ == '__main__':
    main()