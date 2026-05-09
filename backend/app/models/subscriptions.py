"""
Subscription model — business subscription tiers.
"""
import uuid
from datetime import datetime, date, timezone
from enum import Enum as PyEnum
from sqlalchemy import String, Boolean, DateTime, Date, Numeric, ForeignKey, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


class SubscriptionPlan(str, PyEnum):
    FREE = "free"
    BASIC = "basic"         # Up to 100 customers
    PROFESSIONAL = "professional"  # Up to 500 customers
    ENTERPRISE = "enterprise"      # Unlimited


class SubscriptionStatus(str, PyEnum):
    ACTIVE = "active"
    EXPIRED = "expired"
    CANCELLED = "cancelled"
    TRIAL = "trial"


class Subscription(Base):
    __tablename__ = "subscriptions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False, index=True)

    plan: Mapped[SubscriptionPlan] = mapped_column(Enum(SubscriptionPlan), default=SubscriptionPlan.FREE)
    status: Mapped[SubscriptionStatus] = mapped_column(Enum(SubscriptionStatus), default=SubscriptionStatus.TRIAL)

    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    amount_paid: Mapped[float] = mapped_column(Numeric(10, 2), default=0.00)
    currency: Mapped[str] = mapped_column(String(3), default="INR")
    payment_reference: Mapped[str | None] = mapped_column(String(255), nullable=True)

    max_customers: Mapped[int] = mapped_column(default=10)   # FREE plan limit
    auto_renew: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    business: Mapped["Business"] = relationship("Business", back_populates="subscriptions")

    def __repr__(self) -> str:
        return f"<Subscription {self.plan} [{self.status}]>"
