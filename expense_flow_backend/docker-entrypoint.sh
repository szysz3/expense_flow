#!/bin/bash
set -e

echo "Starting ExpenseFlow API in ${MODE:-production} mode..."

if [ -f .data/serve/receipts.db ] && [ ! -f .data/serve/receipts.sqlite3 ]; then
  echo "Migrating production TinyDB store to SQLite..."
  python -m scripts.migrate_tinydb_to_sqlite \
    --receipts-tinydb .data/serve/receipts.db \
    --receipts-sqlite .data/serve/receipts.sqlite3 \
    --temp-tinydb .data/serve/temp_receipts.db \
    --temp-sqlite .data/serve/temp_receipts.sqlite3
fi

if [ -f .data-demo/serve/receipts.db ] && [ ! -f .data-demo/serve/receipts.sqlite3 ]; then
  echo "Migrating demo TinyDB store to SQLite..."
  python -m scripts.migrate_tinydb_to_sqlite \
    --receipts-tinydb .data-demo/serve/receipts.db \
    --receipts-sqlite .data-demo/serve/receipts.sqlite3 \
    --temp-tinydb .data-demo/serve/temp_receipts.db \
    --temp-sqlite .data-demo/serve/temp_receipts.sqlite3
fi

echo "Initializing production vector database..."
python -m scripts.setup.init_vector_db --db-path .data/serve/receipts.sqlite3 --vector-db-path .data/vector_db

echo "Initializing demo vector database..."
python -m scripts.setup.init_vector_db --db-path .data-demo/serve/receipts.sqlite3 --vector-db-path .data-demo/vector_db

exec python -m expense_flow.api.main --host 0.0.0.0 --port 8000
