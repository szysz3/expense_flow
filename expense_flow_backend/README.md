# <img src="https://github.com/user-attachments/assets/40f6c7b3-30d2-47df-8229-29fc836bf4e6" width="48" height="48"> expense_flow_backend

Python backend with FastAPI and SQLite (via SQLAlchemy).

## Setup

1. Setup [Ollama](https://github.com/ollama/ollama) on your AI capable host and download LLMs.

2. Get the code.
```
git clone git@github.com:szysz3/expense_flow.git
```

3. Setup docker container.
```
cd expense_flow/expense_flow_backend/scripts/setup
./setup-docker.sh
```
4. Fill `.env` with keys.
5. Run compose.
```
docker-compose up -d
```
6. Migrate any existing TinyDB data (one time only):
```
python -m scripts.migrate_tinydb_to_sqlite \
  --receipts-tinydb .data/serve/receipts.db \
  --receipts-sqlite .data/serve/receipts.sqlite3 \
  --temp-tinydb .data/serve/temp_receipts.db \
  --temp-sqlite .data/serve/temp_receipts.sqlite3
```

7. Prepare backup media and run:
```
./scripts/setup/setup-backup-cron.sh
```
