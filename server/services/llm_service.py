import json
import time
import google.generativeai as genai
from server.config import GEMINI_API_KEY
from typing import List
from datetime import datetime

genai.configure(api_key=GEMINI_API_KEY)

# ── Model fallback order ──────────────────────────────────────────────────────
# Ordered by free-tier daily quota (highest first).
# gemini-2.0-flash:      active primary
# gemini-2.0-flash-lite: solid lightweight fallback
# gemini-2.5-flash:      high quality fallback
# gemini-2.5-flash-lite: backup fallback
# gemini-3.1-flash-lite: latest flash-lite fallback
# (Older 1.5-flash and 1.0-pro have been deprecated and return 404)
MODELS_TO_TRY = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-3.1-flash-lite',
]

# ── Shared generation logic ───────────────────────────────────────────────────

def _call_model(prompt: str) -> str:
    """
    Tries each model in fallback order and returns the raw text response.
    Raises a clear exception on quota exhaustion or total failure.
    Extracted to avoid duplicating the retry loop in every function.
    """
    last_errors = []

    for model_name in MODELS_TO_TRY:
        try:
            print(f" [LLM] Trying {model_name}...")
            model = genai.GenerativeModel(model_name)
            response = model.generate_content(prompt)

            if not response or not response.candidates:
                last_errors.append(f"{model_name}: no candidates returned.")
                continue

            candidate = response.candidates[0]
            finish_reason = str(getattr(candidate, 'finish_reason', ''))

            if candidate.finish_reason == 3:  # SAFETY block
                last_errors.append(f"{model_name}: blocked by safety filters.")
                continue

            if finish_reason not in ('FinishReason.STOP', 'STOP', '1'):
                last_errors.append(f"{model_name}: incomplete. Reason: {finish_reason}")
                continue

            text = response.text
            if text:
                print(f" [LLM] Success with {model_name}")
                return text

        except Exception as e:
            msg = f"{model_name}: {str(e)}"
            last_errors.append(msg)
            print(f" [LLM] {msg}")
            continue

    summary = "\n".join(last_errors)
    
    # 1. Check for limit: 0 or key validation issues
    if "limit: 0" in summary or "billing details" in summary.lower() or "check your plan" in summary.lower():
        raise Exception(
            "AI service is temporarily unavailable. Please try again later."
        )
        
    # 2. Check for temporary Rate Limit (RPM/TPM) vs Daily Quota (RPD)
    if "429" in summary or "quota" in summary.lower():
        if "perminute" in summary.lower() or "tokens" in summary.lower() or "rate" in summary.lower():
            raise Exception(
                "Rate limit reached. Please wait 60 seconds and try again."
            )
        raise Exception(
            "Daily service limit reached. Please try again tomorrow."
        )
        
    raise Exception("All AI models failed to respond. Please check your network connection and try again.")


# ── Public API ────────────────────────────────────────────────────────────────

def generate_ai_response(prompt: str) -> str:
    """Simple text generation — used for drafts and direct LLM calls."""
    return _call_model(prompt)


def build_prompt(query: str, search_results: list, include_followups: bool = False) -> str:
    context = ""
    for i, r in enumerate(search_results[:3], start=1):
        snippet = r.get('snippet', '')[:200]
        context += f"[{i}] {r['title']}: {snippet} ({r['link']})\n"

    current_date = datetime.now().strftime("%B %d, %Y")

    prompt = f"""You are Seekr, a knowledgeable and friendly AI assistant.
Today's date is {current_date}. You are operating in real-time.

Answer the question directly and confidently using the search results below as your primary source of truth.

Critical rules:
- The search results reflect CURRENT, REAL information as of today
- Always trust the search results over your training knowledge for recent events
- NEVER say information is unavailable for a year that has already happened
- NEVER say "the provided sources", "based on the sources" or reveal you use search
- Be direct, confident, and helpful

Question: {query}

Reference material:
{context}"""

    if include_followups:
        prompt += """

Reply ONLY with this exact JSON — no markdown, no extra text:
{"answer": "your answer here", "followups": ["question 1?", "question 2?", "question 3?"]}

Rules for followups:
- Generate 3 questions the user might want to ask NEXT about this TOPIC
- Questions must be ABOUT THE SUBJECT, never about the user's personal preferences
- Never ask "what is your budget", "what do you prefer", "what's your favorite"
- Good: "How does X compare to Y?", "What are the main use cases of X?"
- Bad: "What's your preferred X?", "What's your budget?"
- Keep questions short (under 10 words)"""

    return prompt


def generate_answer_and_followups(prompt: str) -> tuple[str, List[str]]:
    """
    Single API call that returns both the answer and 3 follow-up questions.
    Parses the JSON response and falls back gracefully if JSON is malformed.
    """
    raw = _call_model(prompt)

    try:
        # Strip markdown code fences if model ignores the instruction
        clean = raw.strip()
        if clean.startswith("```json"):
            clean = clean.split("```json", 1)[-1].split("```")[0].strip()
        elif clean.startswith("```"):
            clean = clean.split("```", 1)[-1].split("```")[0].strip()

        # First attempt: direct parse
        try:
            payload = json.loads(clean)
        except json.JSONDecodeError:
            # Second attempt: fix unescaped newlines inside JSON string values
            import re
            fixed = re.sub(r'(?<=": ")(.*?)(?="[,\s]*"followups")', 
                          lambda m: m.group(0).replace('\n', '\\n').replace('\r', '\\r'), 
                          clean, flags=re.DOTALL)
            try:
                payload = json.loads(fixed)
            except json.JSONDecodeError:
                # Third attempt: regex extraction
                answer_match = re.search(r'"answer"\s*:\s*"(.*?)"(?:\s*,\s*"followups")', clean, re.DOTALL)
                followup_match = re.search(r'"followups"\s*:\s*\[(.*?)\]', clean, re.DOTALL)
                
                if answer_match:
                    answer = answer_match.group(1).replace('\\n', '\n').replace('\\"', '"')
                    followups = []
                    if followup_match:
                        followups = re.findall(r'"([^"]+)"', followup_match.group(1))
                    while len(followups) < 3:
                        followups.append("")
                    print(f" [LLM] Regex extraction successful.")
                    return answer.strip(), followups[:3]
                
                raise  # re-raise if regex also failed

        answer = payload.get("answer", "").strip()
        followups = payload.get("followups", [])

        # Ensure exactly 3 follow-ups
        while len(followups) < 3:
            followups.append("")

        print(f" [LLM] JSON batch payload parsed successfully.")
        return answer, followups[:3]

    except json.JSONDecodeError:
        # Final fallback — return raw text as answer with no follow-ups
        print(f" [LLM] JSON parse failed, returning raw text as answer.")
        return raw, ["", "", ""]


def generate_session_title(first_query: str) -> str:
    """
    Generates a human-readable session title from the first query.
    Pure string operation — no AI call, zero quota cost.
    """
    words = first_query.split()
    title = " ".join(words[:6])
    if len(words) > 6:
        title += "..."
    return title[:1].upper() + title[1:] if title else "New Session"


def generate_draft(text: str, format: str) -> str:
    """Transforms research content into a specific professional format."""
    templates = {
        "email": f"Write a professional email based on this information. Include a subject line, greeting, structured body, and sign-off. Keep it concise. Information: {text}",
        "linkedin": f"Write an engaging LinkedIn post based on this information. Use a strong hook, emojis, and 3-5 relevant hashtags. Information: {text}",
        "markdown": f"Format this information as a clean Markdown report with headers, bullet points, and clear structure. Information: {text}",
        "summary": f"Write a concise executive summary of this information in 3-5 high-impact bullet points. Information: {text}",
    }
    prompt = templates.get(format, templates["summary"])
    return generate_ai_response(prompt)