from typing import List, Dict, Any
from datetime import datetime, timezone
from firebase_admin import firestore
from server.services.database_service import get_firestore_client
from server.pydantic_models.chat_body import Source

def save_bookmark_sync(
    user_id: str,
    folder_name: str,
    query: str,
    answer: str,
    sources: List[Dict[str, Any]]
) -> str:
    db = get_firestore_client()
    
    doc_data = {
        "user_id": user_id,
        "folder_name": folder_name,
        "query": query,
        "answer": answer,
        "sources": sources,
        "timestamp": firestore.SERVER_TIMESTAMP,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    
    result = db.collection("bookmarks").add(doc_data)
    if isinstance(result, tuple):
        _, doc_ref = result
    else:
        doc_ref = result
    return doc_ref.id


def get_collections_sync(user_id: str) -> Dict[str, List[Dict[str, Any]]]:
    db = get_firestore_client()
    
    docs = (
        db.collection("bookmarks")
        .where("user_id", "==", user_id)
        .stream()
    )
    
    all_docs = []
    for doc in docs:
        d = doc.to_dict()
        d["id"] = doc.id
        all_docs.append(d)
        
    # Sort locally to avoid needing a Firestore composite index
    all_docs.sort(key=lambda x: x.get("created_at") or "", reverse=True)
    
    folders: Dict[str, List[Dict[str, Any]]] = {}
    
    for data in all_docs:
        folder_name = data.get("folder_name", "Uncategorized")
        
        created_at = data.get("created_at", "")
        if hasattr(created_at, "isoformat"):
            created_at = created_at.isoformat()
        
        sources = data.get("sources", [])
        if not isinstance(sources, list):
            sources = []
        
        item = {
            "id": doc.id,
            "query": str(data.get("query", "")),
            "answer": str(data.get("answer", "")),
            "sources": sources,
            "created_at": str(created_at)
        }
        
        if folder_name not in folders:
            folders[folder_name] = []
        folders[folder_name].append(item)
        
    return folders


def delete_bookmark_sync(user_id: str, bookmark_id: str):
    db = get_firestore_client()
    # verify ownership before deleting
    doc_ref = db.collection("bookmarks").document(bookmark_id)
    doc = doc_ref.get()
    
    if doc.exists and doc.to_dict().get("user_id") == user_id:
        doc_ref.delete()
    else:
        raise Exception("Bookmark not found or unauthorized")
