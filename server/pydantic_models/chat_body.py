from pydantic import BaseModel
from typing import Optional

class ChatRequest(BaseModel):
    query: str

class Source(BaseModel):
    title: str
    link: str

class DraftRequest(BaseModel):
    text: str
    format: str # e.g., 'email', 'linkedin', 'markdown', 'summary'