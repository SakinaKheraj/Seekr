import asyncio
from fastapi.concurrency import run_in_threadpool
from server.services.search_service import google_search
from server.services.llm_service import generate_ai_response, build_prompt, generate_followups
from server.services.database_service import (
    save_chat_message,
    get_session_history
)
from server.pydantic_models.chat_body import Source


async def chat_with_search(query: str, user_id: str):
    # Fetch recent history (backend-managed session)
    history = await get_session_history(user_id, limit=3)

    search_results = await google_search(query)
    prompt = build_prompt(query, search_results)

    if history:
        prompt = (
            "Previous chats:\n"
            + "\n".join(
                [f"Q: {h['query']} A: {h['answer'][:100]}..." for h in history]
            )
            + "\n\n"
            + prompt
        )

    # Run the initial Gemini generation in a thread so it doesn't block the API
    answer = await run_in_threadpool(generate_ai_response, prompt)

    async def get_followups():
        try:
            return await run_in_threadpool(generate_followups, query, answer)
        except Exception as e:
            print("Followup Gen Error:", e)
            return []

    # Run followup generation and database saving simultaneously to cut latency in half
    task_followups = asyncio.create_task(get_followups())
    task_save = asyncio.create_task(
        save_chat_message(
            user_id=user_id,
            query=query,
            answer=answer,
            sources=search_results[:3],
        )
    )

    followups, _ = await asyncio.gather(task_followups, task_save)

    sources = [
        Source(title=r["title"], link=r["link"])
        for r in search_results[:3]
    ]

    return answer, sources, followups
