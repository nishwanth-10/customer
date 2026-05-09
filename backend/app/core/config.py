"""
Application configuration using Pydantic Settings.
All values are loaded from environment variables or .env file.
"""
from pydantic_settings import BaseSettings
from typing import List
import secrets


class Settings(BaseSettings):
    # ── Application ──────────────────────────────────────────────
    APP_NAME: str = "Customer Ledger Pro"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"  # development | staging | production

    # ── Security ─────────────────────────────────────────────────
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    OTP_EXPIRE_MINUTES: int = 5
    ALGORITHM: str = "HS256"

    # ── Neon PostgreSQL ───────────────────────────────────────────
    # asyncpg driver uses ?ssl=require (NOT sslmode=require)
    DATABASE_URL: str = "postgresql+asyncpg://postgres:password@localhost:5432/customer_ledger"
    DATABASE_URL_SYNC: str = "postgresql://postgres:password@localhost:5432/customer_ledger"

    # ── Upstash Redis (REST/HTTP — no TCP needed) ─────────────────
    UPSTASH_REDIS_REST_URL: str = ""
    UPSTASH_REDIS_REST_TOKEN: str = ""

    # ── CORS ──────────────────────────────────────────────────────
    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    # ── Firebase ──────────────────────────────────────────────────
    FIREBASE_CREDENTIALS_PATH: str = "customer-legder-firebase-adminsdk-fbsvc-1ca8f8570c.json"
    FIREBASE_PROJECT_ID: str = "customer-legder"

    # ── Twilio SMS ────────────────────────────────────────────────
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_FROM_NUMBER: str = ""        # E.164 format: +1234567890

    # ── WhatsApp Business API (Twilio) ────────────────────────────
    TWILIO_WHATSAPP_FROM: str = ""      # whatsapp:+14155238886

    # ── Google OAuth ──────────────────────────────────────────────
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""

    # ── Storage ───────────────────────────────────────────────────
    UPLOAD_DIR: str = "uploads"
    MAX_UPLOAD_SIZE_MB: int = 10

    # ── Rate Limiting ─────────────────────────────────────────────
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_AUTH_PER_MINUTE: int = 10

    # ── Pagination ────────────────────────────────────────────────
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100

    # ── Business defaults ─────────────────────────────────────────
    DEFAULT_CURRENCY: str = "INR"
    DEFAULT_CURRENCY_SYMBOL: str = "₹"

    model_config = {"env_file": ".env", "case_sensitive": True}


settings = Settings()


# ── Upstash Redis helper (imported by services that need caching) ──
def get_upstash_redis():
    """Return an Upstash Redis client using REST API credentials."""
    if not settings.UPSTASH_REDIS_REST_URL or not settings.UPSTASH_REDIS_REST_TOKEN:
        return None
    try:
        from upstash_redis import Redis
        return Redis(
            url=settings.UPSTASH_REDIS_REST_URL,
            token=settings.UPSTASH_REDIS_REST_TOKEN,
        )
    except ImportError:
        return None
