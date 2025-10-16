from typing import Dict, Any
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.core.credentials import AzureKeyCredential
from azure.core.exceptions import HttpResponseError
from rich.console import Console
from expense_flow.config import Config
import json
import time

class AzureDocumentProcessor:
    """
    Process receipt images using Azure Document Intelligence service
    """
    def __init__(self, config: Config):
        """
        Initialize Azure Document processor

        Args:
            config: Application configuration
        """
        self.console = Console()

        if not config.azure_endpoint or not config.azure_key:
            raise ValueError("Azure Document Intelligence credentials not configured. "
                             "Please set AZURE_ENDPOINT and AZURE_KEY in your .env file.")

        # Create client with custom polling interval to avoid rate limits
        # Default is 1s, but 5s is recommended by Azure to reduce API calls
        self.client = DocumentIntelligenceClient(
            endpoint=config.azure_endpoint,
            credential=AzureKeyCredential(config.azure_key),
            polling_interval=5  # Poll every 5 seconds (Azure recommended)
        )

        # Retry configuration for rate limit errors
        self.timeout = 120  # Maximum wait time in seconds
        self.max_retries = 3  # Maximum retry attempts for rate limit errors
        self.base_backoff = 5  # Base backoff time in seconds for exponential backoff

    def process_image(self, image_path: str) -> Dict[Any, Any]:
        """
        Process receipt image with Azure Document Intelligence

        Args:
            image_path: Path to receipt image

        Returns:
            Dictionary with extracted receipt data
        """
        with self.console.status("[bold green]Analyzing receipt image..."):
            # Retry loop for rate limit errors
            for attempt in range(self.max_retries):
                try:
                    with open(image_path, "rb") as image:
                        poller = self.client.begin_analyze_document("prebuilt-receipt", image)

                    # Wait for result with timeout (polling interval set in client constructor)
                    result = poller.result(timeout=self.timeout)

                    if not result.documents:
                        raise ValueError("No receipt data found in the image")

                    return self._extract_receipt_data(result.documents[0])

                except HttpResponseError as e:
                    # Check if it's a rate limit error (429)
                    if e.status_code == 429:
                        if attempt < self.max_retries - 1:
                            # Exponential backoff: 5s, 10s, 20s
                            backoff_time = self.base_backoff * (2 ** attempt)

                            # Try to get retry-after header from response
                            retry_after = e.response.headers.get('Retry-After')
                            if retry_after:
                                try:
                                    backoff_time = max(backoff_time, int(retry_after))
                                except (ValueError, TypeError):
                                    pass

                            self.console.print(f"[yellow]Rate limit hit. Retrying in {backoff_time}s (attempt {attempt + 1}/{self.max_retries})...[/]")
                            time.sleep(backoff_time)
                            continue
                        else:
                            raise Exception(f"Rate limit exceeded after {self.max_retries} attempts. Please try again later.")
                    else:
                        # Re-raise non-rate-limit errors immediately
                        raise

            # This should not be reached but just in case
            raise Exception("Failed to process image after all retry attempts")

    def _extract_receipt_data(self, doc) -> Dict[Any, Any]:
        """
        Extract structured data from Azure document result
        
        Args:
            doc: Azure Document Intelligence result
            
        Returns:
            Dictionary with extracted fields
        """
        return {
            'analyzeResult': {
                'documents': [{
                    'fields': {
                        'MerchantName': {'content': doc.fields.get('MerchantName', {}).value_string if doc.fields.get('MerchantName') else ''},
                        'MerchantAddress': {'content': doc.fields.get('MerchantAddress', {}).content if doc.fields.get('MerchantAddress') else ''},
                        'TransactionDate': {'valueDate': doc.fields.get('TransactionDate', {}).value_date if doc.fields.get('TransactionDate') else ''},
                        'TransactionTime': {'valueTime': doc.fields.get('TransactionTime', {}).value_time if doc.fields.get('TransactionTime') else ''},
                        'Items': {'valueArray': [
                            self._extract_item_data(item) for item in doc.fields.get('Items', {}).value_array
                        ]},
                        'Total': {'valueCurrency': {'amount': doc.fields.get('Total', {}).value_currency.amount if doc.fields.get('Total') else 0}}
                    }
                }]
            }
        }

    def _extract_item_data(self, item) -> Dict[str, Any]:
        """
        Extract structured data for a receipt item
        
        Args:
            item: Receipt item from Azure Document Intelligence
            
        Returns:
            Dictionary with item data
        """
        return {
            'valueObject': {
                'Description': {'content': item.value_object.get('Description', {}).value_string if item.value_object.get('Description') else ''},
                'Quantity': {'valueNumber': item.value_object.get('Quantity', {}).value_number if item.value_object.get('Quantity') else 0},
                'TotalPrice': {'valueCurrency': {'amount': item.value_object.get('TotalPrice', {}).value_currency.amount if item.value_object.get('TotalPrice') else 0}}
            }
        }

    def preprocess_receipt(self, raw_data: Dict[Any, Any]) -> Dict[Any, Any]:
        """
        Convert Azure Document Intelligence format to application format
        
        Args:
            raw_data: Raw data from Azure Document Intelligence
            
        Returns:
            Dictionary in application's receipt format
        """
        docs = raw_data['analyzeResult'].get('documents', [])
        if not docs:
            return {}
        
        fields = docs[0].get('fields', {})
        date = fields.get('TransactionDate', {}).get('valueDate', '')
        time = fields.get('TransactionTime', {}).get('valueTime', '')
        
        json_data = {
            "merchant": {
                "name": fields.get('MerchantName', {}).get('content', ''),
                "address": fields.get('MerchantAddress', {}).get('content', '')
            },
            "items": [
                self._process_item(item) for item in fields.get('Items', {}).get('valueArray', [])
            ],
            "total": fields.get('Total', {}).get('valueCurrency', {}).get('amount', 0),
            "transaction_datetime": f"{date} {time}" if date and time else ""
        }
        
        return json.loads(json.dumps(json_data, ensure_ascii=True))

    def _process_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process a receipt item from Azure format to application format
        
        Args:
            item: Receipt item in Azure format
            
        Returns:
            Receipt item in application format
        """
        return {
            "description": item['valueObject'].get('Description', {}).get('content', ''),
            "quantity": item['valueObject'].get('Quantity', {}).get('valueNumber', 0),
            "total_price": item['valueObject'].get('TotalPrice', {}).get('valueCurrency', {}).get('amount', 0)
        }