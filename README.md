# expense_flow
Guides families through their spending patterns with clear direction!

# overview

```mermaid
sequenceDiagram
    participant C as Client
    participant A as API Server
    participant AZ as Azure OCR
    participant TD as Temp DB
    participant O as Ollama PC
    participant RD as Receipt DB

    C->>A: POST /api/receipts/analyze
    A->>AZ: Process image
    AZ-->>A: OCR results
    A->>TD: Store raw receipt
    A-->>C: 200 OK + temp_receipt_id

    Note over O,A: Ollama PC comes online
    O->>A: POST /api/analyzer/register
    A-->>O: 200 OK

    loop Process pending receipts
        A->>TD: Get unprocessed receipt
        TD-->>A: Raw receipt data
        A->>O: Send for analysis
        O-->>A: Categorized receipt
        A->>RD: Store final receipt
        A->>TD: Delete processed receipt
    end```
