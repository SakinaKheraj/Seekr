# Seekr - Advanced AI Search & Drafting Assistant

![Seekr Architecture](https://img.shields.io/badge/Architecture-Clean-brightgreen) ![Flutter UI](https://img.shields.io/badge/UI-Glassmorphism-blue) ![FastAPI](https://img.shields.io/badge/Backend-FastAPI-teal) ![Firebase](https://img.shields.io/badge/Database-Firestore-orange)

**Seekr** is a premium, AI-powered search and drafting assistant. It leverages Google Gemini's reasoning capabilities paired with live Google Search to give you highly accurate, context-aware answers complete with source citations, smart follow-up suggestions, and professional drafting tools.

Built with a relentless focus on performance, Seekr dynamically mitigates high API costs through an intelligent `$0-Cost` RAM caching layer that stores recurring search workflows and document conversions.

---

## ✨ Key Features
- 🔍 **Live Search Intelligence**: Automatically runs Google custom searches and passes context to Gemini AI to ensure answers are highly factual and up-to-date.
- ⚡ **Zero-Latency RAM Caching**: Intercepts repetitive AI questions and drafting commands to serve them instantly from a local dictionary, saving severe backend quota costs.
- ✏️ **Drafting Lab**: One-click transform any AI answer into a polished Executive Summary, Email, LinkedIn Post, or Markdown Report format.
- 📂 **Collections & Bookmarks**: Save useful answers in dynamically generated Folders for later use. Share entire collections easily with one click.
- 🕒 **Session History**: Easily scroll through past searches locally and securely via the cloud structure.
- 💎 **Premium Interface**: A world-class interface built identically to iOS system components with fluid animations, solid Apple-style white elevation blocks, and BLoC Stream updates. 

---

## 🛠 Tech Stack

### 📱 Frontend (Mobile App - Flutter)
- **Framework:** Flutter (Dart)
- **State Management:** BLoC (Business Logic Component) Architecture
- **Routing:** Standard Named Routes (`AppRoutes`)
- **Theme Constraints:** Bespoke glass-themed aesthetic featuring bespoke gradient mapping and clean Material elevations.
- **Packages:** `flutter_bloc`, `firebase_auth`, `flutter_markdown`, `google_fonts`, `share_plus`

### ⚙️ Backend (API Layer - Python)
- **Framework:** FastAPI (Uvicorn)
- **AI Models:** Google Gemini (`gemini-2.5-flash`, `gemini-1.5-pro` failover pipelines)
- **Search Engine:** Google Custom Search JSON API
- **Middleware:** Custom singleton MemoryCache structure for $0 scaling limits and optimized throughput.
- **Packages:** `google-generativeai`, `fastapi`, `firebase-admin`, `pydantic`

### ☁️ Infrastructure & Auth
- **Authentication:** Firebase Auth (Email/Password integrated via backend tokens)
- **Database:** Firebase Cloud Firestore (NoSQL Document Store)

---

## 🚀 How to Run Locally

### Prerequisites
Before running Seekr, ensure you have the following installed:
1. [Flutter SDK](https://docs.flutter.dev/get-started/install) 
2. [Python 3.10+](https://www.python.org/downloads/)
3. A Google Cloud Console project (for Firebase Admin Keys, Gemini API key, and Custom Search API Key)

### 1. Setup Backend (FastAPI)
1. Open a terminal and navigate to the backend directory:
   ```bash
   cd server
   ```
2. Create and activate a Python virtual environment:
   ```bash
   python -m venv venv
   source venv/Scripts/activate  # (Windows)
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Set up your hidden credentials!
   You will need to ensure your keys are configured (typically housed in your `.env` or `config.py` structure):
   - `GEMINI_API_KEY`
   - `GOOGLE_SEARCH_API_KEY`
   - `GOOGLE_CSE_ID`
   - **Firebase Admin SDK JSON**: Make sure to place your Firebase Admin Credentials internally where `firebase_config.py` can locate them.
5. Boot the server using Uvicorn:
   ```bash
   uvicorn server.main:app --host 0.0.0.0 --port 8000 --reload
   ```

### 2. Setup Frontend (Flutter)
1. Open a new terminal and navigate to the root working directory where `/lib` is located.
   ```bash
   cd seekr
   ```
2. Fetch Dart packages:
   ```bash
   flutter pub get
   ```
3. Ensure the Flutter app is correctly pointing to your local Python API (`http://10.0.2.2:8000` for Android Emulator, or `http://127.0.0.1:8000` for iOS Simulators). Update your network client inside your Data layers if necessary.
4. Launch the application!
   ```bash
   flutter run
   ```

---

## 📂 Architecture Overview

Seekr uses Clean Architecture principles.
- **Presentation**: UI specific files (Pages, Components, Modals) and BLoC Cubit definitions to intercept interactions.
- **Domain/Data**: Handles outbound connections (`AuthRepo`, `ChatService`, `CollectionsService`), bridging Dart to your Python API Layer via standard REST.
- **Backend Services**: The backend utilizes Thread Pooling (`run_in_threadpool`) so the FastAPI UI thread isn't intentionally blocked while waiting on Gemini to generate Markdown bodies.

---
*Built with ❤️ utilizing Flutter and FastAPI.*
