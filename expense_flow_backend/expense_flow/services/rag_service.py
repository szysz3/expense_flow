from typing import Any, Dict, List
import logging
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
        self.vector_store = vector_store_service
    
    def _text_similarity_score(self, query: str, target: str) -> float:
        """
        Calculate text-based similarity score
        
        Args:
            query: Query text
            target: Target text
            
        Returns:
            Similarity score between 0 and 1
        """
        # Check if query is a prefix of any word in target
        words = target.split()
        if any(word.startswith(query) for word in words):
            return 0.9  # High score for prefix matches
        
        # Check if query appears anywhere in target
        if query in target:
            return 0.8
        
        # Check if all terms in query appear in target
        query_terms = query.split()
        if all(term in target for term in query_terms):
            return 0.7
            
        return 0.0  # No text-based match
    
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
            similar_items = self.vector_store.search_similar_items(item_description, limit=limit * 2)
            
            result = []
            seen_descriptions = set()
            
            for item in similar_items:
                description = item.payload.get("description", "")
                
                if description in seen_descriptions:
                    continue
                
                text_sim = self._text_similarity_score(item_description, description)
                
                combined_score = (0.4 * item.score) + (0.6 * text_sim)
                
                if combined_score > 0.2:
                    result.append({
                        "description": description,
                        "category": item.payload.get("category", ""),
                        "similarity": combined_score
                    })
                    seen_descriptions.add(description)
            
            result = sorted(result, key=lambda x: x["similarity"], reverse=True)
            
            return result[:limit]
            
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