import firebase_admin
from firebase_admin import firestore
from datetime import datetime, timezone, date
from typing import List, Dict, Tuple
from fastapi.concurrency import run_in_threadpool
from server.services.llm_service import generate_session_title


def get_firestore_client():
    try:
        return firestore.client()
    except:
        raise Exception("Firebase Admin SDK not initialized")


#  BACKEND-MANAGED SESSION
def get_or_create_active_session(user_id: str) -> Tuple[str, bool]:
    """Returns (session_id, is_new_session)."""
    db = get_firestore_client()

    docs = (
        db.collection("chats")
        .where("user_id", "==", user_id)
        .order_by("timestamp", direction=firestore.Query.DESCENDING)
        .limit(1)
        .stream()
    )

    for doc in docs:
        return doc.to_dict()["session_id"], False

    # no previous session → create new
    return f"session_{user_id}_{int(datetime.now().timestamp())}", True


def save_chat_sync(
    user_id: str,
    query: str,
    answer: str,
    sources: List[Dict]
):
    db = get_firestore_client()
    session_id, is_new_session = get_or_create_active_session(user_id)

    # Generate a human-readable title only once, when the session is first created
    session_title = generate_session_title(query) if is_new_session else None

    doc_data = {
        "user_id": user_id,
        "session_id": session_id,
        "query": query,
        "answer": answer,
        "sources": sources,
        "timestamp": firestore.SERVER_TIMESTAMP,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    if session_title:
        doc_data["session_title"] = session_title

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
            # Prefer the stored Gemini-generated title; fall back to truncated query
            title = chat.get("session_title") or (chat["query"][:80] + "...")
            sessions[sid] = {
                "session_id": sid,
                "last_message": title,
                "timestamp": chat.get("created_at"),
                "message_count": 0,
                "source_count": 0,
            }
        elif chat.get("session_title") and not sessions[sid]["last_message"]:
            # pick up the title from any msg in the session that has it
            sessions[sid]["last_message"] = chat["session_title"]

        sessions[sid]["message_count"] += 1
        sources = chat.get("sources") or []
        sessions[sid]["source_count"] += len(sources)

    return list(sessions.values())[:limit]


async def count_today_messages(user_id: str) -> int:
    """Count how many chat messages the user has sent today (UTC) using a targeted query.
    
    This is much more efficient than fetching the full history.
    """
    db = get_firestore_client()
    # Get the start of the current day in UTC
    today_start = datetime.now(timezone.utc).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    
    # Query for documents created today
    query = (
        db.collection("chats")
        .where("user_id", "==", user_id)
        .where("timestamp", ">=", today_start)
    )
    
    # Use count() aggregation for maximum efficiency (supported in newer firebase-admin)
    try:
        # Note: count() might require an index on (user_id, timestamp)
        count_query = query.count()
        results = count_query.get()
        return results[0][0].value
    except Exception:
        # Fallback if count() is not available or index missing
        docs = query.stream()
        return sum(1 for _ in docs)

