import logging
import time
from collections import defaultdict
from typing import Dict, List

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.concurrency import run_in_threadpool

from server.services import firebase_config
from server.services.firebase_auth_service import verify_firebase_token
from server.services.search_service import google_search
from server.services.chat_service import chat_with_search
from server.services.cache_service import ai_cache
from server.services.llm_service import generate_ai_response, build_prompt, generate_draft
from server.services.database_service import (
    get_user_sessions,
    get_session_history,
    get_session_messages,
    clear_user_history,
    count_today_messages,
)
from server.services.collections_service import (
    save_bookmark_sync,
    get_collections_sync,
    delete_bookmark_sync,
)
from server.pydantic_models.chat_body import ChatRequest, Source, DraftRequest
from server.pydantic_models.chat_response import ChatResponse
from server.pydantic_models.search_models import SearchRequest, SearchResponse
from server.pydantic_models.llm_models import LLMRequest, LLMResponse
from server.pydantic_models.collection_models import (
    BookmarkRequest,
    BookmarkResponse,
    CollectionResponse,
)

# ── App setup ─────────────────────────────────────────────────────────────────

app = FastAPI(title="SeekrAI")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,   # must be False when allow_origins=["*"]
    allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

firebase_config.initialize_firebase()

# ── Per-IP rate limiter ───────────────────────────────────────────────────────
# Prevents abuse on expensive endpoints (search, llm, draft).
# Allows 30 requests per minute per IP before returning 429.

_rate_store: Dict[str, List[float]] = defaultdict(list)
_RATE_LIMIT = 30    # max requests
_RATE_WINDOW = 60   # per second window


def rate_limit(request: Request):
    ip = request.client.host
    now = time.time()
    window_start = now - _RATE_WINDOW

    # Remove timestamps outside the current window
    _rate_store[ip] = [t for t in _rate_store[ip] if t > window_start]

    if len(_rate_store[ip]) >= _RATE_LIMIT:
        raise HTTPException(
            status_code=429,
            detail="Too many requests. Please slow down and try again shortly."
        )

    _rate_store[ip].append(now)


# ── Health ────────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"status": "healthy"}


# ── Chat ──────────────────────────────────────────────────────────────────────

@app.post("/chat", response_model=ChatResponse)
async def chat(
    body: ChatRequest,
    user=Depends(verify_firebase_token),
):
    try:
        # Enforce daily question limit
        today_count = await count_today_messages(user["uid"])
        if today_count >= 10:
            raise HTTPException(
                status_code=429,
                detail="Daily question limit (10) reached. Try again tomorrow.",
            )

        answer, sources, followups = await chat_with_search(body.query, user["uid"])

        return ChatResponse(
            answer=answer,
            sources=sources,
            followups=followups,
            user_id=user["uid"],
        )

    except HTTPException:
        raise  # re-raise 429 cleanly without wrapping it in a 500
    except Exception as e:
        logger.error(f"[CHAT ERROR] uid={user['uid'][:8]}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# ── Search ────────────────────────────────────────────────────────────────────

@app.post("/search", response_model=SearchResponse, dependencies=[Depends(rate_limit)])
async def search(
    body: SearchRequest,
    user=Depends(verify_firebase_token),
):
    try:
        results = await google_search(body.query)
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── LLM ───────────────────────────────────────────────────────────────────────

@app.post("/llm", response_model=LLMResponse, dependencies=[Depends(rate_limit)])
async def llm(
    body: LLMRequest,
    user=Depends(verify_firebase_token),
):
    try:
        answer = await run_in_threadpool(generate_ai_response, body.prompt)
        return {"answer": answer}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── History ───────────────────────────────────────────────────────────────────

@app.get("/history")
async def history(
    limit: int = 20,   # was 1000 — reduced to prevent expensive reads
    user=Depends(verify_firebase_token),
):
    try:
        sessions = await get_user_sessions(user["uid"], limit=limit)
        return sessions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/history/{session_id}")
async def history_details(
    session_id: str,
    user=Depends(verify_firebase_token),
):
    try:
        messages = await get_session_messages(user["uid"], session_id)
        return messages
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/history")
async def clear_history_endpoint(user=Depends(verify_firebase_token)):
    try:
        await clear_user_history(user["uid"])
        return {"message": "History cleared successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Stats ─────────────────────────────────────────────────────────────────────

@app.get("/stats")
async def stats(user=Depends(verify_firebase_token)):
    try:
        used = await count_today_messages(user["uid"])
        return {
            "name": user.get("name") or user.get("email", ""),
            "email": user.get("email", ""),
            "total_sessions": 10,
            "used_sessions": used,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Collections ───────────────────────────────────────────────────────────────

@app.post("/bookmarks", response_model=BookmarkResponse)
async def create_bookmark(
    body: BookmarkRequest,
    user=Depends(verify_firebase_token),
):
    try:
        bookmark_id = await run_in_threadpool(
            save_bookmark_sync,
            user["uid"],
            body.folder_name,
            body.query,
            body.answer,
            [s.model_dump() for s in body.sources],
        )
        return BookmarkResponse(bookmark_id=bookmark_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/collections", response_model=CollectionResponse)
async def get_collections(user=Depends(verify_firebase_token)):
    try:
        folders = await run_in_threadpool(get_collections_sync, user["uid"])
        return CollectionResponse(folders=folders)
    except Exception as e:
        logger.error(f"[COLLECTIONS ERROR] {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/bookmarks/{bookmark_id}")
async def delete_bookmark(
    bookmark_id: str,
    user=Depends(verify_firebase_token),
):
    try:
        await run_in_threadpool(delete_bookmark_sync, user["uid"], bookmark_id)
        return {"message": "Deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Drafting Lab ──────────────────────────────────────────────────────────────

@app.post("/draft", dependencies=[Depends(rate_limit)])
async def create_draft(
    body: DraftRequest,
    user=Depends(verify_firebase_token),
):
    try:
        # Check RAM cache first — repeated draft requests cost $0
        cache_key = f"DRAFT:{body.format}:{body.text[:100]}"
        cached = ai_cache.get_cached_response(cache_key)

        if cached:
            print(f" 🚀 [CACHE HIT] Draft '{body.format}' served instantly. Saved 1 API call!")
            return {"draft": cached["answer"]}

        draft = await run_in_threadpool(generate_draft, body.text, body.format)

        # Cache so repeated clicks don't hit Gemini
        ai_cache.save_response(cache_key, draft, [], [])

        return {"draft": draft}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))