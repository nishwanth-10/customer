# Customer Ledger Pro — Complete Setup & Deployment Guide

## 📦 Project Structure

```
business/
├── customer_ledger_pro/    # Flutter Android App
├── backend/                # FastAPI Python Backend
├── nginx/                  # Nginx reverse proxy
├── docker-compose.yml      # Full stack orchestration
├── .env.example            # Environment variables template
└── docs/                   # Documentation
```

---

## 🚀 Quick Start (Local Development)

### Prerequisites
- Flutter SDK 3.x+
- Python 3.12+
- Docker Desktop
- Android Studio / VS Code

### 1. Clone and Set Up Environment
```bash
cd business
cp .env.example .env
# Edit .env with your credentials
```

### 2. Start Backend with Docker
```bash
docker-compose up -d db redis
# Wait for PostgreSQL to be ready, then:
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 3. Run Full Stack with Docker
```bash
docker-compose up --build
# API: http://localhost:8000
# Docs: http://localhost:8000/docs
# Nginx: http://localhost:80
```

### 4. Run Flutter App
```bash
cd customer_ledger_pro
flutter pub get
# Update lib/core/network/dio_client.dart with your API URL
# Add google-services.json to android/app/
flutter run
```

---

## 🔥 Firebase Setup (REQUIRED)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create project → Enable:
   - **Authentication** → Phone, Google
   - **Cloud Messaging** (FCM)
3. Add Android app:
   - Package name: `com.customerledgerpro.app`
   - Download `google-services.json` → place in `android/app/`
4. Generate service account key → download as `firebase-credentials.json` → place in `backend/`

---

## 📱 Twilio Setup (for SMS + WhatsApp)

1. Sign up at [twilio.com](https://www.twilio.com)
2. Get Account SID and Auth Token from Console
3. Buy a phone number for SMS
4. For WhatsApp: Join sandbox at `https://console.twilio.com/us1/develop/sms/try-it-out/whatsapp-learn`
5. Update `.env` with your credentials

---

## 🏗️ Backend Database Migrations

```bash
cd backend
# Initialize Alembic
alembic init migrations

# Generate first migration
alembic revision --autogenerate -m "initial_schema"

# Apply migrations
alembic upgrade head
```

---

## ☁️ Deploy to Render.com

### 1. Database
- Render Dashboard → New → PostgreSQL
- Copy the connection string → Update `.env`

### 2. Backend API
- New → Web Service → Connect GitHub repo
- Root Directory: `backend`
- Build Command: `pip install -r requirements.txt`
- Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Add all environment variables from `.env`

### 3. Update Flutter App
```dart
// lib/core/network/dio_client.dart
const String kBaseUrl = 'https://your-service.onrender.com/api/v1';
const String kWsUrl = 'wss://your-service.onrender.com/ws';
```

---

## 📲 Play Store Release Build

### Step 1: Generate Keystore
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### Step 2: Configure Signing
```bash
# Copy template
cp android/key.properties.template android/key.properties
# Edit key.properties with your keystore details
```

### Step 3: Build AAB
```bash
cd customer_ledger_pro
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Step 4: Play Console
1. Create app at [play.google.com/console](https://play.google.com/console)
2. App Content → Fill privacy policy URL
3. Production → Create new release → Upload AAB
4. Complete store listing (screenshots, description)
5. Roll out to production

---

## 🔒 Security Checklist

- [ ] Change `SECRET_KEY` to a random 64-char string
- [ ] Set `DEBUG=false` in production
- [ ] Restrict `BACKEND_CORS_ORIGINS` to your domain
- [ ] Enable HTTPS (Nginx SSL or Render HTTPS)
- [ ] Add `key.properties` to `.gitignore`
- [ ] Never commit `firebase-credentials.json`
- [ ] Rotate Twilio tokens regularly

---

## 📊 API Documentation

When running, visit:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **OpenAPI JSON**: `http://localhost:8000/openapi.json`

---

## 🧪 Testing

```bash
# Backend tests
cd backend
pytest tests/ -v

# Flutter tests
cd customer_ledger_pro
flutter test
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| `asyncpg` connection refused | Check PostgreSQL is running and DATABASE_URL is correct |
| Firebase not initialized | Ensure `firebase-credentials.json` is in backend root |
| OTP not received | Check Twilio credentials and phone number format (+91xxxxxxxxxx) |
| Flutter build failed | Run `flutter pub get` and check `google-services.json` |
| WebSocket disconnects | Check Nginx `proxy_read_timeout` is set to 86400 |

---

## 📞 Support

For technical issues, create a GitHub issue or contact the development team.
