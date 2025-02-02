# Use Python 3.11 slim as base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set Python environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama using the official installation script
RUN curl https://ollama.ai/install.sh | sh

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir requests

# Copy project files
COPY . /app/

# Make run.sh executable
RUN chmod +x /app/run.sh

# Create entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Starting Ollama server..."\n\
ollama serve &\n\
OLLAMA_PID=$!\n\
\n\
# Function to check if Ollama is running\n\
check_ollama() {\n\
    curl -s http://localhost:11434/api/tags >/dev/null 2>&1\n\
}\n\
\n\
# Wait for Ollama with timeout\n\
echo "Waiting for Ollama to start..."\n\
TIMEOUT=60\n\
COUNTER=0\n\
while ! check_ollama; do\n\
    if [ $COUNTER -ge $TIMEOUT ]; then\n\
        echo "Error: Ollama failed to start within $TIMEOUT seconds"\n\
        exit 1\n\
    fi\n\
    sleep 1\n\
    COUNTER=$((COUNTER + 1))\n\
    if [ $((COUNTER % 5)) -eq 0 ]; then\n\
        echo "Still waiting for Ollama... ($COUNTER seconds)"\n\
    fi\n\
done\n\
\n\
echo "Ollama is running"\n\
\n\
# Pull the model with timeout and progress indication\n\
echo "Pulling model phi4..."\n\
timeout 300 ollama pull phi4 || {\n\
    echo "Error: Model pull failed or timed out after 5 minutes"\n\
    exit 1\n\
}\n\
\n\
# Start the FastAPI application\n\
echo "Starting FastAPI application..."\n\
exec "$@"' > /app/entrypoint.sh \
    && chmod +x /app/entrypoint.sh

# Expose API port
EXPOSE 8000

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Default command
CMD ["python", "-m", "expense_flow.api.main"]