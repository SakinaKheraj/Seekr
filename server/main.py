# import os
from fastapi import FastAPI, Depends, HTTPException
from server.services import firebase_config
from server.services.firebase_auth_service import verify_firebase_token
from server.pydantic_models.chat_body import ChatRequest, Source
from server.pydantic_models.chat_response import ChatResponse
from server.services.search_service import google_search
from server.pydantic_models.search_models import (
    SearchRequest, SearchResponse
)
from server.services.llm_service import generate_ai_response, build_prompt
from server.pydantic_models.llm_models import LLMRequest, LLMResponse
from fastapi.concurrency import run_in_threadpool
from server.services.chat_service import chat_with_search
from server.services.database_service import (
    save_chat_message,
    get_user_sessions,
    get_session_history,
    count_today_messages,
)

app = FastAPI(title='SeekrAI')
firebase_config.initialize_firebase()

@app.get('/health')
def health():
    return {'status' : 'healthy'}

@app.post('/chat', response_model=ChatResponse)
async def chat(
    body: ChatRequest,
    user = Depends(verify_firebase_token)
):
    try:
        # enforce daily question limit (10 per day)
        today_count = await count_today_messages(user["uid"])
        if today_count >= 10:
            raise HTTPException(
                status_code=429,
                detail="Daily question limit (10) reached. Try again tomorrow.",
            )

        answer, sources = await chat_with_search(
            body.query,
            user["uid"]
        )

        return ChatResponse(
            answer=answer,
            sources=sources,
            user_id=user["uid"]
        )

    except Exception as e:
        print("CHAT ERROR:", e)  # TEMP DEBUG
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    
@app.post("/search", response_model=SearchResponse)
async def search(
    body: SearchRequest,
    user = Depends(verify_firebase_token)
):
    results = await google_search(body.query)
    return {"results": results}

@app.post('/llm', response_model=LLMResponse)
async def llm(
    body: LLMRequest,
    user = Depends(verify_firebase_token)
):
    answer = await run_in_threadpool(
        generate_ai_response,
        body.prompt
    )
    return {"answer": answer}


@app.get("/history")
async def history(limit: int = 1000, user=Depends(verify_firebase_token)):
    try:
        sessions = await get_user_sessions(user["uid"], limit=limit)
        return sessions
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


@app.get("/stats")
async def stats(user=Depends(verify_firebase_token)):
    try:
        # fixed daily quota of 10 questions
        total_sessions = 10
        used_sessions = await count_today_messages(user["uid"])

        return {
            "name": user.get("name") or user.get("email", ""),
            "email": user.get("email", ""),
            "total_sessions": total_sessions,
            "used_sessions": used_sessions,
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )
