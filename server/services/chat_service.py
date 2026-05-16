import asyncio
from fastapi.concurrency import run_in_threadpool
from server.services.search_service import google_search
from server.services.llm_service import (
    build_prompt,
    generate_answer_and_followups
)
from server.services.database_service import (
    save_chat_message,
    get_session_history,
    increment_today_count
)
from server.pydantic_models.chat_body import Source
from server.services.cache_service import ai_cache
from typing import Dict

# ── Search-level cache ────────────────────────────────────────────────────────
_search_cache: Dict[str, list] = {}
_SEARCH_CACHE_MAX = 200

# ── Skip-search detection ─────────────────────────────────────────────────────
_SKIP_SEARCH_EXACT = {
    "hi", "hello", "hey", "how are you", "who are you",
    "good morning", "good evening", "good night",
    "thanks", "thank you", "ok", "okay", "sure",
    "yes", "no", "why", "how", "what", "tell me more",
    "explain", "elaborate", "go on", "continue", "more",
    "and", "so", "then", "next", "what else",
}


def _should_skip_search(query: str) -> bool:
    """Returns True if the query is a greeting, filler, or very short follow-up."""
    clean = query.lower().strip().strip("?!.")
    if clean in _SKIP_SEARCH_EXACT:
        return True
    if len(clean.split()) <= 2:
        return True
    return False


async def _cached_google_search(query: str) -> list:
    """Wraps google_search with a lightweight in-memory cache."""
    key = query.lower().strip()
    if key in _search_cache:
        print(f" [SEARCH CACHE HIT] '{query[:40]}'")
        return _search_cache[key]

    results = await google_search(query)

    if len(_search_cache) >= _SEARCH_CACHE_MAX:
        _search_cache.pop(next(iter(_search_cache)))

    _search_cache[key] = results
    return results


async def chat_with_search(query: str, user_id: str):
    """
    Full optimized pipeline:
    1. RAM cache check         — 0ms, $0
    2. Skip-search detection   — saves Google API quota
    3. Parallel history+search — fastest possible data fetch
    4. Prompt construction     — trimmed for token efficiency
    5. Single AI call          — answer + followups in one request
    6. Non-blocking save       — returns to user immediately
    """

    # ── Step 0: RAM cache ─────────────────────────────────────────────────────
    cached_data = ai_cache.get_cached_response(query)
    if cached_data:
        print(f" 🚀 [CACHE HIT] '{query[:30]}' served instantly. Saved 1 API call!")
        asyncio.create_task(
            save_chat_message(
                user_id=user_id,
                query=query,
                answer=cached_data["answer"],
                sources=cached_data["sources"],
            )
        )
        increment_today_count(user_id)
        sources = [
            Source(title=r["title"], link=r["link"])
            for r in cached_data["sources"]
        ]
        return cached_data["answer"], sources, cached_data["followups"]

    # ── Step 1: Skip-search detection ────────────────────────────────────────
    is_greeting = _should_skip_search(query)

    # ── Step 2: Parallel fetch ────────────────────────────────────────────────
    # History and search run simultaneously — saves 1-2 seconds per request.
    if is_greeting:
        # Greetings don't need search — only fetch history
        history = await get_session_history(user_id, limit=2)
        search_results = []
    else:
        # Run history fetch and Google Search at the same time
        history, search_results = await asyncio.gather(
            get_session_history(user_id, limit=2),
            _cached_google_search(query),
        )

        # Contextual query expansion for short follow-up questions
        if history and len(query.split()) < 5:
            last_topic = history[0].get("query", "")
            if last_topic:
                expanded = f"{query} regarding {last_topic}"
                # Only re-search if not already cached
                if expanded.lower().strip() not in _search_cache:
                    search_results = await _cached_google_search(expanded)

    # ── Step 3: Build prompt ──────────────────────────────────────────────────
    prompt = build_prompt(query, search_results, include_followups=True)

    # Only add history for non-greeting queries to save tokens
    if history and not is_greeting:
        history_context = "\n".join(
            f"Q: {h.get('query', '')[:60]} A: {h.get('answer', '')[:80]}"
            for h in history
        )
        prompt = f"Context from previous questions:\n{history_context}\n\n{prompt}"

    # ── Step 4: AI generation ─────────────────────────────────────────────────
    answer, followups = await run_in_threadpool(generate_answer_and_followups, prompt)

    # ── Step 5: Cache + non-blocking DB save ──────────────────────────────────
    ai_cache.save_response(query, answer, search_results[:3], followups)

    asyncio.create_task(
        save_chat_message(
            user_id=user_id,
            query=query,
            answer=answer,
            sources=search_results[:3],
        )
    )

    increment_today_count(user_id)

    sources = [
        Source(title=r["title"], link=r["link"])
        for r in search_results[:3]
    ]
    return answer, sources, followups