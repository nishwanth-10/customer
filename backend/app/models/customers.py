"""
Customer model — full customer records with payment tracking.
"""
import uuid
from datetime import datetime, date, timezone
from enum import Enum as PyEnum
from sqlalchemy import String, Boolean, DateTime, Date, Text, ForeignKey, Numeric, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


class PaymentStatus(str, PyEnum):
    PAID = "paid"
    PENDING = "pending"
    OVERDUE = "overdue"
    PARTIAL = "partial"


class Customer(Base):
    __tablename__ = "customers"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Personal Info
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    mobile_number: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    whatsapp_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Financial
    monthly_payment_amount: Mapped[float] = mapped_column(Numeric(12, 2), default=0.00, nullable=False)
    due_amount: Mapped[float] = mapped_column(Numeric(12, 2), default=0.00, nullable=False)
    total_paid: Mapped[float] = mapped_column(Numeric(12, 2), default=0.00, nullable=False)
    opening_balance: Mapped[float] = mapped_column(Numeric(12, 2), default=0.00, nullable=False)

    payment_status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus), default=PaymentStatus.PENDING, nullable=False, index=True
    )
    last_payment_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    due_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    # Reminder settings
    reminder_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    whatsapp_reminder: Mapped[bool] = mapped_column(Boolean, default=True)
    sms_reminder: Mapped[bool] = mapped_column(Boolean, default=True)
    push_reminder: Mapped[bool] = mapped_column(Boolean, default=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # ── Relationships ──────────────────────────────────────────────────────────
    business: Mapped["Business"] = relationship("Business", back_populates="customers")
    transactions: Mapped[list["Transaction"]] = relationship("Transaction", back_populates="customer", cascade="all, delete-orphan")
    monthly_bills: Mapped[list["MonthlyBill"]] = relationship("MonthlyBill", back_populates="customer", cascade="all, delete-orphan")
    payments: Mapped[list["Payment"]] = relationship("Payment", back_populates="customer", cascade="all, delete-orphan")
    notifications: Mapped[list["Notification"]] = relationship("Notification", back_populates="customer")

    def __repr__(self) -> str:
        return f"<Customer {self.name} [{self.payment_status}]>"
