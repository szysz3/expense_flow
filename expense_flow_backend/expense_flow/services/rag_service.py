# expense_flow/services/rag_service.py
from typing import List, Dict, Any
import logging
from expense_flow.services.similarity_service import SimilarityService
from expense_flow.services.vector_store_service import VectorStoreService

logger = logging.getLogger("expense_flow")

class RAGService:
    """Service for Retrieval Augmented Generation with receipt items"""
    
    def __init__(self, vector_store_service: VectorStoreService):
        """
        Initialize RAG service
        
        Args:
            vector_store_service: Vector store service for similarity search
        """
        self.similarity_service = SimilarityService(vector_store_service)
    
    def get_similar_items(self, item_description: str, limit: int = 5) -> List[Dict[str, Any]]:
        """
        Get similar previously categorized items from the vector store
        
        Args:
            item_description: Item description to find similar items for
            limit: Maximum number of similar items to return
            
        Returns:
            List of similar items with their categories
        """
        if not item_description:
            return []
            
        try:
            similar_items = self.similarity_service.search_similar_items(
                item_description, 
                limit=limit,
                score_threshold=0.2
            )
            
            return [
                {
                    "description": item["description"],
                    "category": item["category"],
                    "similarity": item["similarity"]
                }
                for item in similar_items
            ]
            
        except Exception as e:
            logger.error(f"Error getting similar items: {str(e)}")
            return []
    
    def format_examples_for_prompt(self, similar_items: List[Dict[str, Any]]) -> str:
        """
        Format similar items as examples for the LLM prompt
        
        Args:
            similar_items: List of similar items with their categories
            
        Returns:
            Formatted examples string
        """
        if not similar_items:
            return "No similar items found in database."
            
        examples = ''
        for i, item in enumerate(similar_items):
            examples += f"{i+1}. \"{item['description']}\" → {item['category']} (similarity: {item['similarity']:.2f})\n"
            
        return examples
    
    def get_examples_for_item(self, item_description: str, limit: int = 3) -> str:
        """
        Get formatted examples for an item description
        
        Args:
            item_description: Item description to find examples for
            limit: Maximum number of examples
            
        Returns:
            Formatted examples string
        """
        similar_items = self.get_similar_items(item_description, limit=limit)
        return self.format_examples_for_prompt(similar_items)