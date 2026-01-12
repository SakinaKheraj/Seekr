from fastapi import FastAPI

app = FastAPI(title='SeekrAI')

@app.get('/health')
def health():
    return {'status' : 'healthy'}