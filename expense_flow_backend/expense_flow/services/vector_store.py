# Modified code for expense_flow/services/vector_store.py

from expense_flow.config import Config
from qdrant_client import QdrantClient
from qdrant_client.http import models
import numpy as np
from typing import Dict, List, Any, Optional
from sentence_transformers import SentenceTransformer
import os
import uuid  # Make sure to import uuid
import logging

logger = logging.getLogger("expense_flow")

class VectorStoreService:
    """Service for managing vector embeddings and similarity search"""
    
    def __init__(self, config: Config):
        """Initialize vector store service"""
        self.config = config
        
        # Ensure vector database directory exists
        os.makedirs(os.path.dirname(str(config.vector_db_path)), exist_ok=True)
        
        # Initialize embedding model
        self.embedding_model = SentenceTransformer(config.embedding_model)
        self.vector_size = self.embedding_model.get_sentence_embedding_dimension()
        
        # Initialize Qdrant client
        self.client = QdrantClient(
            path=str(config.vector_db_path),
            prefer_grpc=False
        )
        
        # Initialize collections if they don't exist
        self._init_collections()
        
    def _init_collections(self):
        """Initialize vector collections if they don't exist"""
        collections = [c.name for c in self.client.get_collections().collections]
        
        # Collection for items
        if "items" not in collections:
            self.client.create_collection(
                collection_name="items",
                vectors_config=models.VectorParams(size=self.vector_size, distance=models.Distance.COSINE),
            )
    
    def generate_embedding(self, text: str) -> np.ndarray:
        """Generate embedding for text"""
        return self.embedding_model.encode(text)
    
    def add_item_embedding(self, item_data: Dict[str, Any]):
        """
        Add item embedding to vector store
        
        Args:
            item_data: Dictionary with item data including 'description' and 'category'
        """
        text = item_data['description']
        embedding = self.generate_embedding(text)
        
        # Generate a pure UUID without prefix
        point_id = str(uuid.uuid4())
        
        # Store the original ID in the payload if needed
        if 'id' not in item_data and 'receipt_id' in item_data:
            item_data['id'] = f"item_{item_data['receipt_id']}_{uuid.uuid4()}"
        
        self.client.upsert(
            collection_name="items",
            points=[models.PointStruct(
                id=point_id,  # Use the pure UUID as point ID
                vector=embedding.tolist(),
                payload=item_data
            )]
        )
    
    def search_similar_items(self, description: str, limit: int = 5):
        """Search for similar items"""
        embedding = self.generate_embedding(description)
        
        return self.client.search(
            collection_name="items",
            query_vector=embedding.tolist(),
            limit=limit
        )
        
    def delete_items_by_receipt_id(self, receipt_id: str):
        """Delete all items associated with a receipt"""
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