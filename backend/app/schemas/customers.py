"""
Pydantic schemas for Customers.
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date, datetime
import uuid
from app.models.customers import PaymentStatus


class CustomerCreate(BaseModel):
    business_id: uuid.UUID
    name: str = Field(..., min_length=1, max_length=255)
    mobile_number: str
    whatsapp_number: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    notes: Optional[str] = None
    monthly_payment_amount: float = Field(default=0.0, ge=0)
    due_amount: float = Field(default=0.0, ge=0)
    opening_balance: float = Field(default=0.0, ge=0)
    payment_status: PaymentStatus = PaymentStatus.PENDING
    due_date: Optional[date] = None
    reminder_enabled: bool = True
    whatsapp_reminder: bool = True
    sms_reminder: bool = True
    push_reminder: bool = True


class CustomerUpdate(BaseModel):
    name: Optional[str] = None
    mobile_number: Optional[str] = None
    whatsapp_number: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    notes: Optional[str] = None
    monthly_payment_amount: Optional[float] = None
    due_amount: Optional[float] = None
    payment_status: Optional[PaymentStatus] = None
    due_date: Optional[date] = None
    reminder_enabled: Optional[bool] = None
    whatsapp_reminder: Optional[bool] = None
    sms_reminder: Optional[bool] = None
    push_reminder: Optional[bool] = None


class CustomerResponse(BaseModel):
    id: uuid.UUID
    business_id: uuid.UUID
    name: str
    mobile_number: str
    whatsapp_number: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    notes: Optional[str] = None
    monthly_payment_amount: float
    due_amount: float
    total_paid: float
    payment_status: PaymentStatus
    last_payment_date: Optional[date] = None
    due_date: Optional[date] = None
    reminder_enabled: bool
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class CustomerListResponse(BaseModel):
    items: List[CustomerResponse]
    total: int
    page: int
    page_size: int
    pages: int
