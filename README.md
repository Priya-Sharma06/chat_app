# Flutter Emotion-Aware Chat App

## 📱 Overview

An intelligent real-time messaging application that combines seamless communication with advanced emotion detection powered by AI. This Flutter-based chat app uses BERT language models to analyze user emotions, providing meaningful insights into conversations while maintaining privacy and ease of use.

## ✨ Key Features

**Real-Time Messaging**
- Global chat mode for broadcast conversations
- Private one-on-one messaging
- Recent conversations view for quick access
- Instant message delivery through Firebase Firestore
- Real-time message synchronization across devices

**AI-Powered Emotion Detection**
- Automatic emotion analysis of each message using DistilRoBERTa-based BERT model
- Detects 6 primary emotions: Joy, Sadness, Anger, Fear, Surprise, and Neutral
- Per-message emotion classification
- Aggregated emotion statistics over time
- Dominant emotion identification for conversation context

**User Authentication**
- Secure Google Sign-In integration
- Firebase Authentication backend
- User session management
- One-tap login experience

**Modern UI/UX**
- Beautiful gradient backgrounds with soft pastel colors
- Smooth animations for enhanced user experience
- Dynamic message bubbles with real-time rendering
- Responsive design that works on all screen sizes
- Intuitive navigation between chat modes

## 🏗️ Architecture

- **Frontend:** Flutter with Dart
- **Backend:** Firebase (Authentication & Firestore) + FastAPI (Emotion Detection)
- **AI Model:** DistilRoBERTa-base fine-tuned for emotion detection
- **Real-Time Database:** Cloud Firestore
- **Authentication:** Google Sign-In with Firebase Auth

## 🚀 Tech Stack

- **Flutter** - Cross-platform mobile development
- **Firebase Suite** - Authentication, Firestore database, real-time updates
- **FastAPI** - High-performance Python backend for AI inference
- **BERT (DistilRoBERTa)** - Transformer-based emotion classification
- **Transformers Library** - PyTorch-based model loading and inference

The app seamlessly integrates mobile development with machine learning, delivering a unique communication experience that values emotional understanding.

## 📊 Screen Flow Diagram

```
                              START
                                │
                                ↓
                        ┌─────────────────┐
                        │  Home Screen    │
                        │(Google Sign-In) │
                        └─────────────────┘
                                │
                                │Authenticate
                                ↓
                       ┌─────────────────┐
                       │   Chat Screen   │
                       └─────────────────┘
                                │
           ┌────────────────────┼────────────────────┐
           │                    │                    │
           ↓                    ↓                    ↓
   ┌─────────────┐       ┌─────────────┐     ┌──────────────┐
   │Global Chat  │       │   Recents   │     │Private Chat  │
   │   (Rooms)   │       │  (Threads)  │     │  (1-to-1)    │
   └─────────────┘       └─────────────┘     └──────────────┘
           │                    │                   │
           └────────────────────┼───────────────────┘
                                │
                        User Sends Message
                                │
           ┌────────────────────┴────────────────────┐
           │                                         │
           ↓                                         ↓
   ┌──────────────┐                    ┌───────────────────┐
   │ Firestore    │                    │ Email to API      │
   │ Storage      │                    │ (10.0.2.2:8000)   │
   │              │                    │                   │
   │• Collection: │                    │ BERT Model        │
   │  messages    │                    │ Analysis          │
   │• Fields:     │                    └───────────────────┘
   │  - sender_id │                              │
   │  - content   │◄─────────────────────────────┘
   │  - emotion   │   (Emotion Result)
   │  - timestamp │
   │  - chat_type │
   └──────────────┘
           │
           │ Real-time Listener
           │ (StreamBuilder)
           ↓
   ┌──────────────┐                   ┌──────────────────────┐
   │ Update UI    │                   │ View Stats Button    │
   │ in Chat      │──────────────────→│                      │
   │ Screen       │  5-min Messages   │ Emotion Results      │
   └──────────────┘                   │ Screen               │
                                      └──────────────────────┘
```

## 🔄 Data Flow

**Message Sending:**
1. User types message → Sends to Chat Screen
2. Message stored in Firestore with user ID and timestamp
3. FastAPI backend receives message via HTTP request
4. BERT model analyzes emotion and returns classification
5. Emotion metadata stored alongside message
6. Real-time update pushed to all subscribed clients

**Emotion Analysis:**
1. Chat screen collects messages from last 5 minutes
2. Sends to FastAPI `/analyze_bulk_emotions` endpoint
3. Backend processes each message through DistilRoBERTa
4. Returns emotion distribution and per-message analysis
5. Emotion Results Screen displays visualizations

## 🛠️ Setup & Installation

```bash
# Flutter app
flutter pub get
flutter run

# FastAPI backend
pip install fastapi uvicorn transformers torch
python main.py  # Runs on http://localhost:8000
```
