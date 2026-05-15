import hashlib
import time
from typing import Optional, Dict, Any


class MemoryCache:
    """
    A lightweight, in-memory caching middleware designed to reduce LLM quota consumption
    and guarantee sub-millisecond response times for frequent queries.

    Optimizations added:
    - TTL (1 hour): Stale entries are automatically expired on access.
    - Max size (500 entries): Oldest entry is evicted when capacity is reached.
    - Prevents unbounded RAM growth on long-running free-tier servers.
    """

    _instance = None
    MAX_SIZE = 500       # Maximum number of cached entries before eviction
    TTL_SECONDS = 3600   # Cache entries expire after 1 hour

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(MemoryCache, cls).__new__(cls)
            # Memory store: key → {"data": {...}, "ts": float}
            cls._instance.store = {}
        return cls._instance

    def _generate_key(self, query: str) -> str:
        """Create a resilient MD5 hash from the normalized user query.
        Normalization ignores casing and trailing punctuation to maximize cache hits.
        """
        normalized = query.lower().strip().strip("?!.")
        return hashlib.md5(normalized.encode('utf-8')).hexdigest()

    def get_cached_response(self, query: str) -> Optional[Dict[str, Any]]:
        """Retrieve a saved response if the query has been asked before.
        Returns None if the entry is missing or has expired.
        """
        key = self._generate_key(query)
        entry = self.store.get(key)

        if not entry:
            return None

        # Expire stale entries silently on access
        if time.time() - entry["ts"] > self.TTL_SECONDS:
            del self.store[key]
            print(f" [CACHE] Entry expired and removed for key: {key[:8]}...")
            return None

        return entry["data"]

    def save_response(self, query: str, answer: str, sources: list, followups: list):
        """Store the successful AI pipeline output into the fast-access RAM cache.
        Evicts the oldest entry if the cache is at capacity.
        """
        # Evict oldest entry to stay within memory budget
        if len(self.store) >= self.MAX_SIZE:
            oldest_key = min(self.store, key=lambda k: self.store[k]["ts"])
            del self.store[oldest_key]
            print(f" [CACHE] Max size reached. Evicted oldest entry: {oldest_key[:8]}...")

        key = self._generate_key(query)
        self.store[key] = {
            "data": {
                "answer": answer,
                "sources": sources,
                "followups": followups,
            },
            "ts": time.time()
        }

    def get_stats(self) -> Dict[str, Any]:
        """Returns cache statistics for debugging and monitoring."""
        now = time.time()
        active = sum(1 for e in self.store.values() if now - e["ts"] <= self.TTL_SECONDS)
        return {
            "total_entries": len(self.store),
            "active_entries": active,
            "expired_entries": len(self.store) - active,
            "max_size": self.MAX_SIZE,
            "ttl_seconds": self.TTL_SECONDS,
        }


# Instantiate global singleton cache accessible across API routes
ai_cache = MemoryCache()