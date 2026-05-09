"""
Transaction model — daily credit/debit entries.
"""
import uuid
from datetime import datetime, date, timezone
from enum import Enum as PyEnum
from sqlalchemy import String, DateTime, Date, Text, ForeignKey, Numeric, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


class TransactionType(str, PyEnum):
    CREDIT = "credit"    # Money received FROM customer
    DEBIT = "debit"      # Money given TO customer / expense


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False, index=True)
    customer_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("customers.id", ondelete="CASCADE"), nullable=False, index=True)
    created_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)

    transaction_type: Mapped[TransactionType] = mapped_column(Enum(TransactionType), nullable=False, index=True)
    amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    reference_number: Mapped[str | None] = mapped_column(String(100), nullable=True)

    transaction_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Running balance after this transaction
    balance_after: Mapped[float] = mapped_column(Numeric(12, 2), default=0.00)

    # Relationships
    business: Mapped["Business"] = relationship("Business", back_populates="transactions")
    customer: Mapped["Customer"] = relationship("Customer", back_populates="transactions")

    def __repr__(self) -> str:
        return f"<Transaction {self.transaction_type} ₹{self.amount}>"
