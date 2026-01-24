import google.generativeai as genai
from server.config import GEMINI_API_KEY

genai.configure(api_key=GEMINI_API_KEY)

def generate_ai_response(prompt: str) -> str:
    model = genai.GenerativeModel('gemini-2.5-flash')
    response = model.generate_content(prompt)
    
    if not response.text:
        raise Exception("Empty response from Gemini")
    
    return response.text
def build_prompt(query: str, search_results: list) -> str:
    context = ""
    for i, r in enumerate(search_results[:3], start=1):
        context += f"""
Source {i}:
Title: {r['title']}
Snippet: {r.get('snippet', '')[:300]}
URL: {r['link']}
---
"""
    
    prompt = f"""
You are a helpful AI assistant.
Answer the question ONLY using the sources below.
If the answer is not present, say "I don't know".

Question: {query}

Sources:
{context}

Answer in simple language. Cite sources like [Source 1].
"""
    return prompt
