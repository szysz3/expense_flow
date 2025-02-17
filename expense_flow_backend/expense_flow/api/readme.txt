./run.sh serve

curl -X POST "http://localhost:8000/api/receipts/analyze" \
  -H "accept: application/json" \
  -H "X-API-Key: your_api_key" \
  -F "file=@path/to/your/receipt.jpg" \
  -F "llm_type=local"

  curl -X GET "http://localhost:8000/api/categories" \
  -H "accept: application/json" \
  -H "X-API-Key: your_api_key"

  curl -X GET "http://localhost:8000/api/months/summary" \
  -H "accept: application/json" \
  -H "X-API-Key: your_api_key"