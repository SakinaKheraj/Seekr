from pydantic import BaseModel
from typing import List
from .chat_body import Source

class ChatResponse(BaseModel):
    answer: str
    sources: List[Source]
    followups: List[str] = []
    user_id: str