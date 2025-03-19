#!/bin/bash
set -e

# Start the API service
exec python -m expense_flow.api.main --host 0.0.0.0 --port 8000