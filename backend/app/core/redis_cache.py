"""
Upstash Redis helper — provides a thin caching layer using the
Upstash REST API (no TCP Redis server required).
"""
from app.core.config import get_upstash_redis

_redis = None


def get_redis():
    """Lazy singleton — returns the Upstash Redis client or None."""
    global _redis
    if _redis is None:
        _redis = get_upstash_redis()
    return _redis


def cache_set(key: str, value: str, ex: int = 300) -> bool:
    """Set a key with TTL (seconds). Returns True on success."""
    r = get_redis()
    if r is None:
        return False
    try:
        r.set(key, value, ex=ex)
        return True
    except Exception:
        return False


def cache_get(key: str):
    """Get a cached value, or None if missing / Redis unavailable."""
    r = get_redis()
    if r is None:
        return None
    try:
        return r.get(key)
    except Exception:
        return None


def cache_delete(key: str) -> bool:
    r = get_redis()
    if r is None:
        return False
    try:
        r.delete(key)
        return True
    except Exception:
        return False


def cache_otp(phone: str, otp: str, ttl_seconds: int = 300) -> bool:
    """Store OTP for phone number with TTL."""
    return cache_set(f"otp:{phone}", otp, ex=ttl_seconds)


def get_cached_otp(phone: str):
    """Retrieve OTP for phone number."""
    return cache_get(f"otp:{phone}")


def delete_otp(phone: str):
    """Delete OTP after successful verification."""
    return cache_delete(f"otp:{phone}")
