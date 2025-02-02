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
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -L https://ollama.ai/download/ollama-linux-amd64 -o /usr/local/bin/ollama \
    && chmod +x /usr/local/bin/ollama

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
## Start Ollama in the background\n\
#ollama serve &\n\
#\n\
## Wait for Ollama to start\n\
#echo "Waiting for Ollama to start..."\n\
#until curl -s http://localhost:11434/api/tags > /dev/null; do\n\
#    sleep 1\n\
#done\n\
#echo "Ollama is running"\n\
#\n\
## Pull the model\n\
#echo "Pulling model deepseek-r1:8b..."\n\
#ollama pull deepseek-r1:8b\n\
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