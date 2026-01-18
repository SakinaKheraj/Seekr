# SeekrAI Backend

## Overview
SeekrAI is an AI-powered search assistant that combines
Google Search with Gemini AI to generate factual answers
with source citations.

## Tech Stack
- FastAPI
- Firebase Authentication
- Google Custom Search API
- Google Gemini AI

## Features
- Secure AI endpoints
- Search-Augmented Generation (SAG)
- Source attribution
- Clean service-based architecture

## API Endpoints

### POST /chat
Protected endpoint that returns an AI-generated answer
using live web search results.

Request:
{
  "query": "What is FastAPI?",
  "session_id": "abc123"
}

Response:
{
  "answer": "...",
  "sources": [...],
  "user_id": "..."
}
