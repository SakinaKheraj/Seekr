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
        
        # 🧪 SESSION EXPIRY: If last message was > 30 mins ago, start NEW session.
        if last_ts:
            # Firestore returns timezone-aware datetimes
            now = datetime.now(timezone.utc)
            if (now - last_ts).total_seconds() > 1800: # 30 mins
                break
        
        return data["session_id"], False

    # no previous session or session expired → create new
    new_sid = f"session_{user_id}_{int(datetime.now().timestamp())}"
    return new_sid, True


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
        .where(filter=firestore.FieldFilter("user_id", "==", user_id))
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


async def clear_user_history(user_id: str):
    """Deletes all chat messages for a user."""
    def delete_all():
        db = get_firestore_client()
        docs = db.collection("chats").where(filter=firestore.FieldFilter("user_id", "==", user_id)).stream()
        for doc in docs:
            doc.reference.delete()
    
    await run_in_threadpool(delete_all)


async def get_session_messages(user_id: str, session_id: str):
    """Fetch all messages for a specific session, ordered by time."""
    def get_messages():
        db = get_firestore_client()
        try:
            # 1. Try optimized query (Requires index)
            docs = (
                db.collection("chats")
                .where(filter=firestore.FieldFilter("user_id", "==", user_id))
                .where(filter=firestore.FieldFilter("session_id", "==", session_id))
                .order_by("timestamp", direction=firestore.Query.ASCENDING)
                .stream()
            )
            return [{"id": doc.id, **doc.to_dict()} for doc in docs]
        except Exception as e:
            # 2. Fallback: Query without sort and sort in memory (No index needed)
            print(f" INFO: Detail view falling back to memory sort. Error: {str(e)}")
            docs = (
                db.collection("chats")
                .where(filter=firestore.FieldFilter("user_id", "==", user_id))
                .where(filter=firestore.FieldFilter("session_id", "==", session_id))
                .stream()
            )
            msgs = [{"id": doc.id, **doc.to_dict()} for doc in docs]
            # Sort by timestamp (handling None)
            msgs.sort(key=lambda x: x.get("timestamp") or datetime.min.replace(tzinfo=timezone.utc))
            return msgs

    return await run_in_threadpool(get_messages)


async def get_user_sessions(user_id: str, limit: int = 10):
    # fetch a large slice of history to approximate "all"
    history = await get_session_history(user_id, limit=1000)

    sessions: Dict[str, Dict] = {}
    for chat in history:
        sid = chat["session_id"]
        if sid not in sessions:
            # Prefer the Gemini-generated title if available
            title = chat.get("session_title") or (chat["query"][:80] + "...")
            sessions[sid] = {
                "session_id": sid,
                "last_message": title,
                "timestamp": chat.get("created_at") or chat.get("timestamp"),
                "message_count": 0,
                "source_count": 0,
            }
        
        # Only count if it's a valid message (has query/answer)
        if chat.get("query") or chat.get("answer"):
            sessions[sid]["message_count"] += 1
            sources = chat.get("sources") or []
            sessions[sid]["source_count"] += len(sources)

    return list(sessions.values())[:limit]


async def count_today_messages(user_id: str) -> int:
    """Count how many chat messages the user has sent today (UTC).
    
    Includes a fallback for when the required composite index is not yet created.
    """
    db = get_firestore_client()
    today_start = datetime.now(timezone.utc).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    
    try:
        # 1. Attempt the optimized query (Requires Composite Index)
        query = (
            db.collection("chats")
            .where(filter=firestore.FieldFilter("user_id", "==", user_id))
            .where(filter=firestore.FieldFilter("timestamp", ">=", today_start))
        )
        
        # Try a simple count aggregation
        count_query = query.count()
        results = count_query.get()
        return results[0][0].value
        
    except Exception as e:
        # 2. Fallback: If index is missing, query by user_id ONLY and filter in memory
        # This prevents the 500 error while the index is being built.
        print(f" INFO: Index missing, using fallback filtering. Error: {str(e)}")
        
        fallback_query = (
            db.collection("chats")
            .where(filter=firestore.FieldFilter("user_id", "==", user_id))
        )
        
        docs = fallback_query.stream()
        count = 0
        for doc in docs:
            data = doc.to_dict()
            # Handle possible differences in doc structure
            ts = data.get("timestamp")
            if ts:
                # Firestore timestamps are often datetime objects in the SDK
                if ts >= today_start:
                    count += 1
        return count

