"""
Async SQLAlchemy database engine — configured for Neon PostgreSQL (SSL).
"""
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.pool import NullPool
from app.core.config import settings
import ssl


def _build_engine_kwargs() -> dict:
    """
    Build engine kwargs — adds SSL context for Neon/cloud Postgres.
    asyncpg uses ?ssl=require in the URL, but we also pass an SSL
    context to avoid certificate validation issues on some hosts.
    """
    kwargs: dict = {
        "echo": settings.DEBUG,
        "pool_pre_ping": True,
    }

    # Use NullPool in test mode; NullPool avoids connection reuse issues
    # with Neon's serverless connection pooler.
    if settings.ENVIRONMENT in ("testing", "production"):
        kwargs["poolclass"] = NullPool
    else:
        kwargs["pool_size"] = 5
        kwargs["max_overflow"] = 10

    # If connecting to a cloud database (Neon, Supabase, etc.), add SSL
    if "neon.tech" in settings.DATABASE_URL or "ssl=require" in settings.DATABASE_URL:
        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE
        kwargs["connect_args"] = {"ssl": ssl_context}

    return kwargs


# ── Async Engine ─────────────────────────────────────────────────────────────
engine = create_async_engine(settings.DATABASE_URL, **_build_engine_kwargs())

# ── Session Factory ───────────────────────────────────────────────────────────
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


# ── Base Model ────────────────────────────────────────────────────────────────
class Base(DeclarativeBase):
    pass


# ── Dependency ────────────────────────────────────────────────────────────────
async def get_db() -> AsyncSession:
    """FastAPI dependency that provides a managed database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def create_tables():
    """Create all database tables (idempotent — safe to call on every startup)."""
    async with engine.begin() as conn:
        from app.models import (  # noqa: F401 — ensures all models are registered
            users, businesses, customers, transactions,
            monthly_bills, notifications, payments, audit_logs, subscriptions
        )
        await conn.run_sync(Base.metadata.create_all)
