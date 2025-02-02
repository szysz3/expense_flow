#!/bin/bash
set -e

echo "Starting Ollama server..."
ollama serve &
OLLAMA_PID=$!

# Function to check if Ollama is running
check_ollama() {
    curl -s http://localhost:11434/api/tags >/dev/null 2>&1
}

# Wait for Ollama with timeout
echo "Waiting for Ollama to start..."
TIMEOUT=60
COUNTER=0
while ! check_ollama; do
    if [ $COUNTER -ge $TIMEOUT ]; then
        echo "Error: Ollama failed to start within $TIMEOUT seconds"
        exit 1
    fi
    sleep 1
    COUNTER=$((COUNTER + 1))
    if [ $((COUNTER % 5)) -eq 0 ]; then
        echo "Still waiting for Ollama... ($COUNTER seconds)"
    fi
done

echo "Ollama is running"

# Pull the model with timeout and progress indication
echo "Pulling model phi4..."
timeout 900 ollama pull phi4 || {
    echo "Error: Model pull failed or timed out after 5 minutes"
    exit 1
}

# Start the FastAPI application
echo "Starting FastAPI application..."
exec "$@"