# expense_flow_backend

Python backend with FastAPI and TinyDB.

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
6. Prepare backup media and run:
```
./scripts/setup/setup-backup-cron.sh
```