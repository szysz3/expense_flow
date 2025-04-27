import re
import unicodedata

class TextProcessingService:
    """Service for common text processing operations"""
    
    @staticmethod
    def normalize_text(text: str) -> str:
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
        
        text = ''.join(c for c in unicodedata.normalize('NFD', text)
                      if unicodedata.category(c) != 'Mn')
        
        text = re.sub(r'\s+', ' ', text).strip()
        
        return text
    
    @staticmethod
    def calculate_text_similarity(query: str, target: str) -> float:
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