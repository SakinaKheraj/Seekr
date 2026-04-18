import google.generativeai as genai
from server.config import GEMINI_API_KEY
from typing import List

genai.configure(api_key=GEMINI_API_KEY)

MODELS_TO_TRY = [
    'gemini-2.5-flash',  
    'gemini-2.0-flash',   
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-1.5-flash-8b',
    'gemini-1.0-pro'
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
                print(f" {msg}")
                last_error_info.append(msg)
                continue

            candidate = response.candidates[0]
            finish_reason = str(getattr(candidate, 'finish_reason', ''))

            # STOP = success
            if finish_reason not in ('FinishReason.STOP', 'STOP', '1'):
                msg = f"{model_name}: blocked/incomplete. Reason: {finish_reason}"
                print(f" {msg}")
                last_error_info.append(msg)
                continue

            try:
                text = response.text
                if text:
                    print(f" SUCCESS with {model_name}")
                    return text
            except Exception as e:
                msg = f"{model_name}: text extraction failed: {str(e)}"
                print(f" {msg}")
                last_error_info.append(msg)
                continue

        except Exception as e:
            msg = f"{model_name} error: {str(e)}"
            print(f" {msg}")
            last_error_info.append(msg)
            continue

    error_summary = "\n".join(last_error_info)
    if "429" in error_summary or "quota" in error_summary.lower():
        raise Exception("API Quota Exceeded 🛑\nYou have reached the Gemini free tier limit. Please wait a minute and try again.")
    raise Exception(f"AI models failed to respond. Please try again.")


def build_prompt(query: str, search_results: list, include_followups: bool = False) -> str:
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
You are Seekr, a helpful AI assistant. 
Answer the question using the sources provided below as your primary reference.

Guidelines:
1. If the sources are relevant, use them to provide a detailed and accurate answer.
2. If the sources are irrelevant or don't fully answer the user's question (especially for follow-up questions like "give an example"), use the provided 'Previous chats' history and your own general knowledge to give a proper response.
3. Be concise, friendly, and helpful. 
4. Do NOT mention source numbers or say "Source 1 says...". Just provide the information naturally.

Question: {query}

Sources:
{context}
"""
    if include_followups:
        prompt += """
After your answer, add exactly one line: FOLLOWUP_SECTION
Then, suggest exactly 3 short follow-up questions that the user might want to ask next.
- Each question must be on a new line.
- No numbering, no bullet points, no extra text.
- Each question must be under 10 words.
"""
    return prompt


def generate_answer_and_followups(prompt: str) -> tuple[str, List[str]]:
    """Generates an AI response and extracts follow-up questions to save requests."""
    last_error_info = []

    for model_name in MODELS_TO_TRY:
        try:
            print(f" TRACK: Attempting AI response with {model_name}...")
            model = genai.GenerativeModel(model_name)
            response = model.generate_content(prompt)

            if not response or not response.candidates:
                msg = f"{model_name}: no candidates returned."
                print(f" {msg}")
                last_error_info.append(msg)
                continue

            candidate = response.candidates[0]
            if candidate.finish_reason == 3: # SAFETY
                msg = f"{model_name}: blocked by safety filters."
                print(f" {msg}")
                last_error_info.append(msg)
                continue

            try:
                full_text = response.text
                if not full_text:
                    continue

                answer = full_text
                followups = []
                
                if "FOLLOWUP_SECTION" in full_text:
                    parts = full_text.split("FOLLOWUP_SECTION")
                    answer = parts[0].strip()
                    if len(parts) > 1:
                        followups = [
                            f.strip().lstrip("-").lstrip("*").strip()
                            for f in parts[1].strip().splitlines()
                            if f.strip()
                        ][:3]

                # pad with empty strings up to 3
                while followups and len(followups) < 3:
                    followups.append("")

                print(f" SUCCESS with {model_name}")
                return answer, followups

            except Exception as e:
                msg = f"{model_name}: text extraction failed: {str(e)}"
                print(f" {msg}")
                last_error_info.append(msg)
                continue

        except Exception as e:
            msg = f"{model_name} error: {str(e)}"
            print(f" {msg}")
            last_error_info.append(msg)
            continue

    error_summary = "\n".join(last_error_info)
    if "429" in error_summary or "quota" in error_summary.lower():
        raise Exception("API Quota Exceeded 🛑\nYou have reached the Gemini free tier limit. Please wait a minute and try again.")
    raise Exception(f"AI models failed to respond. Please try again.")


def generate_session_title(first_query: str) -> str:
    """Simple non-AI title generation to save quota."""
    # Take first 6 words and capitalize
    words = first_query.split()
    title = " ".join(words[:6])
    if len(words) > 6:
        title += "..."
    # capitalize first letter
    return title[:1].upper() + title[1:] if title else "New Session"


def generate_followups(query: str, answer: str) -> List[str]:
    """Return 3 concise follow-up questions the user might want to ask next."""
    prompt = (
        f"The user just asked: {query}\n"
        f"The AI answered: {answer[:400]}\n\n"
        f"Suggest exactly 3 short follow-up questions (one per line, no numbering, "
        f"no bullet points, no extra text). Each question must be under 10 words."
    )
    for model_name in MODELS_TO_TRY:
        try:
            model = genai.GenerativeModel(model_name)
            response = model.generate_content(prompt)
            if response and response.text:
                lines = [
                    l.strip().lstrip("-").lstrip("*").strip()
                    for l in response.text.strip().splitlines()
                    if l.strip()
                ]
                # return exactly 3, pad with empty strings if needed
                questions = [q for q in lines if q][:3]
                while len(questions) < 3:
                    questions.append("")
                return questions
        except Exception:
            continue
    return []

def generate_draft(text: str, format: str) -> str:
    """Transform search results into specific professional formats."""
    templates = {
        "email": f"Draft a professional email based on this information. Include a clear subject line and a structured body with a greeting and sign-off. Information: {text}",
        "linkedin": f"Draft a highly engaging LinkedIn post based on this information. Use a scroll-stopping hook, emojis, and relevant hashtags. Information: {text}",
        "markdown": f"Format this information into a high-quality Markdown report. Use headers, bullet points, and clean structure. Information: {text}",
        "summary": f"Provide a brief, executive summary of this information in 3-5 high-impact bullet points. Information: {text}"
    }
    
    prompt = templates.get(format, templates["summary"])
    return generate_ai_response(prompt)
