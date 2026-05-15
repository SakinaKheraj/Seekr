import firebase_admin
from firebase_admin import firestore
from datetime import datetime, timezone, date
from typing import List, Dict, Any
from fastapi.concurrency import run_in_threadpool
from server.services.llm_service import generate_session_title

# ── In-memory daily message counter ──────────────────────────────────────────
# Prevents hitting Firestore on every single chat request just to check the
# daily quota. Resets automatically when the date changes.
_daily_counts: Dict[str, Dict] = {}  # {user_id: {"count": int, "date": date}}


def get_firestore_client():
    try:
        return firestore.client()
    except:
        raise Exception("Firebase Admin SDK not initialized")


# ── Daily count helpers ───────────────────────────────────────────────────────

def _get_in_memory_count(user_id: str) -> int | None:
    """Returns today's count from memory, or None if not yet loaded."""
    entry = _daily_counts.get(user_id)
    if entry and entry["date"] == date.today():
        return entry["count"]
    return None


def _set_in_memory_count(user_id: str, count: int):
    """Sets the in-memory count for today."""
    _daily_counts[user_id] = {"count": count, "date": date.today()}


def increment_today_count(user_id: str):
    """Increments the in-memory daily counter without touching Firestore."""
    entry = _daily_counts.get(user_id)
    if entry and entry["date"] == date.today():
        entry["count"] += 1
    else:
        # No entry yet for today — initialize at 1
        _set_in_memory_count(user_id, 1)


# ── Session management ────────────────────────────────────────────────────────

def get_or_create_active_session(user_id: str):
    """
    Checks for an existing session that hasn't expired (30 min).
    Returns (session_id, is_new_session).
    """
    db = get_firestore_client()
    docs = (
        db.collection("chats")
        .where(filter=firestore.FieldFilter("user_id", "==", user_id))
        .order_by("timestamp", direction=firestore.Query.DESCENDING)
        .limit(1)
        .get()
    )

    for doc in docs:
        data = doc.to_dict()
        last_ts = data.get("timestamp")

        if last_ts:
            now = datetime.now(timezone.utc)
            if (now - last_ts).total_seconds() > 1800:  # 30 mins → new session
                break

        return data["session_id"], False

    # No previous session or session expired → create new
    new_sid = f"session_{user_id}_{int(datetime.now().timestamp())}"
    return new_sid, True


# ── Chat persistence ──────────────────────────────────────────────────────────

def save_chat_sync(
    user_id: str,
    query: str,
    answer: str,
    sources: List[Dict]
):
    db = get_firestore_client()
    session_id, is_new_session = get_or_create_active_session(user_id)

    # Generate title only once per session — saves an LLM call on every message
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

    try:
        # Optimized query — requires Firestore composite index
        query = (
            db.collection("chats")
            .where(filter=firestore.FieldFilter("user_id", "==", user_id))
            .order_by("timestamp", direction=firestore.Query.DESCENDING)
        )
        if limit:
            query = query.limit(limit)

        docs = query.stream()
        return [{"id": doc.id, **doc.to_dict()} for doc in docs]

    except Exception as e:
        # Fallback: sort in memory if index is missing
        print(f" INFO: History falling back to memory sort. Error: {str(e)}")
        docs = (
            db.collection("chats")
            .where(filter=firestore.FieldFilter("user_id", "==", user_id))
            .stream()
        )
        msgs = [{"id": doc.id, **doc.to_dict()} for doc in docs]
        msgs.sort(
            key=lambda x: x.get("timestamp") or datetime.min.replace(tzinfo=timezone.utc),
            reverse=True
        )
        return msgs[:limit] if limit else msgs


# ── Async wrappers ────────────────────────────────────────────────────────────

async def save_chat_message(
    user_id: str,
    query: str,
    answer: str,
    sources: List[Dict]
):
    await run_in_threadpool(save_chat_sync, user_id, query, answer, sources)


async def get_session_history(user_id: str, limit: int = 10):
    return await run_in_threadpool(get_history_sync, user_id, limit)


async def clear_user_history(user_id: str):
    """Deletes all chat messages for a user."""
    def delete_all():
        db = get_firestore_client()
        docs = (
            db.collection("chats")
            .where(filter=firestore.FieldFilter("user_id", "==", user_id))
            .stream()
        )
        for doc in docs:
            doc.reference.delete()
        # Reset in-memory counter on history clear
        _daily_counts.pop(user_id, None)

    await run_in_threadpool(delete_all)


async def get_session_messages(user_id: str, session_id: str):
    """Fetch all messages for a specific session, ordered by time."""
    def get_messages():
        db = get_firestore_client()
        try:
            docs = (
                db.collection("chats")
                .where(filter=firestore.FieldFilter("user_id", "==", user_id))
                .where(filter=firestore.FieldFilter("session_id", "==", session_id))
                .order_by("timestamp", direction=firestore.Query.ASCENDING)
                .stream()
            )
            return [{"id": doc.id, **doc.to_dict()} for doc in docs]
        except Exception as e:
            print(f" INFO: Session detail falling back to memory sort. Error: {str(e)}")
            docs = (
                db.collection("chats")
                .where(filter=firestore.FieldFilter("user_id", "==", user_id))
                .where(filter=firestore.FieldFilter("session_id", "==", session_id))
                .stream()
            )
            msgs = [{"id": doc.id, **doc.to_dict()} for doc in docs]
            msgs.sort(
                key=lambda x: x.get("timestamp") or datetime.min.replace(tzinfo=timezone.utc)
            )
            return msgs

    return await run_in_threadpool(get_messages)


async def get_user_sessions(user_id: str, limit: int = 10):
    """Aggregates chat messages into sessions for the history screen.
    Capped at 100 documents to avoid expensive Firestore reads.
    """
    history = await get_session_history(user_id, limit=100)  # was 1000 — reduced

    sessions: Dict[str, Dict] = {}
    for chat in history:
        sid = chat.get("session_id")
        if not sid:
            continue

        if sid not in sessions:
            title = chat.get("session_title") or (chat.get("query", "")[:80] + "...")
            sessions[sid] = {
                "session_id": sid,
                "last_message": title,
                "timestamp": chat.get("created_at") or chat.get("timestamp"),
                "message_count": 0,
                "source_count": 0,
            }

        if chat.get("query") or chat.get("answer"):
            sessions[sid]["message_count"] += 1
            sessions[sid]["source_count"] += len(chat.get("sources") or [])

    return list(sessions.values())[:limit]


async def count_today_messages(user_id: str) -> int:
    """Count how many messages the user has sent today.

    Uses in-memory counter first to avoid Firestore reads on every request.
    Only falls back to Firestore on first request of the day.
    """
    # Fast path — in-memory counter
    cached = _get_in_memory_count(user_id)
    if cached is not None:
        return cached

    # Slow path — query Firestore once per day per user
    db = get_firestore_client()
    today_start = datetime.now(timezone.utc).replace(
        hour=0, minute=0, second=0, microsecond=0
    )

    try:
        query = (
            db.collection("chats")
            .where(filter=firestore.FieldFilter("user_id", "==", user_id))
            .where(filter=firestore.FieldFilter("timestamp", ">=", today_start))
        )
        results = query.count().get()
        count = results[0][0].value

    except Exception as e:
        print(f" INFO: Count index missing, using fallback. Error: {str(e)}")
        docs = (
            db.collection("chats")
            .where(filter=firestore.FieldFilter("user_id", "==", user_id))
            .stream()
        )
        count = sum(
            1 for doc in docs
            if (ts := doc.to_dict().get("timestamp")) and ts >= today_start
        )

    # Cache the result in memory for the rest of the day
    _set_in_memory_count(user_id, count)
    return count