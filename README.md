# 🌌 Seekr

> **An ultra-premium, AI-native discovery and drafting ecosystem.**  
> Seekr solves the *"Stale AI"* problem by bridging real-time web intelligence with advanced LLM reasoning — wrapped in a luxury-grade visual experience.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Google Gemini](https://img.shields.io/badge/Gemini-8E75B2?style=for-the-badge&logo=google&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)

---

## What is Seekr?

Seekr is built for researchers, writers, and power-users who need more than a chatbot. It combines **real-time search**, **advanced AI reasoning**, and **smart archiving** into one cohesive tool — at near-zero infrastructure cost thanks to a RAM-first caching architecture.

---

## Features

### 🔍 Intelligent Search
Real-time factual anchoring via the Google Search API. Every query pulls the top 5 live sources before the AI reasons over them, eliminating stale or hallucinated answers.

### 🧠 AI Intelligence Pipeline
Gemini 2.5 Flash / 1.5 Pro in a multi-model failover setup. A custom **MemoryCache Singleton** intercepts repeated queries and serves them from RAM in 0ms — zero Gemini cost. Responses are **JSON-batched**: one API call returns the full answer *and* 3 smart follow-up questions simultaneously.

### ✍️ Drafting Lab
Transform any AI response into a professional format — **Email, LinkedIn Post, Markdown Report, or Executive Summary**. Drafts are cached too, so regenerating for the same content is instant and free.

### ⏱️ Session-Managed History
Sessions auto-expire after 30 minutes of inactivity and spawn a fresh `session_id`. Gemini generates a human-readable title for each session from the first query (e.g., *"Exploring Quantum Physics"*). History is aggregated into grouped sessions with message and source counts.

### 📁 Collections & Bookmarks
Save any response into a named folder. Access is user-scoped — `collections_service.py` enforces that users can only read or delete bookmarks belonging to their own `uid`.

### 🔐 Secure Authentication
Firebase Authentication with JWT ID Tokens. Every backend request passes through `firebase_auth_service.py`, which verifies the Bearer token against the Firebase Admin SDK before any logic executes.

---

## Tech Stack

**Frontend** — Flutter (Dart) targeting Android, iOS, and Web from a single codebase. State is managed with the BLoC / Cubit pattern for predictable, immutable transitions. UI follows a *Glassmorphism 2.0* design language using `BackdropFilter` frosted glass and high-elevation Material cards.

**Backend** — FastAPI (Python) with Uvicorn for high-performance async request handling. Google Gemini handles LLM reasoning with a custom multi-model failover pipeline. A MemoryCache Singleton sits in front of all AI and search calls.

**Infrastructure** — Google Cloud Firestore for chat and collection persistence. Firebase Authentication for identity. Docker + AWS EC2 for containerized cloud deployment routed through Port 80 via `docker-compose`.

---

## Architecture

### Authentication Flow
```
User Login → FirebaseAuth → JWT ID Token
                                 ↓
              Backend Request + Bearer Token
                                 ↓
         firebase_auth_service.py → Firebase Admin SDK
                                 ↓
                     Request proceeds to logic
```

### Search & Intelligence Pipeline
```
User Query
    │
    ├─ RAM Cache Hit? ──────────────────────→ Return in 0ms ($0 cost)
    │
    ├─ Greeting detected? ──────────────────→ Skip Search & AI
    │
    ▼
search_service.py → Top 5 Google Results
    │
    ▼
llm_service.py → Query + Results + Chat History → Gemini
    │
    ▼
JSON: { answer, follow_up_questions[3] }
```

---

## Project Structure

```
seekr/
├── backend/
│   ├── main.py
│   ├── services/
│   │   ├── firebase_auth_service.py
│   │   ├── search_service.py
│   │   ├── llm_service.py
│   │   └── collections_service.py
│   ├── cache/
│   │   └── memory_cache.py
│   ├── Dockerfile
│   └── docker-compose.yml
│
└── flutter_app/
    ├── lib/
    │   ├── blocs/
    │   ├── screens/
    │   ├── widgets/
    │   └── services/
    └── pubspec.yaml
```

---

## Getting Started

### Prerequisites
- Flutter SDK
- Python 3.10+
- Docker
- Firebase project with Firestore & Authentication enabled
- Google Cloud API keys (Custom Search API + Gemini)

### Backend
```bash
git clone https://github.com/your-org/seekr.git
cd seekr/backend

pip install -r requirements.txt

cp .env.example .env
# Add: GEMINI_API_KEY, GOOGLE_SEARCH_API_KEY, FIREBASE_CREDENTIALS_PATH

uvicorn main:app --reload --port 8000
```

### Flutter App
```bash
cd seekr/flutter_app
flutter pub get
flutter run
```

### Docker (Production)
```bash
cd seekr
docker-compose up --build -d
# API live on Port 80
```

---

## Design

*"Classy Glass"* — a luxury visual language that is high-tech and clean.

- **Glassmorphism 2.0** — frosted glass panels over deep-navy gradients via `BackdropFilter`
- **Elevation** — cards use `blurRadius: 40` and `borderRadius: 28` to appear floating
- **Color** — vibrant blue-to-deep-navy gradients paired with pure white blocks
- **Typography** — Poppins (Google Fonts) for legibility and a modern feel

---

## Deployment

1. Build and push the Docker image
2. SSH into your AWS EC2 instance
3. Run `docker-compose up -d`
4. Set `ApiConfig.useProduction = true` in the Flutter app
5. All clients on any network hit the live API on Port 80

---

<p align="center">Built with Flutter · FastAPI · Gemini · Firebase · AWS</p>
