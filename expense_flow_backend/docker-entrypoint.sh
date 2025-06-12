#!/bin/bash
set -e

echo "Starting ExpenseFlow API in ${MODE:-production} mode..."

python -m scripts.setup.init_vector_db

exec python -m expense_flow.api.main --host 0.0.0.0 --port 8000