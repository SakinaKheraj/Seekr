from pydantic import BaseModel, Field
from typing import List, Dict
from server.pydantic_models.chat_body import Source

class BookmarkRequest(BaseModel):
    query: str
    answer: str
    sources: List[Source] = Field(default_factory=list)
    folder_name: str

class BookmarkResponse(BaseModel):
    bookmark_id: str
    message: str = "Bookmark saved successfully"

class BookmarkItem(BaseModel):
    id: str
    query: str
    answer: str
    sources: List[Source] = Field(default_factory=list)
    created_at: str

class CollectionResponse(BaseModel):
    # A dictionary mapping folder_name -> list of bookmarks
    folders: Dict[str, List[BookmarkItem]]
