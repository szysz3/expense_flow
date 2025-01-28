class TextProcessor:
    def _is_polish_char(self, char: str) -> bool:
        polish_chars = {'Ż', 'Ź', 'Ą', 'Ę', 'Ś', 'Ć', 'Ń', 'Ó', 'Ł'}
        return char.upper() in polish_chars

    def compare_text_ignore_polish(self, original: str, result: str) -> bool:
        if len(original) != len(result):
            return False
            
        for orig_char, result_char in zip(original.upper(), result.upper()):
            if not self._is_polish_char(orig_char) and orig_char != result_char:
                return False
        return True