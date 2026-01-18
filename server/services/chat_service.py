from server.services.search_service import google_search
from server.services.llm_service import generate_ai_response, build_prompt
from server.pydantic_models.chat_body import Source

async def chat_with_search(query: str):
    search_results = await google_search(query)
    prompt = build_prompt(query, search_results)  # Fixed variable name
    answer = generate_ai_response(prompt)  # Fixed: pass prompt variable
    
    sources = [
        Source(title=r["title"], link=r["link"])
        for r in search_results[:3]  # Limit to top 3
    ]
    
    return answer, sources
