FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p .data/serve .data/analyzis

RUN useradd -m appuser
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

COPY docker-entrypoint.sh /app/

ENTRYPOINT ["/app/docker-entrypoint.sh"]