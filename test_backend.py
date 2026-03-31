import asyncio
from server.services.database_service import get_or_create_active_session, save_chat_sync

def test_db():
    print("Testing DB connection...")
    session_id, is_new = get_or_create_active_session("test_user_123")
    print(f"Session ID: {session_id}, New: {is_new}")
    
    
from server.services.llm_service import generate_session_title, generate_followups

def test_llm():
    print("Testing LLM generation...")
    title = generate_session_title("What is the capital of France?")
    print(f"Title: {title}")
    
    followups = generate_followups("What is the capital of France?", "The capital of France is Paris.")
    print(f"Followups: {followups}")
    
if __name__ == "__main__":
    try:
        from server.services.firebase_config import initialize_firebase
        initialize_firebase()
    except Exception as e:
        print("Firebase init error (may already be initialized):", e)
        pass
        
    test_db()
    test_llm()
    print("All tests passed.")
