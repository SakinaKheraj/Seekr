
# 🌌 Seekr — AI-Native Discovery & Drafting Engine

<p align="center">
  <b>Real-time research. Intelligent synthesis. Ready-to-publish output.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Frontend-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/FastAPI-Backend-green?logo=fastapi" />
  <img src="https://img.shields.io/badge/Firebase-Auth-orange?logo=firebase" />
  <img src="https://img.shields.io/badge/Gemini-AI-purple" />
  <img src="https://img.shields.io/badge/Docker-Containerized-blue?logo=docker" />
  <img src="https://img.shields.io/badge/Status-Production--Ready-success" />
</p>

---

## 📌 Overview

**Seekr** is a premium AI-powered platform that combines **real-time web search** with **LLM reasoning** to generate **accurate, context-aware, and structured outputs**.

Unlike traditional chatbots, Seekr is designed for:

* Researchers
* Writers
* Power users

➡️ It transforms live web data into **usable, professional content**

---

## ✨ Features

* 🔎 **Real-Time Search** — Google Search API integration for factual grounding
* ✍️ **Drafting Lab** — Convert responses into emails, posts, reports
* 🧠 **Smart Sessions** — Context-aware chat with auto titles
* 📁 **Collections** — Folder-based bookmarking system
* ☁️ **Cloud Sync** — Firestore-powered persistence
* ⚡ **Zero-Cost Optimizations** — RAM caching + JSON batching

---

## 🏗️ Architecture

```text
User (Flutter App)
        │
        ▼
Firebase Auth (JWT)
        │
        ▼
FastAPI Backend
 ├── Auth Middleware
 ├── Memory Cache (RAM)
 ├── Search Service (Google API)
 ├── LLM Service (Gemini)
        │
        ▼
Firestore (Database)
```

---

## 🔐 Authentication Flow

1. User logs in via Firebase
2. JWT token generated
3. Token sent with API requests
4. Backend verifies using Firebase Admin SDK
5. Access granted only if valid

---

## 🧠 Intelligence Pipeline

1. User query received
2. Cache check (instant response if hit)
3. Greeting filter (saves API cost)
4. Google Search retrieves context
5. LLM processes:

   * Query
   * Search results
   * Chat history
6. Returns structured JSON:

   * Answer
   * Follow-up questions

---

## ⚡ Performance Optimizations

### 🧠 MemoryCache (Singleton)

* RAM-based caching
* Zero-cost repeated queries
* Shared across chat + drafting

### 📦 JSON Batching

* Single response includes:

  * Answer
  * Suggestions
* Reduces API calls

---

## 🕒 Session Management

* Auto new session after **30 min inactivity**
* AI-generated session titles
* Context grouped as "conversation journeys"

---

## 📁 Feature Modules

### 📌 Collections

* Save responses into folders
* Secure user-specific access

### ✍️ Drafting Lab

* Formats:

  * Email
  * LinkedIn
  * Markdown
  * Summary
* Cached → instant regeneration

### 📊 Search History

* Session-based grouping
* Metadata:

  * Message count
  * Source count

---

## 🎨 UI Design — "Classy Glass"

* Glassmorphism (BackdropFilter)
* Soft shadows (blurRadius: 40)
* Rounded cards (28px)
* Blue → navy gradients
* Premium minimal aesthetic

---

## 🛠 Tech Stack

| Layer     | Technology                 |
| --------- | -------------------------- |
| Frontend  | Flutter (Dart), BLoC       |
| Backend   | FastAPI, Uvicorn           |
| AI Models | Gemini 2.5 Flash / 1.5 Pro |
| Database  | Firestore                  |
| Auth      | Firebase Auth              |
| DevOps    | Docker, AWS EC2            |

---

## 🚀 Getting Started

### 🔧 Prerequisites

* Flutter SDK
* Python 3.10+
* Firebase project
* Google API keys

---

### 📦 Installation

```bash
# Clone repository
git clone https://github.com/your-username/seekr.git
cd seekr
```

---

### ▶️ Backend Setup

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

---

### 📱 Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

---

## 🔐 Environment Variables

Create `.env` in backend:

```env
FIREBASE_CREDENTIALS=your_credentials.json
GEMINI_API_KEY=your_key
GOOGLE_SEARCH_API_KEY=your_key
```


---

## 🤝 Contributing

Contributions are welcome.

```bash
# Fork repo
# Create branch
git checkout -b feature/your-feature

# Commit
git commit -m "Add feature"

# Push
git push origin feature/your-feature
```


---

## ⭐ Support

If you found this useful:

* ⭐ Star the repo
* 🍴 Fork it
* 🧠 Share feedback
