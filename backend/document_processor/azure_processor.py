from typing import Dict, Any
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.core.credentials import AzureKeyCredential
from rich.console import Console
from config import Config
import json

class AzureDocumentProcessor:
    def __init__(self, config: Config):
        self.console = Console()
        self.client = DocumentIntelligenceClient(
            endpoint=config.endpoint,
            credential=AzureKeyCredential(config.key)
        )

    def process_image(self, image_path: str) -> Dict[Any, Any]:
        with self.console.status("[bold green]Analyzing receipt image..."):
            with open(image_path, "rb") as image:
                poller = self.client.begin_analyze_document("prebuilt-receipt", image)
            result = poller.result()
            
            if not result.documents:
                raise ValueError("No receipt data found in the image")

            return self._extract_receipt_data(result.documents[0])

    def _extract_receipt_data(self, doc) -> Dict[Any, Any]:
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
        return {
            'valueObject': {
                'Description': {'content': item.value_object.get('Description', {}).value_string if item.value_object.get('Description') else ''},
                'Quantity': {'valueNumber': item.value_object.get('Quantity', {}).value_number if item.value_object.get('Quantity') else 0},
                'TotalPrice': {'valueCurrency': {'amount': item.value_object.get('TotalPrice', {}).value_currency.amount if item.value_object.get('TotalPrice') else 0}}
            }
        }

    def preprocess_receipt(self, raw_data: Dict[Any, Any]) -> Dict[Any, Any]:
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
        return {
            "description": item['valueObject'].get('Description', {}).get('content', ''),
            "quantity": item['valueObject'].get('Quantity', {}).get('valueNumber', 0),
            "total_price": item['valueObject'].get('TotalPrice', {}).get('valueCurrency', {}).get('amount', 0)
        }