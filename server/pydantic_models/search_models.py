from pydantic import BaseModel
from typing import List

class SearchRequest(BaseModel):
    query: str

class SearchResult(BaseModel):
    title: str
    link: str
    snippet: str

class SearchResponse(BaseModel):
    results: List[SearchResult]