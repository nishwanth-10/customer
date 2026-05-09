"""
MonthlyBill model — monthly billing records per customer.
"""
import uuid
from datetime import datetime, date, timezone
from enum import Enum as PyEnum
from sqlalchemy import String, Boolean, DateTime, Date, Integer, ForeignKey, Numeric, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


class BillStatus(str, PyEnum):
    UNPAID = "unpaid"
    PAID = "paid"
    PARTIAL = "partial"
    WAIVED = "waived"


class MonthlyBill(Base):
    __tablename__ = "monthly_bills"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    customer_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("customers.id", ondelete="CASCADE"), nullable=False, index=True)
    business_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False, index=True)

    bill_month: Mapped[int] = mapped_column(Integer, nullable=False)   # 1–12
    bill_year: Mapped[int] = mapped_column(Integer, nullable=False)    # e.g. 2024
    due_date: Mapped[date] = mapped_column(Date, nullable=False)

    amount_due: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    amount_paid: Mapped[float] = mapped_column(Numeric(12, 2), default=0.00)
    amount_remaining: Mapped[float] = mapped_column(Numeric(12, 2), default=0.00)

    status: Mapped[BillStatus] = mapped_column(Enum(BillStatus), default=BillStatus.UNPAID, index=True)
    paid_on: Mapped[date | None] = mapped_column(Date, nullable=True)

    reminder_sent: Mapped[bool] = mapped_column(Boolean, default=False)
    reminder_sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    customer: Mapped["Customer"] = relationship("Customer", back_populates="monthly_bills")

    def __repr__(self) -> str:
        return f"<MonthlyBill {self.bill_month}/{self.bill_year} ₹{self.amount_due}>"
