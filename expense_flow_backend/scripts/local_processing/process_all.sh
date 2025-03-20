#!/bin/bash

LLM_TYPE="local"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
RUN_SCRIPT="$SCRIPT_DIR/run.sh"

usage() {
    echo -e "\033[33mUsage: $0 <path_to_json_directory> [--llm-type local|chatgpt]\033[0m"
    echo -e "Example: $0 /path/to/jsons --llm-type local"
    exit 1
}

format_time() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    if [ $minutes -gt 0 ]; then
        echo "${minutes}m ${remaining_seconds}s"
    else
        echo "${remaining_seconds}s"
    fi
}

if [ $# -lt 1 ]; then
    usage
fi

JSON_DIR="$1"
shift

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

total_files=$(find "$JSON_DIR" -maxdepth 1 -type f -name "*.json" | wc -l)
processed_files=0
failed_files=0
start_time=$(date +%s)

while IFS= read -r json_file; do
    echo -e "\033[32m====================================\033[0m"
    echo -e "\033[32mProcessing: $(basename "$json_file")\033[0m"
    echo -e "\033[32m====================================\033[0m"
    
    file_start_time=$(date +%s)
    
    "$RUN_SCRIPT" analyze "$json_file" --llm-type "$LLM_TYPE"
    exit_code=$?
    
    file_end_time=$(date +%s)
    file_duration=$((file_end_time - file_start_time))
    
    if [ $exit_code -ne 0 ]; then
        echo -e "\033[31mError processing $(basename "$json_file")\033[0m"
        ((failed_files++))
    fi
    
    ((processed_files++))
    echo -e "\033[36mFile processing time: $(format_time $file_duration)\033[0m"
    echo
done < <(find "$JSON_DIR" -maxdepth 1 -type f -name "*.json")

end_time=$(date +%s)
total_duration=$((end_time - start_time))

echo -e "\033[32m====================================\033[0m"
echo -e "\033[32mExecution Summary\033[0m"
echo -e "\033[32m====================================\033[0m"
echo -e "Total files processed: $processed_files/$total_files"
echo -e "Successfully processed: $((processed_files - failed_files))"
echo -e "Failed: $failed_files"
echo -e "Total execution time: $(format_time $total_duration)"
echo -e "\033[32mAll files processed\033[0m"