#!/bin/bash
cd ../../
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Setting up Docker environment for ExpenseFlow...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from .env.example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Please edit the .env file with your actual credentials and set LLM_OLLAMA_HOST to your Ollama instance.${NC}"
fi

echo -e "${GREEN}Creating necessary directories...${NC}"
mkdir -p .data/serve .data/analyzis
mkdir -p .data-demo/serve .data-demo/analyzis

echo -e "${GREEN}Building Docker images...${NC}"
docker-compose build

echo -e "${YELLOW}NOTE: Please ensure your external Ollama server is running and accessible.${NC}"
echo -e "${YELLOW}Make sure to update LLM_OLLAMA_HOST in your .env file with the correct URL.${NC}"
echo -e "${GREEN}Setup complete! You can now run:${NC}"
echo -e "${YELLOW}  Production:  docker-compose up -d api-production${NC}"
echo -e "${YELLOW}  Demo:       docker-compose up -d api-demo${NC}"
echo -e "${YELLOW}  Both:       docker-compose up -d${NC}"
echo -e "${GREEN}Production will run on port 8000, Demo on port 8001${NC}"