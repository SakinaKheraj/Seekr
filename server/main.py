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
from server.services.database_service import save_chat_message

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
        answer, sources, session_id = await chat_with_search(
            body.query,
            body.session_id,
            user["uid"]
        )

        return ChatResponse(
            answer=answer,
            sources=sources,
            user_id=user["uid"]
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail="Something went wrong while processing your request"
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
