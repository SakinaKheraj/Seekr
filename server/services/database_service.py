import firebase_admin
from firebase_admin import firestore
from datetime import datetime
from typing import Optional, List, Dict, Any
from fastapi.concurrency import run_in_threadpool

def get_db():
    """Safe Firestore client - only call AFTER firebase_config runs"""
    return firestore.client()


def get_firestore_client():
    """Safe Firestore client - works after firebase_config initializes"""
    try:
        return firestore.client()
    except:
        raise Exception("Firebase Admin SDK not initialized. Check firebase_config.py")

def save_chat_sync(user_id: str, session_id: Optional[str], query: str, answer: str, sources: List[Dict]):
    """Save chat message synchronously (threadpool)"""
    db = get_firestore_client()
    
    doc_data = {
        "user_id": user_id,
        "session_id": session_id or f"session_{user_id}_{int(datetime.now().timestamp())}",
        "query": query,
        "answer": answer,
        "sources": sources,
        "timestamp": firestore.SERVER_TIMESTAMP,
        "created_at": datetime.utcnow().isoformat()
    }
    
    db.collection("chats").add(doc_data)
    return doc_data["session_id"]

def get_history_sync(
    user_id: str,
    session_id: Optional[str] = None,
    limit: int = 10
):
    db = get_firestore_client()

    query = db.collection("chats").where("user_id", "==", user_id)

    if session_id:
        query = query.where("session_id", "==", session_id)

    docs = query.limit(limit).stream()

    history = [{"id": doc.id, **doc.to_dict()} for doc in docs]
    return history


async def save_chat_message(
    user_id: str,
    session_id: Optional[str],
    query: str,
    answer: str,
    sources: List[Dict]
) -> str:
    """Async wrapper for saving chat"""
    return await run_in_threadpool(
        save_chat_sync, user_id, session_id, query, answer, sources
    )

async def get_session_history(
    user_id: str,
    session_id: Optional[str] = None,
    limit: int = 10
) -> List[Dict]:
    """Async wrapper for getting session history"""
    return await run_in_threadpool(
        get_history_sync, user_id, session_id, limit
    )

async def get_user_sessions(user_id: str, limit: int = 10) -> List[Dict]:
    """Get distinct sessions for user"""
    history = await get_session_history(user_id, limit=50)
    sessions = {}
    for chat in history:
        sid = chat["session_id"]
        if sid not in sessions:
            sessions[sid] = {
                "session_id": sid,
                "last_message": chat["query"][:50] + "...",
                "timestamp": chat["created_at"]
            }
    return list(sessions.values())[:limit]

if __name__ == "__main__":
    """Test functions locally"""
    print("Firestore service ready!")
