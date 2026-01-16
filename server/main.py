from fastapi import FastAPI, Depends
from server.services.firebase_config import initialize_firebase
from server.services.firebase_auth_service import verify_firebase_token
from server.pydantic_models.chat_body import ChatRequest
from server.pydantic_models.chat_response import ChatResponse

app = FastAPI(title='SeekrAI')
initialize_firebase()

@app.get('/health')
def health():
    return {'status' : 'healthy'}

@app.post('/chat', response_model=ChatResponse)
def chat(
    body: ChatRequest,
    user = Depends(verify_firebase_token)
):
    return ChatResponse(
        answer=f"You asked: {body.query}",
        user_id=user["uid"]
    )