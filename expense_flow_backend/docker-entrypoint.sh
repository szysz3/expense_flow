#!/bin/bash
set -e

echo "Starting ExpenseFlow API in ${MODE:-production} mode..."

echo "Initializing production vector database..."
python -m scripts.setup.init_vector_db --db-path .data/serve/receipts.db --vector-db-path .data/vector_db

echo "Initializing demo vector database..."
python -m scripts.setup.init_vector_db --db-path .data-demo/serve/receipts.db --vector-db-path .data-demo/vector_db

exec python -m expense_flow.api.main --host 0.0.0.0 --port 8000