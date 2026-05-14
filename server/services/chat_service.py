import asyncio
from fastapi.concurrency import run_in_threadpool
from server.services.search_service import google_search
from server.services.llm_service import (
    generate_ai_response, 
    build_prompt, 
    generate_answer_and_followups
)
from server.services.database_service import (
    save_chat_message,
    get_session_history
)
from server.pydantic_models.chat_body import Source
from server.services.cache_service import ai_cache


async def chat_with_search(query: str, user_id: str):
    # 0. Check the lightweight Memory Cache first!
    cached_data = ai_cache.get_cached_response(query)
    if cached_data:
        print(f" 🚀 [CACHE HIT] Delivered response for '{query[:20]}...' instantly. Saved 1 API Call!")
        # We still save it to the DB so user sees it in History
        asyncio.create_task(
            save_chat_message(
                user_id=user_id,
                query=query,
                answer=cached_data["answer"],
                sources=cached_data["sources"],
            )
        )
        sources = [
            Source(title=r["title"], link=r["link"])
            for r in cached_data["sources"]
        ]
        return cached_data["answer"], sources, cached_data["followups"]

    # 1. Fetch recent history (backend-managed session)
    history = await get_session_history(user_id, limit=3)

    # Optimization: Greetings detection to save Search & AI quota
    greetings = {"hi", "hello", "hey", "how are you", "who are you", "good morning", "good evening", "thanks", "thank you"}
    clean_query = query.lower().strip().strip("?!.")
    
    is_greeting = clean_query in greetings or len(clean_query.split()) < 2
    
    search_query = query
    search_results = []
    
    if not is_greeting:
        # Contextual Query Expansion
        if history and len(query.split()) < 5:
            last_topic = history[0]['query']
            search_query = f"{query} regarding {last_topic}"

        search_results = await google_search(search_query)

    # Optimization: One prompt for both answer and followups
    prompt = build_prompt(query, search_results, include_followups=True)

    if history:
        prompt = (
            "Previous chats:\n"
            + "\n".join(
                [f"Q: {h['query']} A: {h['answer'][:100]}..." for h in history]
            )
            + "\n\n"
            + prompt
        )

    # Combined generation: Answer + 3 Followups
    answer, followups = await run_in_threadpool(generate_answer_and_followups, prompt)

    # Save to global RAM cache to prevent duplicate processing in the future
    ai_cache.save_response(query, answer, search_results[:3], followups)

    # Save to database (fire and forget task for saving, while we return results)
    asyncio.create_task(
        save_chat_message(
            user_id=user_id,
            query=query,
            answer=answer,
            sources=search_results[:3],
        )
    )

    sources = [
        Source(title=r["title"], link=r["link"])
        for r in search_results[:3]
    ]

    return answer, sources, followups

    