import google.generativeai as genai
from server.config import GEMINI_API_KEY

genai.configure(api_key=GEMINI_API_KEY)

MODELS_TO_TRY = [
    'gemini-2.5-flash',   # Original working model
    'gemini-2.0-flash',   # Fallback 1
    'gemini-1.5-flash',   # Fallback 2
]


def generate_ai_response(prompt: str) -> str:
    last_error_info = []

    for model_name in MODELS_TO_TRY:
        try:
            print(f" TRACK: Attempting AI response with {model_name}...")
            model = genai.GenerativeModel(model_name)
            response = model.generate_content(prompt)

            if not response or not response.candidates:
                msg = f"{model_name}: no candidates returned."
                print(f"⚠️ {msg}")
                last_error_info.append(msg)
                continue

            candidate = response.candidates[0]
            finish_reason = str(getattr(candidate, 'finish_reason', ''))

            # STOP = success
            if finish_reason not in ('FinishReason.STOP', 'STOP', '1'):
                msg = f"{model_name}: blocked/incomplete. Reason: {finish_reason}"
                print(f"⚠️ {msg}")
                last_error_info.append(msg)
                continue

            try:
                text = response.text
                if text:
                    print(f"✅ SUCCESS with {model_name}")
                    return text
            except Exception as e:
                msg = f"{model_name}: text extraction failed: {str(e)}"
                print(f"⚠️ {msg}")
                last_error_info.append(msg)
                continue

        except Exception as e:
            msg = f"{model_name} error: {str(e)}"
            print(f"❌ {msg}")
            last_error_info.append(msg)
            continue

    error_summary = "\n".join(last_error_info)
    raise Exception(f"All AI models failed.\n{error_summary}")


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

Answer in simple, friendly language. Do NOT mention or cite source numbers.
"""
    return prompt
