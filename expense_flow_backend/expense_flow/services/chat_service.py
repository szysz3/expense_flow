import uuid
from datetime import datetime
from typing import Dict, List, AsyncGenerator, Optional
from expense_flow.config import Config
from expense_flow.api.models import ChatMessage
from expense_flow.analyzers.llm_providers import OllamaProvider

class ChatService:
    """Service for interactive chats with LLMs"""
    
    def __init__(self, config: Config):
        """
        Initialize the chat service
        
        Args:
            config: Application configuration
        """
        self.config = config
        self._conversations: Dict[str, List[Dict[str, str]]] = {}
        self._provider = OllamaProvider(host=config.ollama_host, model=config.ollama_model)
    
    async def send_message(self, 
                         message: str, 
                         conversation_id: Optional[str] = None
                        ) -> AsyncGenerator[ChatMessage, None]:
        """
        Send message to LLM and stream response
        
        Args:
            message: User message
            conversation_id: ID of existing conversation or None for new conversation
            
        Yields:
            ChatMessage objects for each chunk of response
        """
        
        if not conversation_id or conversation_id not in self._conversations:
            conversation_id = str(uuid.uuid4())
            self._conversations[conversation_id] = []
        
        self._conversations[conversation_id].append({"role": "user", "content": message})
                
        assistant_id = str(uuid.uuid4())
        assistant_message = ChatMessage(
            id=assistant_id,
            content="",
            sender="assistant"
        )
        
        full_response = ""
        try:
            async for chunk in self._provider.chat_stream(self._conversations[conversation_id]):
                if "message" in chunk and "content" in chunk["message"]:
                    content_chunk = chunk["message"]["content"]
                    full_response += content_chunk
                    assistant_message.content = full_response
                    assistant_message.timestamp = datetime.utcnow()
                    yield assistant_message
            
            self._conversations[conversation_id].append({"role": "assistant", "content": full_response})
        except Exception as e:
            error_message = f"Error communicating with LLM provider: {str(e)}"
            assistant_message.content = f"Sorry, I encountered an error: {error_message}"
            yield assistant_message
        
    def get_conversation(self, conversation_id: str) -> List[ChatMessage]:
        """
        Get conversation history
        
        Args:
            conversation_id: ID of the conversation
            
        Returns:
            List of ChatMessage objects
        """
        if conversation_id not in self._conversations:
            return []
            
        messages = []
        for msg in self._conversations[conversation_id]:
            messages.append(
                ChatMessage(
                    content=msg["content"],
                    sender=msg["role"]
                )
            )
        return messages