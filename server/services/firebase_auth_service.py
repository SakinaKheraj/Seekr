import time
from typing import Dict
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth

security = HTTPBearer()

# ── Token verification cache ──────────────────────────────────────────────────
# Firebase token verification makes a network call on every request.
# Caching verified tokens for 5 minutes eliminates this overhead entirely
# for active users while keeping security tight (tokens still expire normally).
_token_cache: Dict[str, Dict] = {}
_TOKEN_TTL = 300       # 5 minutes
_TOKEN_CACHE_MAX = 500  # max cached tokens before eviction


def verify_firebase_token(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> Dict:
    token = credentials.credentials
    now = time.time()

    # ── Fast path: return cached decoded token ────────────────────────────────
    cached = _token_cache.get(token)
    if cached and (now - cached["ts"]) < _TOKEN_TTL:
        return cached["data"]

    # ── Slow path: verify with Firebase ──────────────────────────────────────
    try:
        decoded = auth.verify_id_token(token)

        # Evict oldest entry if cache is full
        if len(_token_cache) >= _TOKEN_CACHE_MAX:
            oldest = min(_token_cache, key=lambda k: _token_cache[k]["ts"])
            del _token_cache[oldest]

        _token_cache[token] = {"data": decoded, "ts": now}
        return decoded

    except Exception as e:
        print(f" [AUTH] Token verification failed: {str(e)}")
        raise HTTPException(
            status_code=401,
            detail=f"Invalid or expired token. Please log in again."
        )