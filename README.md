# 🏦 Customer Ledger Pro

**Production-ready Android app for small businesses to manage customers, payments, and automated reminders.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.111-green?logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue?logo=postgresql)](https://www.postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 👥 Customer Management | Full CRUD with contact info, due amounts, and payment history |
| 💰 Transaction Tracking | Daily credit/debit with running balance and history |
| 📅 Monthly Billing | Auto-generate monthly bills and track collection rates |
| 📲 Automated Reminders | WhatsApp + SMS + Push notifications via Twilio & Firebase |
| 📊 Reports & Analytics | Monthly reports, bar charts, PDF/Excel export |
| 🌙 Dark Mode | Full Material 3 dark theme |
| 🔌 Offline Support | Hive local cache + sync queue for offline-first use |
| 🔐 Multi-Auth | Email/Password, Phone OTP, Google Sign-In |
| 👑 Role-Based Access | Super Admin, Business Owner, Staff roles |
| 🐳 Docker Ready | Full Compose stack with Nginx, Postgres, Redis |

---

## 📱 Tech Stack

### Mobile (Flutter)
- **State**: Riverpod 2.x
- **Navigation**: GoRouter
- **HTTP**: Dio with JWT auto-refresh
- **Offline**: Hive local storage
- **Charts**: FL Chart
- **UI**: Material 3 + Google Fonts (Poppins)

### Backend (Python)
- **API**: FastAPI 0.111 + Uvicorn
- **DB**: PostgreSQL 15 + SQLAlchemy async + Alembic
- **Auth**: JWT (python-jose) + bcrypt + Firebase Phone Auth
- **SMS**: Twilio REST API
- **WhatsApp**: Twilio WhatsApp Business API
- **Push**: Firebase Admin SDK
- **Scheduler**: APScheduler (monthly reminders)
- **Cache**: Redis + Slowapi rate limiting

---

## 🚀 Quick Start

```bash
# 1. Clone & configure
git clone <repo>
cd business
cp .env.example .env        # fill in your secrets

# 2. Start all services
docker-compose up --build   # API at :8000, Nginx at :80

# 3. Run Flutter app
cd customer_ledger_pro
flutter pub get
flutter run                 # connects to localhost:8000
```

📖 See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for full setup guide.

---

## 📂 Project Structure

```
business/
├── customer_ledger_pro/          # Flutter App
│   ├── lib/
│   │   ├── core/                 # theme, router, network, storage
│   │   ├── features/             # auth, dashboard, customers, transactions...
│   │   └── shared/widgets/       # reusable UI components
│   └── android/                  # Android config, signing
│
├── backend/                      # FastAPI Backend
│   ├── app/
│   │   ├── api/                  # auth, customers, transactions, reports...
│   │   ├── models/               # 9 SQLAlchemy models
│   │   ├── schemas/              # Pydantic request/response schemas
│   │   └── services/             # Twilio, Firebase, APScheduler
│   └── Dockerfile
│
├── nginx/nginx.conf              # Reverse proxy + rate limiting
├── docker-compose.yml            # Full stack orchestration
├── .env.example                  # Environment template
└── docs/                         # Guides
```

---

## 🗃️ Database Schema

```
users ─┬─ businesses ─┬─ customers ─┬─ transactions
       │              │             ├─ monthly_bills
       │              │             ├─ payments
       │              │             └─ notifications
       │              ├─ subscriptions
       │              └─ audit_logs
       └─ audit_logs
```

---

## 🔐 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Email login |
| POST | `/api/v1/auth/send-otp` | Send phone OTP |
| POST | `/api/v1/auth/verify-otp` | Verify OTP → JWT |
| POST | `/api/v1/auth/google` | Google Sign-In |
| GET | `/api/v1/customers` | List customers (paginated) |
| POST | `/api/v1/customers` | Create customer |
| GET | `/api/v1/transactions` | List transactions |
| POST | `/api/v1/transactions` | Record transaction |
| GET | `/api/v1/dashboard` | Dashboard stats |
| POST | `/api/v1/reminders/send-bulk` | Bulk reminders |
| GET | `/api/v1/reports/export/pdf` | Export PDF |
| GET | `/api/v1/reports/export/excel` | Export Excel |
| WS | `/ws/{business_id}` | Real-time updates |

---

## 📲 Play Store

1. Build: `flutter build appbundle --release`
2. Upload AAB to Google Play Console
3. Host `docs/privacy_policy.html` publicly
4. See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md#play-store-release-build) for signing steps

---

## 📄 License

MIT License — See [LICENSE](LICENSE)

---

*Built with ❤️ for Indian small businesses*
