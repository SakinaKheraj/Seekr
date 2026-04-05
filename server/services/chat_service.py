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


async def chat_with_search(query: str, user_id: str):
    # Fetch recent history (backend-managed session)
    history = await get_session_history(user_id, limit=3)

    search_results = await google_search(query)
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

    