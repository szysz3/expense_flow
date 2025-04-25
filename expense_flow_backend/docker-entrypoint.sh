#!/bin/bash
set -e

# Prepare vector db
python -m scripts.setup.init_vector_db

# Start the API service
exec python -m expense_flow.api.main --host 0.0.0.0 --port 8000