"""
Authentication API — Register, Login, OTP, Google OAuth, Token Refresh.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone

from app.core.database import get_db
from app.core.security import (
    verify_password, get_password_hash, create_access_token,
    create_refresh_token, decode_token, generate_otp, generate_otp_expiry
)
from app.core.config import settings
from app.models.users import User, UserRole, AuthProvider
from app.schemas.auth import (
    RegisterRequest, LoginRequest, TokenResponse, OTPRequest,
    OTPVerifyRequest, RefreshTokenRequest, GoogleAuthRequest
)
from app.services.notification_service import send_otp_sms
import uuid

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """Register new business owner with email + password."""
    # Check duplicate
    existing = await db.execute(
        select(User).where(User.email == payload.email)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        id=uuid.uuid4(),
        email=payload.email,
        full_name=payload.full_name,
        hashed_password=get_password_hash(payload.password),
        role=UserRole.BUSINESS_OWNER,
        auth_provider=AuthProvider.EMAIL,
        is_active=True,
        is_verified=False,
    )
    db.add(user)
    await db.flush()

    # Create default business profile for the owner
    from app.models.businesses import Business
    business = Business(
        id=user.id,  # Link business ID to user ID for the primary business
        owner_id=user.id,
        name=f"{user.full_name}'s Business",
        slug=f"biz-{str(user.id)[:8]}",
        email=user.email,
    )
    db.add(business)

    # Generate OTP for email verification
    otp = generate_otp()
    user.otp_code = otp
    user.otp_expires_at = generate_otp_expiry()
    await db.commit()

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    refresh_token = create_refresh_token({"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user_id=str(user.id),
        full_name=user.full_name,
        email=user.email,
        role=user.role,
        is_verified=user.is_verified,
    )


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)):
    """Login with email + password."""
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(payload.password, user.hashed_password or ""):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account suspended")

    user.last_login_at = datetime.now(timezone.utc)
    if payload.fcm_token:
        user.fcm_token = payload.fcm_token
    await db.commit()

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    refresh_token = create_refresh_token({"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user_id=str(user.id),
        full_name=user.full_name,
        email=user.email,
        role=user.role,
        is_verified=user.is_verified,
    )


@router.post("/send-otp")
async def send_otp(payload: OTPRequest, db: AsyncSession = Depends(get_db)):
    """Send OTP to phone number for authentication."""
    result = await db.execute(select(User).where(User.phone_number == payload.phone_number))
    user = result.scalar_one_or_none()

    if not user:
        # Create new user with phone auth
        user = User(
            id=uuid.uuid4(),
            phone_number=payload.phone_number,
            full_name=payload.phone_number,
            role=UserRole.BUSINESS_OWNER,
            auth_provider=AuthProvider.PHONE,
            is_active=True,
            is_verified=False,
        )
        db.add(user)

    otp = generate_otp()
    user.otp_code = otp
    user.otp_expires_at = generate_otp_expiry()
    await db.commit()

    # Send OTP via SMS
    await send_otp_sms(payload.phone_number, otp)

    return {"message": f"OTP sent to {payload.phone_number}", "expires_in": settings.OTP_EXPIRE_MINUTES * 60}


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(payload: OTPVerifyRequest, db: AsyncSession = Depends(get_db)):
    """Verify OTP and return JWT tokens."""
    result = await db.execute(select(User).where(User.phone_number == payload.phone_number))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.otp_code != payload.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")

    if not user.otp_expires_at or datetime.now(timezone.utc) > user.otp_expires_at:
        raise HTTPException(status_code=400, detail="OTP expired")

    user.otp_code = None
    user.otp_expires_at = None
    user.is_verified = True
    user.last_login_at = datetime.now(timezone.utc)
    if payload.fcm_token:
        user.fcm_token = payload.fcm_token
    await db.commit()

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    refresh_token = create_refresh_token({"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user_id=str(user.id),
        full_name=user.full_name,
        phone_number=user.phone_number,
        role=user.role,
        is_verified=user.is_verified,
    )


@router.post("/google", response_model=TokenResponse)
async def google_auth(payload: GoogleAuthRequest, db: AsyncSession = Depends(get_db)):
    """Authenticate with Google ID token."""
    import firebase_admin.auth as firebase_auth
    try:
        decoded = firebase_auth.verify_id_token(payload.id_token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Google token")

    google_id = decoded.get("uid")
    email = decoded.get("email")
    name = decoded.get("name", email)
    avatar = decoded.get("picture")

    result = await db.execute(select(User).where(User.google_id == google_id))
    user = result.scalar_one_or_none()

    if not user:
        # Check by email
        if email:
            result2 = await db.execute(select(User).where(User.email == email))
            user = result2.scalar_one_or_none()

        if not user:
            user = User(
                id=uuid.uuid4(),
                email=email,
                full_name=name,
                google_id=google_id,
                firebase_uid=google_id,
                avatar_url=avatar,
                role=UserRole.BUSINESS_OWNER,
                auth_provider=AuthProvider.GOOGLE,
                is_active=True,
                is_verified=True,
            )
            db.add(user)
        else:
            user.google_id = google_id
            user.is_verified = True

    user.last_login_at = datetime.now(timezone.utc)
    if payload.fcm_token:
        user.fcm_token = payload.fcm_token
    await db.commit()

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    refresh_token = create_refresh_token({"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user_id=str(user.id),
        full_name=user.full_name,
        email=user.email,
        role=user.role,
        is_verified=True,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(payload: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    """Refresh access token using refresh token."""
    decoded = decode_token(payload.refresh_token)
    if not decoded or decoded.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    user_id = decoded.get("sub")
    result = await db.execute(select(User).where(User.id == user_id, User.is_active == True))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    new_refresh = create_refresh_token({"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh,
        token_type="bearer",
        user_id=str(user.id),
        full_name=user.full_name,
        email=user.email,
        role=user.role,
        is_verified=user.is_verified,
    )


@router.post("/logout")
async def logout():
    """Logout — client should discard tokens."""
    return {"message": "Logged out successfully"}
