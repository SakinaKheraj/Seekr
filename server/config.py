import os
from dotenv import load_dotenv

load_dotenv()

FIREBASE_CREDENTIALS = os.getenv("FIREBASE_CREDENTIALS")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
GOOGLE_CSE_ID = os.getenv("GOOGLE_CSE_ID")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")