#!/bin/bash

# Exit on error
set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Running tests..."
echo "---------------"

# Run pytest with Python path set to current directory
if PYTHONPATH="$SCRIPT_DIR" pytest tests/; then
    echo -e "\n${GREEN}Tests completed successfully!${NC}"
    exit 0
else
    echo -e "\n${RED}Tests failed!${NC}"
    exit 1
fi