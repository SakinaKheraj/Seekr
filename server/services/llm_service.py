import json
import time
import google.generativeai as genai
from server.config import GEMINI_API_KEY
from typing import List

genai.configure(api_key=GEMINI_API_KEY)

# ── Model fallback order ──────────────────────────────────────────────────────
# Ordered by free-tier daily quota (highest first).
# gemini-2.0-flash:    1500 RPD, 15 RPM  ← primary
# gemini-1.5-flash:    1500 RPD, 15 RPM  ← solid backup
# gemini-1.5-flash-8b: 1500 RPD, 15 RPM  ← lightweight backup
# gemini-2.5-flash:     250 RPD, 10 RPM  ← quality fallback (low quota)
# gemini-1.0-pro:       limited           ← last resort
# gemini-1.5-pro EXCLUDED: only 50 RPD free — not worth a fallback slot
MODELS_TO_TRY = [
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-2.5-flash',
    'gemini-1.0-pro',
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
    if "429" in summary or "quota" in summary.lower():
        raise Exception(
            "Daily API quota reached. Please wait a few minutes and try again."
        )
    raise Exception("All AI models failed to respond. Please try again.")


# ── Public API ────────────────────────────────────────────────────────────────

def generate_ai_response(prompt: str) -> str:
    """Simple text generation — used for drafts and direct LLM calls."""
    return _call_model(prompt)


def build_prompt(query: str, search_results: list, include_followups: bool = False) -> str:
    context = ""
    for i, r in enumerate(search_results[:3], start=1):
        snippet = r.get('snippet', '')[:200]
        context += f"[{i}] {r['title']}: {snippet} ({r['link']})\n"

    prompt = f"""You are Seekr, a knowledgeable and friendly AI assistant.
Answer the question directly and confidently using your knowledge and the sources below.

Critical rules:
- NEVER say "the provided sources", "based on the sources", "the sources don't mention" or any variation of this
- NEVER reveal that you are using search results or sources
- If sources are not helpful, answer from your own knowledge naturally
- Always give a direct, confident answer — never say you don't have enough information
- Be concise, warm, and helpful

Question: {query}

Reference material:
{context}"""

    if include_followups:
        prompt += """

Reply ONLY with this exact JSON — no markdown, no extra text:
{"answer": "your answer here", "followups": ["question 1?", "question 2?", "question 3?"]}"""

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

        payload = json.loads(clean)
        answer = payload.get("answer", "").strip()
        followups = payload.get("followups", [])

        # Ensure exactly 3 follow-ups
        while len(followups) < 3:
            followups.append("")

        print(f" [LLM] JSON batch payload parsed successfully.")
        return answer, followups[:3]

    except json.JSONDecodeError:
        # Graceful fallback — return raw text as answer with no follow-ups
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