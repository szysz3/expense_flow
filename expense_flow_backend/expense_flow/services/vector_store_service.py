from expense_flow.config import Config
from qdrant_client import QdrantClient
from qdrant_client.http import models
import numpy as np
from typing import Dict, List, Any, Optional
from sentence_transformers import SentenceTransformer
import os
import uuid
import logging
from expense_flow.services.text_processing_service import TextProcessingService

logger = logging.getLogger("expense_flow")

class VectorStoreService:
    """Service for managing vector embeddings and similarity search"""
    
    def __init__(self, config: Config):
        """
        Initialize vector store service
        
        Args:
            config: Application configuration
        """
        self.config = config
        
        os.makedirs(os.path.dirname(str(config.vector_db_path)), exist_ok=True)
        
        self.embedding_model = SentenceTransformer(config.embedding_model)
        self.vector_size = self.embedding_model.get_sentence_embedding_dimension()
        
        self.client = QdrantClient(
            path=str(config.vector_db_path),
            prefer_grpc=False
        )
        
        self.text_processor = TextProcessingService()
        
        self._init_collections()
        
    def _init_collections(self):
        """Initialize vector collections if they don't exist"""
        collections = [c.name for c in self.client.get_collections().collections]
        
        if "items" not in collections:
            self.client.create_collection(
                collection_name="items",
                vectors_config=models.VectorParams(size=self.vector_size, distance=models.Distance.COSINE),
            )
    
    def _normalize_text(self, text: str) -> str:
        """
        Normalize text for improved matching:
        - Convert to lowercase
        - Remove diacritics (accents)
        - Replace multiple spaces with single space
        
        Args:
            text: Text to normalize
            
        Returns:
            Normalized text
        """
        return self.text_processor.normalize_text(text)
    
    def generate_embedding(self, text: str) -> np.ndarray:
        """
        Generate embedding for text
        
        Args:
            text: Text to generate embedding for
            
        Returns:
            Embedding vector as numpy array
        """
        return self.embedding_model.encode(text)
    
    def add_item_embedding(self, item_data: Dict[str, Any]):
        """
        Add item embedding to vector store
        
        Args:
            item_data: Dictionary with item data including 'description' and 'category'
        """
        text = item_data['description']
        embedding = self.generate_embedding(text)
        
        point_id = str(uuid.uuid4())
        
        if 'id' not in item_data and 'receipt_id' in item_data:
            item_data['id'] = f"item_{item_data['receipt_id']}_{uuid.uuid4()}"
        
        item_data['normalized_description'] = self._normalize_text(text)
        
        self.client.upsert(
            collection_name="items",
            points=[models.PointStruct(
                id=point_id,
                vector=embedding.tolist(),
                payload=item_data
            )]
        )
    
    def search_similar_items(self, description: str, limit: int = 5):
        """
        Search for similar items using vector similarity
        
        Args:
            description: Description to search for
            limit: Maximum number of results
            
        Returns:
            List of similar items with payload and score
        """
        embedding = self.generate_embedding(description)
        
        return self.client.search(
            collection_name="items",
            query_vector=embedding.tolist(),
            limit=limit * 2,
            with_payload=True
        )
        
    def delete_items_by_receipt_id(self, receipt_id: str):
        """
        Delete all items associated with a receipt
        
        Args:
            receipt_id: ID of the receipt
        """
        self.client.delete(
            collection_name="items",
            points_selector=models.FilterSelector(
                filter=models.Filter(
                    must=[
                        models.FieldCondition(
                            key="receipt_id",
                            match=models.MatchValue(value=receipt_id)
                        )
                    ]
                )
            )
        )