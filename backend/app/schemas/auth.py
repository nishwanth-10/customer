"""
Pydantic schemas for Authentication.
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from app.models.users import UserRole


class RegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=255)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=72)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    fcm_token: Optional[str] = None


class OTPRequest(BaseModel):
    phone_number: str = Field(..., pattern=r"^\+[1-9]\d{6,14}$")


class OTPVerifyRequest(BaseModel):
    phone_number: str
    otp: str = Field(..., min_length=6, max_length=6)
    fcm_token: Optional[str] = None


class GoogleAuthRequest(BaseModel):
    id_token: str
    fcm_token: Optional[str] = None


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: str
    full_name: str
    email: Optional[str] = None
    phone_number: Optional[str] = None
    role: UserRole
    is_verified: bool
