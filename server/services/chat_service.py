from server.services.search_service import google_search
from server.services.llm_service import generate_ai_response, build_prompt
from server.services.database_service import save_chat_message, get_session_history
from server.pydantic_models.chat_body import Source
from server.pydantic_models.chat_response import ChatResponse

async def chat_with_search(query: str, session_id: Optional[str], user_id: str):
    history = await get_session_history(user_id, session_id, limit=3)

    search_results = await google_search(query)
    prompt = build_prompt(query, search_results)
    if history:
        prompt = f"Previous chats:\n" + "\n".join([f"Q: {h['query']} A: {h['answer'][:100]}..." for h in history]) + "\n\n" + prompt
    
    answer = generate_ai_response(prompt)
    
    saved_session_id = await save_chat_message(user_id, session_id, query, answer, search_results[:3])
    
    sources = [Source(title=r["title"], link=r["link"]) for r in search_results[:3]]
    
    return answer, sources, saved_session_id
