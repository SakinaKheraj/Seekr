import google.generativeai as genai
import time
from server.config import GEMINI_API_KEY
from typing import List

genai.configure(api_key=GEMINI_API_KEY)

# Free-tier quota order (highest daily quota first):
# gemini-2.0-flash:   1500 RPD, 15 RPM  ← best free tier option
# gemini-2.5-flash:   250 RPD,  10 RPM
# gemini-1.5-flash:   1500 RPD, 15 RPM  ← second best
# gemini-1.5-flash-8b: 1500 RPD, 15 RPM
# gemini-1.0-pro:     --- (limited)
# gemini-1.5-pro is EXCLUDED: only 50 RPD free — not worth the fallback slot
MODELS_TO_TRY = [
    'gemini-2.0-flash',    # Best free tier: 1500 RPD, 15 RPM
    'gemini-2.5-flash',    # 250 RPD, 10 RPM — premium quality fallback
    'gemini-1.5-flash',    # 1500 RPD, 15 RPM — solid backup
    'gemini-1.5-flash-8b', # 1500 RPD, 15 RPM — lightweight backup
    'gemini-1.0-pro'       # Last resort
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
IMPORTANT: You MUST respond ONLY with a raw, valid JSON object matching the exact schema below! Do not add any markdown formatting, code blocks, or conversational text.

{
  "answer": "Your detailed answer here based on the sources...",
  "followups": [
    "Short related question 1?",
    "Short related question 2?",
    "Short related question 3?"
  ]
}
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

                import json
                try:
                    # Strip out Markdown JSON block wrappers if the model ignores the instruction
                    clean_json = full_text.strip()
                    if clean_json.startswith("```json"):
                        clean_json = clean_json.split("```json")[-1].split("```")[0].strip()
                    elif clean_json.startswith("```"):
                        clean_json = clean_json.split("```")[-1].split("```")[0].strip()

                    payload = json.loads(clean_json)
                    answer = payload.get("answer", "").strip()
                    followups = payload.get("followups", [])
                except json.JSONDecodeError as e:
                    # Fallback if AI entirely fails to produce valid JSON
                    answer = full_text
                    followups = []

                # pad with empty strings up to 3 to satisfy UI expectations if AI provides fewer
                while followups and len(followups) < 3:
                    followups.append("")

                print(f" SUCCESS with {model_name} (JSON BATCH PAYLOAD)")
                return answer, followups[:3]

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
