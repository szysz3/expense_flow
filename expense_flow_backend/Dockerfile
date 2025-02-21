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

# Copy the rest of the project files
COPY . /app/
RUN chmod +x /app/run.sh

# Expose API port
EXPOSE 8000

# Set the entrypoint
ENTRYPOINT ["/app/docker_entrypoint.sh"]

# Default command
CMD ["python", "-m", "expense_flow.api.main"]