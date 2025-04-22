from typing import List, Dict, Any
from expense_flow.services.vector_store import VectorStoreService
import logging

logger = logging.getLogger("expense_flow")

class AutoCompleteService:
    """Service for providing auto-complete suggestions for receipt items"""
    
    def __init__(self, vector_store_service: VectorStoreService):
        """
        Initialize auto-complete service
        
        Args:
            vector_store_service: Vector store service for similarity search
        """
        self.vector_store = vector_store_service
    
    def get_suggestions(self, partial_text: str, limit: int = 5) -> List[Dict[str, Any]]:
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
            similar_items = self.vector_store.search_similar_items(partial_text, limit=limit)
            
            suggestions = []
            for item in similar_items:
                if item.score > 0.4:  
                    suggestions.append({
                        "description": item.payload.get("description", ""),
                        "category": item.payload.get("category", ""),
                        "score": item.score
                    })
            
            return suggestions
        except Exception as e:
            logger.error(f"Error getting suggestions: {str(e)}")
            return []