"""
Pydantic schemas for Transactions.
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date, datetime
import uuid
from app.models.transactions import TransactionType


class TransactionCreate(BaseModel):
    business_id: uuid.UUID
    customer_id: uuid.UUID
    transaction_type: TransactionType
    amount: float = Field(..., gt=0)
    description: Optional[str] = None
    reference_number: Optional[str] = None
    transaction_date: date = Field(default_factory=date.today)


class TransactionResponse(BaseModel):
    id: uuid.UUID
    business_id: uuid.UUID
    customer_id: uuid.UUID
    created_by: uuid.UUID
    transaction_type: TransactionType
    amount: float
    description: Optional[str] = None
    reference_number: Optional[str] = None
    transaction_date: date
    balance_after: float
    created_at: datetime

    model_config = {"from_attributes": True}


class TransactionListResponse(BaseModel):
    items: List[TransactionResponse]
    total: int
    page: int
    page_size: int
    pages: int


class DailySummary(BaseModel):
    date: date
    total_credit: float
    total_debit: float
    net: float
    transaction_count: int
