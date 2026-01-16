import firebase_admin
from firebase_admin import credentials
from server.config import FIREBASE_CREDENTIALS

def initialize_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(FIREBASE_CREDENTIALS)
        firebase_admin.initialize_app(
            cred,
            {
                "projectId": "seekr-8b019"
            }
        )
