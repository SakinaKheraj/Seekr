import firebase_admin
from firebase_admin import firestore
from datetime import datetime, timezone, date
from typing import List, Dict
from fastapi.concurrency import run_in_threadpool


def get_firestore_client():
    try:
        return firestore.client()
    except:
        raise Exception("Firebase Admin SDK not initialized")


# 🔑 BACKEND-MANAGED SESSION
def get_or_create_active_session(user_id: str) -> str:
    db = get_firestore_client()

    docs = (
        db.collection("chats")
        .where("user_id", "==", user_id)
        .order_by("timestamp", direction=firestore.Query.DESCENDING)
        .limit(1)
        .stream()
    )

    for doc in docs:
        return doc.to_dict()["session_id"]

    # no previous session → create new
    return f"session_{user_id}_{int(datetime.now().timestamp())}"


def save_chat_sync(
    user_id: str,
    query: str,
    answer: str,
    sources: List[Dict]
):
    db = get_firestore_client()
    session_id = get_or_create_active_session(user_id)

    doc_data = {
        "user_id": user_id,
        "session_id": session_id,
        "query": query,
        "answer": answer,
        "sources": sources,
        "timestamp": firestore.SERVER_TIMESTAMP,
        # Store an ISO timestamp with timezone so string parsing + comparisons are consistent.
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    db.collection("chats").add(doc_data)


def get_history_sync(user_id: str, limit: int = 10):
    db = get_firestore_client()

    query = (
        db.collection("chats")
        .where("user_id", "==", user_id)
        .order_by("timestamp", direction=firestore.Query.DESCENDING)
    )

    if limit:
        query = query.limit(limit)

    docs = query.stream()

    return [{"id": doc.id, **doc.to_dict()} for doc in docs]


# ---------------- ASYNC WRAPPERS ---------------- #

async def save_chat_message(
    user_id: str,
    query: str,
    answer: str,
    sources: List[Dict]
):
    await run_in_threadpool(
        save_chat_sync, user_id, query, answer, sources
    )


async def get_session_history(user_id: str, limit: int = 10):
    return await run_in_threadpool(get_history_sync, user_id, limit)


async def get_user_sessions(user_id: str, limit: int = 10):
    # fetch a large slice of history to approximate "all"
    history = await get_session_history(user_id, limit=1000)

    sessions: Dict[str, Dict] = {}
    for chat in history:
        sid = chat["session_id"]
        if sid not in sessions:
            sessions[sid] = {
                "session_id": sid,
                "last_message": chat["query"][:80] + "...",
                "timestamp": chat.get("created_at"),
                "message_count": 0,
                "source_count": 0,
            }

        sessions[sid]["message_count"] += 1
        sources = chat.get("sources") or []
        sessions[sid]["source_count"] += len(sources)

    return list(sessions.values())[:limit]


async def count_today_messages(user_id: str) -> int:
    """Count how many chat messages the user has sent today (UTC).

    Uses stored `created_at` ISO string for compatibility with existing docs.
    """
    history = await get_session_history(user_id, limit=1000)
    today_utc = datetime.now(timezone.utc).date()

    count = 0
    for h in history:
        created_at = h.get("created_at")
        if not created_at:
            continue
        try:
            # Handle both "2026-01-28T..." and "2026-01-28T...+00:00"
            dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            if dt.astimezone(timezone.utc).date() == today_utc:
                count += 1
        except Exception:
            continue

    return count
