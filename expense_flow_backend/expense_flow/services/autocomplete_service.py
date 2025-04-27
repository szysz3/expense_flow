from typing import List, Dict, Any
import logging
from expense_flow.services.similarity_service import SimilarityService
from expense_flow.services.vector_store_service import VectorStoreService

logger = logging.getLogger("expense_flow")

class AutoCompleteService:
    """Service for providing auto-complete suggestions for receipt items"""
    
    def __init__(self, vector_store_service: VectorStoreService):
        """
        Initialize auto-complete service
        
        Args:
            vector_store_service: Vector store service for similarity search
        """
        self.similarity_service = SimilarityService(vector_store_service)
    
    def get_suggestions(self, partial_text: str, limit: int = 8) -> List[Dict[str, Any]]:
        """
        Get auto-complete suggestions based on partial text input
        
        Args:
            partial_text: Partial text to match
            limit: Maximum number of suggestions
            
        Returns:
            List of suggestion items with description, category and score
        """
        if not partial_text:
            return []
            
        try:
            similar_items = self.similarity_service.search_similar_items(
                partial_text, 
                limit=limit,
                score_threshold=0.2
            )
            
            return [
                {
                    "description": item["description"],
                    "category": item["category"],
                    "score": item["similarity"]
                }
                for item in similar_items
            ]
            
        except Exception as e:
            logger.error(f"Error getting suggestions: {str(e)}")
            return []