from pydantic import BaseModel
from typing import Optional

class ChatRequest(BaseModel):
    query: str
    session_id: Optional[str] = None

class Source(BaseModel):
    title: str
    link: str