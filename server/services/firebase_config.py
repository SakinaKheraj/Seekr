import json
import os
import firebase_admin
from firebase_admin import credentials

def initialize_firebase():
    if not firebase_admin._apps:
        # Try JSON string first (for Render)
        cred_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
        if cred_json:
            cred_dict = json.loads(cred_json)
            # Ensure private_key handles escaped newlines correctly
            if "private_key" in cred_dict:
                cred_dict["private_key"] = cred_dict["private_key"].replace("\\n", "\n")
            cred = credentials.Certificate(cred_dict)
        else:
            # Fall back to file path (for local/EC2)
            from server.config import FIREBASE_CREDENTIALS
            cred = credentials.Certificate(FIREBASE_CREDENTIALS)
        
        firebase_admin.initialize_app(
            cred,
            {"projectId": "seekr-8b019"}
        )