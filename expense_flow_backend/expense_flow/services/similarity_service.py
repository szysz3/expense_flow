from typing import List, Dict, Any, Optional
import logging
from expense_flow.services.vector_store_service import VectorStoreService
from expense_flow.services.text_processing_service import TextProcessingService

logger = logging.getLogger("expense_flow")

class SimilarityService:
    """Base service for similarity operations across the application"""
    
    def __init__(self, vector_store_service: VectorStoreService):
        """
        Initialize similarity service
        
        Args:
            vector_store_service: Vector store service for similarity search
        """
        self.vector_store = vector_store_service
        self.text_processor = TextProcessingService()
    
    def search_similar_items(
        self, 
        query: str, 
        limit: int = 5,
        score_threshold: float = 0.2,
        combine_vector_weight: float = 0.4,
        combine_text_weight: float = 0.6
    ) -> List[Dict[str, Any]]:
        """
        Search for similar items with combined vector and text-based similarity
        
        Args:
            query: Query text to find similar items for
            limit: Maximum number of results to return
            score_threshold: Minimum combined score threshold
            combine_vector_weight: Weight for vector similarity score (0.0-1.0)
            combine_text_weight: Weight for text similarity score (0.0-1.0)
            
        Returns:
            List of similar items with their metadata and scores
        """
        if not query:
            return []
            
        normalized_query = self.text_processor.normalize_text(query)
        if not normalized_query:
            return []
            
        try:
            similar_items = self.vector_store.search_similar_items(query, limit=limit * 2)
            
            result = []
            seen_descriptions = set()
            
            for item in similar_items:
                description = item.payload.get("description", "")
                
                if description in seen_descriptions:
                    continue
                
                normalized_desc = item.payload.get("normalized_description", "")
                if not normalized_desc:
                    normalized_desc = self.text_processor.normalize_text(description)
                    
                text_sim = self.text_processor.calculate_text_similarity(normalized_query, normalized_desc)
                
                combined_score = (combine_vector_weight * item.score) + (combine_text_weight * text_sim)
                
                if combined_score > score_threshold:
                    result.append({
                        "description": description,
                        "category": item.payload.get("category", ""),
                        "similarity": combined_score,
                        "receipt_id": item.payload.get("receipt_id", ""),
                        "vector_score": item.score,
                        "text_score": text_sim
                    })
                    seen_descriptions.add(description)
            
            result = sorted(result, key=lambda x: x["similarity"], reverse=True)
            
            return result[:limit]
            
        except Exception as e:
            logger.error(f"Error searching similar items: {str(e)}")
            return []