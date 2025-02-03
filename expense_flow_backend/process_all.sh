#!/bin/bash

LLM_TYPE="local" 
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
RUN_SCRIPT="$SCRIPT_DIR/run.sh"

usage() {
    echo -e "\033[33mUsage: $0 <path_to_json_directory> [--llm-type local|chatgpt]\033[0m"
    echo -e "Example: $0 /path/to/jsons --llm-type local"
    exit 1
}

# Check command line arguments
if [ $# -lt 1 ]; then
    usage
fi

JSON_DIR="$1"
shift

# Parse optional arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --llm-type)
            if [ "$2" = "local" ] || [ "$2" = "chatgpt" ]; then
                LLM_TYPE="$2"
                shift 2
            else
                echo -e "\033[31mError: Invalid LLM type. Use 'local' or 'chatgpt'\033[0m"
                exit 1
            fi
            ;;
        *)
            usage
            ;;
    esac
done

if [ ! -x "$RUN_SCRIPT" ]; then
    echo -e "\033[31mError: run.sh not found or not executable at $RUN_SCRIPT\033[0m"
    exit 1
fi

if [ ! -d "$JSON_DIR" ]; then
    echo -e "\033[31mError: JSON directory not found at $JSON_DIR\033[0m"
    exit 1
fi

find "$JSON_DIR" -maxdepth 1 -type f -name "*.json" | while read -r json_file; do
    echo -e "\033[32m====================================\033[0m"
    echo -e "\033[32mProcessing: $(basename "$json_file")\033[0m"
    echo -e "\033[32m====================================\033[0m"
    
    "$RUN_SCRIPT" analyze "$json_file" --llm-type "$LLM_TYPE"
    
    if [ $? -ne 0 ]; then
        echo -e "\033[31mError processing $(basename "$json_file")\033[0m"
    fi
    
    echo
done

echo -e "\033[32mAll files processed\033[0m"