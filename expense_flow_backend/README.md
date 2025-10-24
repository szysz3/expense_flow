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

## Firebase Cloud Messaging

Enable push notifications by supplying Firebase service account credentials via either the `FIREBASE_CREDENTIALS_PATH` (path to a JSON file) or `FIREBASE_CREDENTIALS_JSON` (raw JSON payload) environment variables. Once configured, mobile clients can manage their registration tokens using:

- `POST /api/notifications/devices` – register a device (`token`, `platform`=`ios|android`)
- `DELETE /api/notifications/devices` – unregister a device (`token`)

Completed receipt processing runs automatically trigger notifications to all registered devices.

## End-to-end verification

After installing the project dependencies (particularly `uvicorn`), you can exercise the HTTP API against the seeded `.data/serve` SQLite database. The script uses real `curl` calls to cover every REST endpoint (create/update/delete receipts, analytics summaries, autocomplete, temp receipt flows, etc.) and compares the responses with the live SQLite contents:

```
python3 scripts/tests/run_receipts_e2e.py
```

If you already have the API running, reuse it instead of launching a new server:

```
python3 scripts/tests/run_receipts_e2e.py --reuse-server --api-key <your-api-key>
```
