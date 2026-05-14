import hashlib
from typing import Optional, Dict, Any

class MemoryCache:
    """
    A lightweight, in-memory caching middleware designed to reduce LLM quota consumption 
    and guarantee sub-millisecond response times for frequent queries.
    """
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(MemoryCache, cls).__new__(cls)
            # Memory store mapping query hashes to full chat responses
            cls._instance.store = {}
        return cls._instance

    def _generate_key(self, query: str) -> str:
        """Create a resilient md5 hash from the normalized user query."""
        # Normalization ignores casing and trailing punctuation to maximize hits
        normalized = query.lower().strip().strip("?!.")
        return hashlib.md5(normalized.encode('utf-8')).hexdigest()

    def get_cached_response(self, query: str) -> Optional[Dict[str, Any]]:
        """Retrieve a saved response if the query has been asked before."""
        key = self._generate_key(query)
        return self.store.get(key)

    def save_response(self, query: str, answer: str, sources: list, followups: list):
        """Store the successful AI pipeline output into the fast-access RAM cache."""
        key = self._generate_key(query)
        self.store[key] = {
            "answer": answer,
            "sources": sources,
            "followups": followups
        }

# Instantiate global singleton cache accessible across API routes
ai_cache = MemoryCache()
