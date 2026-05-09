"""
FastAPI Application Entry Point — Customer Ledger Pro Backend
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
import firebase_admin
from firebase_admin import credentials
import os

from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.core.config import settings, get_upstash_redis
from app.core.database import create_tables
from app.services.reminder_service import start_scheduler, stop_scheduler

# ── API Routers ───────────────────────────────────────────────────────────────
from app.api.auth import router as auth_router
from app.api.customers import router as customers_router
from app.api.transactions import router as transactions_router
from app.api.dashboard import router as dashboard_router
from app.api.reminders import router as reminders_router
from app.api.reports import router as reports_router
from app.api.admin import router as admin_router
from app.api.websocket import router as ws_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
)
logger = logging.getLogger(__name__)

# ── Rate Limiter (in-memory; no Redis URI needed) ─────────────────────────────
# storage_uri="memory://" prevents slowapi from reading the .env file itself
limiter = Limiter(key_func=get_remote_address, storage_uri="memory://")


# ── App Lifespan ──────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting Customer Ledger Pro API...")

    # ── Firebase ──────────────────────────────────────────────────
    firebase_path = settings.FIREBASE_CREDENTIALS_PATH
    if not os.path.isabs(firebase_path):
        firebase_path = os.path.normpath(
            os.path.join(os.path.dirname(__file__), "..", firebase_path)
        )
    if os.path.exists(firebase_path):
        try:
            if not firebase_admin._apps:
                cred = credentials.Certificate(firebase_path)
                firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized OK")
        except Exception as e:
            logger.warning(f"Firebase init failed: {e}")
    else:
        logger.warning(f"Firebase credentials not found at {firebase_path} — push disabled")

    # ── Upstash Redis ─────────────────────────────────────────────
    redis = get_upstash_redis()
    if redis:
        try:
            redis.set("clp_ping", "pong")
            logger.info("Upstash Redis connected OK")
        except Exception as e:
            logger.warning(f"Upstash Redis ping failed: {e}")
    else:
        logger.warning("Upstash Redis not configured — caching disabled")

    # ── Database tables ───────────────────────────────────────────
    try:
        await create_tables()
        logger.info("Neon PostgreSQL tables ready")
    except Exception as e:
        logger.error(f"Database init failed: {e}")

    # ── APScheduler (daily reminders) ─────────────────────────────
    start_scheduler()
    logger.info("Reminder scheduler started (daily 9 AM IST)")

    yield  # ── server is running ──────────────────────────────────

    stop_scheduler()
    logger.info("Server shutdown complete")


# ── FastAPI App ───────────────────────────────────────────────────────────────
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Production-ready API for Customer Ledger Pro — small business payment management",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# ── Attach limiter ────────────────────────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── CORS Middleware ───────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routes ────────────────────────────────────────────────────────────────────
API_PREFIX = "/api/v1"
app.include_router(auth_router,         prefix=API_PREFIX)
app.include_router(customers_router,    prefix=API_PREFIX)
app.include_router(transactions_router, prefix=API_PREFIX)
app.include_router(dashboard_router,    prefix=API_PREFIX)
app.include_router(reminders_router,    prefix=API_PREFIX)
app.include_router(reports_router,      prefix=API_PREFIX)
app.include_router(admin_router,        prefix=API_PREFIX)
app.include_router(ws_router)           # WebSocket at root level


# ── Root endpoints ────────────────────────────────────────────────────────────
@app.get("/")
async def root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": settings.APP_VERSION}
