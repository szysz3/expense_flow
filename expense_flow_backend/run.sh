#!/bin/bash

usage() {
    echo -e "\033[33mUsage: $0 [command] [options]\033[0m"
    echo -e "\033[33mCommands:\033[0m"
    echo -e "  analyze path/to/receipt.{jpg,png,pdf} [--llm-type local|chatgpt]"
    echo -e "  serve [--host HOST] [--port PORT]"
    exit 1
}

check_venv() {
    # Skip venv check if running in Docker
    if [ -f "/.dockerenv" ]; then
        return 0
    }

    VENV_PATH="$HOME/ai_venv"
    if [ ! -d "$VENV_PATH" ]; then
        echo -e "\033[31mError: Virtual environment not found in $VENV_PATH\033[0m"
        echo -e "\033[33mFirst create environment using:\033[0m"
        echo -e "\033[36mpython3 -m venv ~/ai_venv\033[0m"
        echo -e "\033[36msource ~/ai_venv/bin/activate\033[0m"
        echo -e "\033[36mpip install azure-ai-documentintelligence azure-core rich ollama openai fastapi uvicorn python-multipart\033[0m"
        exit 1
    fi
}

check_azure_credentials() {
    if [ -z "$AZURE_DOCUMENT_ENDPOINT" ] || [ -z "$AZURE_DOCUMENT_KEY" ]; then
        echo -e "\033[31mError: Azure credentials not found in environment!\033[0m"
        echo -e "\033[33mPlease set environment variables:\033[0m"
        echo -e "\033[36mexport AZURE_DOCUMENT_ENDPOINT='your_endpoint'\033[0m"
        echo -e "\033[36mexport AZURE_DOCUMENT_KEY='your_key'\033[0m"
        exit 1
    fi
}

check_chatgpt_key() {
    if [ "$LLM_TYPE" = "chatgpt" ] && [ -z "$CHATGPT_KEY" ]; then
        echo -e "\033[31mError: ChatGPT API key not found in environment!\033[0m"
        echo -e "\033[33mPlease set environment variable:\033[0m"
        echo -e "\033[36mexport CHATGPT_KEY='your_key'\033[0m"
        exit 1
    fi
}

check_file() {
    if [ ! -f "$1" ]; then
        echo -e "\033[31mError: File $1 does not exist!\033[0m"
        exit 1
    fi

    if [[ ! $1 =~ \.(jpg|jpeg|png|pdf)$ ]]; then
        echo -e "\033[31mError: File must be an image (jpg, png) or PDF!\033[0m"
        exit 1
    fi
}

activate_venv() {
    # Skip venv activation if running in Docker
    if [ -f "/.dockerenv" ]; then
        return 0
    }

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
    }

    echo -e "\033[32mDeactivating virtual environment...\033[0m"
    deactivate
}

analyze_receipt() {
    RECEIPT_PATH="$1"
    LLM_TYPE="$2"

    check_file "$RECEIPT_PATH"
    check_azure_credentials
    check_chatgpt_key
    
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

    # Parse serve command options
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

    check_azure_credentials
    
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

check_venv
activate_venv

# Parse command
COMMAND="$1"
shift

case "$COMMAND" in
    analyze)
        RECEIPT_PATH="$1"
        LLM_TYPE="local"
        shift

        # Parse analyze command options
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