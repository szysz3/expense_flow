from typing import List, Dict, Any
import re
import unicodedata
from expense_flow.services.vector_store_service import VectorStoreService
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
        if not text:
            return ""
            
        text = text.lower()
        
        # Remove diacritics (accents)
        text = ''.join(c for c in unicodedata.normalize('NFD', text)
                      if unicodedata.category(c) != 'Mn')
        
        text = re.sub(r'\s+', ' ', text).strip()
        
        return text
    
    def _text_similarity_score(self, query: str, target: str) -> float:
        """
        Calculate text-based similarity score
        
        Args:
            query: Normalized query text
            target: Normalized target text
            
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
        
        normalized_query = self._normalize_text(partial_text)
        if not normalized_query:
            return []
            
        try:
            similar_items = self.vector_store.search_similar_items(partial_text, limit=limit * 2)
            
            suggestions = []
            seen_descriptions = set()
            
            for item in similar_items:
                description = item.payload.get("description", "")
                
                if description in seen_descriptions:
                    continue
                
                normalized_desc = item.payload.get("normalized_description", "")
                if not normalized_desc:
                    normalized_desc = self._normalize_text(description)
                    
                text_sim = self._text_similarity_score(normalized_query, normalized_desc)
                
                combined_score = (0.4 * item.score) + (0.6 * text_sim)
                
                if combined_score > 0.2:
                    suggestions.append({
                        "description": description,
                        "category": item.payload.get("category", ""),
                        "score": combined_score
                    })
                    seen_descriptions.add(description)
            
            suggestions = sorted(suggestions, key=lambda x: x["score"], reverse=True)
            
            return suggestions[:limit]
            
        except Exception as e:
            logger.error(f"Error getting suggestions: {str(e)}")
            return []