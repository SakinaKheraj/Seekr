from pydantic import BaseModel
from typing import Optional

class ChatRequest(BaseModel):
    query: str

class Source(BaseModel):
    title: str
    link: str