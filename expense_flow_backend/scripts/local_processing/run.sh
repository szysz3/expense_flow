#!/bin/bash

usage() {
    echo -e "\033[33mUsage: $0 [command] [options]\033[0m"
    echo -e "\033[33mCommands:\033[0m"
    echo -e "  analyze path/to/receipt.{jpg,png,pdf,json} [--llm-type local|chatgpt]"
    echo -e "  serve [--host HOST] [--port PORT]"
    exit 1
}

VENV_PATH="$HOME/ai_venv"

check_file() {
    if [ ! -f "$1" ]; then
        echo -e "\033[31mError: File $1 does not exist!\033[0m"
        exit 1
    fi

    if [[ ! $1 =~ \.(jpg|jpeg|png|pdf|json)$ ]]; then
        echo -e "\033[31mError: File must be an image (jpg, png), PDF, or JSON!\033[0m"
        exit 1
    fi
}

activate_venv() {
    # Skip venv activation if running in Docker
    if [ -f "/.dockerenv" ]; then
        return 0
    fi

    echo -e "\033[32mActivating virtual environment...\033[0m"
    source "$VENV_PATH/bin/activate"
    if [ $? -ne 0 ]; then
        echo -e "\033[31mError: Failed to activate virtual environment!\033[0m"
        exit 1
    fi
}

deactivate_venv() {
    # Skip venv deactivation if running in Docker
    if [ -f "/.dockerenv" ]; then
        return 0
    fi

    echo -e "\033[32mDeactivating virtual environment...\033[0m"
    deactivate
}

analyze_receipt() {
    RECEIPT_PATH="$1"
    LLM_TYPE="$2"

    check_file "$RECEIPT_PATH"
    
    echo -e "\033[32mStarting receipt analysis using $LLM_TYPE LLM...\033[0m"
    python -m expense_flow.main "$RECEIPT_PATH" --llm-type "$LLM_TYPE"
    SCRIPT_STATUS=$?

    if [ $SCRIPT_STATUS -ne 0 ]; then
        echo -e "\033[31mError: Receipt analysis failed!\033[0m"
        exit 1
    fi

    echo -e "\033[32mAnalysis complete\033[0m"
}

serve_api() {
    local HOST="0.0.0.0"
    local PORT="8000"

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --host)
                HOST="$2"
                shift 2
                ;;
            --port)
                PORT="$2"
                shift 2
                ;;
            *)
                usage
                ;;
        esac
    done
    
    echo -e "\033[32mStarting API server on $HOST:$PORT...\033[0m"
    python -m expense_flow.api.main --host "$HOST" --port "$PORT"
    SCRIPT_STATUS=$?

    if [ $SCRIPT_STATUS -ne 0 ]; then
        echo -e "\033[31mError: API server failed!\033[0m"
        exit 1
    fi
}

# Main script execution
if [ $# -eq 0 ]; then
    usage
fi

activate_venv

COMMAND="$1"
shift

cd ../../

case "$COMMAND" in
    analyze)
        RECEIPT_PATH="$1"
        LLM_TYPE="local"
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

        analyze_receipt "$RECEIPT_PATH" "$LLM_TYPE"
        ;;
    serve)
        serve_api "$@"
        ;;
    *)
        usage
        ;;
esac

deactivate_venv