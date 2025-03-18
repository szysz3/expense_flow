#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Docker environment for ExpenseFlow...${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from .env.example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Please edit the .env file with your actual credentials and set LLM_OLLAMA_HOST to your Ollama instance.${NC}"
fi

# Create necessary directories
echo -e "${GREEN}Creating necessary directories...${NC}"
mkdir -p .data/serve .data/analyzis

# Pull or build necessary Docker images
echo -e "${GREEN}Building Docker images...${NC}"
docker-compose build

# Verify Ollama connection
echo -e "${YELLOW}NOTE: Please ensure your external Ollama server is running and accessible.${NC}"
echo -e "${YELLOW}Make sure to update LLM_OLLAMA_HOST in your .env file with the correct URL.${NC}"

echo -e "${GREEN}Setup complete! You can now run:${NC}"
echo -e "${YELLOW}  docker-compose up -d${NC}"
echo -e "${GREEN}to start the API service.${NC}"