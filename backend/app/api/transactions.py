"""
Transactions API — Daily credit/debit recording and history.
"""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from typing import Optional
from datetime import date
import uuid

from app.core.database import get_db
from app.core.deps import get_current_active_user
from app.models.transactions import Transaction, TransactionType
from app.models.customers import Customer
from app.models.users import User
from app.schemas.transactions import (
    TransactionCreate, TransactionResponse, TransactionListResponse, DailySummary
)
from app.services.audit_service import log_action

router = APIRouter(prefix="/transactions", tags=["Transactions"])


@router.get("", response_model=TransactionListResponse)
async def list_transactions(
    business_id: uuid.UUID = Query(...),
    customer_id: Optional[uuid.UUID] = Query(None),
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    transaction_type: Optional[TransactionType] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """List transactions with filters."""
    filters = [Transaction.business_id == business_id]

    if customer_id:
        filters.append(Transaction.customer_id == customer_id)
    if from_date:
        filters.append(Transaction.transaction_date >= from_date)
    if to_date:
        filters.append(Transaction.transaction_date <= to_date)
    if transaction_type:
        filters.append(Transaction.transaction_type == transaction_type)

    query = select(Transaction).where(and_(*filters)).order_by(Transaction.transaction_date.desc())

    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar()

    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)
    result = await db.execute(query)
    transactions = result.scalars().all()

    return TransactionListResponse(
        items=[TransactionResponse.model_validate(t) for t in transactions],
        total=total,
        page=page,
        page_size=page_size,
        pages=(total + page_size - 1) // page_size,
    )


@router.post("", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
async def create_transaction(
    payload: TransactionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Record a new credit or debit transaction."""
    # Get customer to update balance
    cust_result = await db.execute(select(Customer).where(Customer.id == payload.customer_id))
    customer = cust_result.scalar_one_or_none()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    # Update customer balance
    from decimal import Decimal
    amount_dec = Decimal(str(payload.amount))

    if payload.transaction_type == TransactionType.CREDIT:
        customer.total_paid += amount_dec
        customer.due_amount = max(Decimal("0"), customer.due_amount - amount_dec)
        customer.last_payment_date = payload.transaction_date
    else:
        customer.due_amount += amount_dec

    # Compute running balance (positive = customer owes money)
    balance_after = float(customer.due_amount)

    transaction = Transaction(
        id=uuid.uuid4(),
        business_id=payload.business_id,
        customer_id=payload.customer_id,
        created_by=current_user.id,
        transaction_type=payload.transaction_type,
        amount=payload.amount,
        description=payload.description,
        reference_number=payload.reference_number,
        transaction_date=payload.transaction_date,
        balance_after=balance_after,
    )
    db.add(transaction)

    # Update payment status
    if customer.due_amount <= 0:
        from app.models.customers import PaymentStatus
        customer.payment_status = PaymentStatus.PAID
    elif 0 < customer.due_amount < customer.monthly_payment_amount:
        from app.models.customers import PaymentStatus
        customer.payment_status = PaymentStatus.PARTIAL

    await log_action(db, current_user.id, payload.business_id, "CREATE", "transaction", str(transaction.id))
    await db.commit()
    await db.refresh(transaction)
    return TransactionResponse.model_validate(transaction)


@router.get("/daily-summary")
async def daily_summary(
    business_id: uuid.UUID = Query(...),
    summary_date: date = Query(default=date.today()),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> DailySummary:
    """Get total credits and debits for a specific day."""
    filters = [
        Transaction.business_id == business_id,
        Transaction.transaction_date == summary_date,
    ]

    credit_q = select(func.sum(Transaction.amount)).where(
        and_(*filters, Transaction.transaction_type == TransactionType.CREDIT)
    )
    debit_q = select(func.sum(Transaction.amount)).where(
        and_(*filters, Transaction.transaction_type == TransactionType.DEBIT)
    )
    count_q = select(func.count(Transaction.id)).where(and_(*filters))

    total_credit = (await db.execute(credit_q)).scalar() or 0
    total_debit = (await db.execute(debit_q)).scalar() or 0
    total_count = (await db.execute(count_q)).scalar() or 0

    return DailySummary(
        date=summary_date,
        total_credit=float(total_credit),
        total_debit=float(total_debit),
        net=float(total_credit - total_debit),
        transaction_count=total_count,
    )


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_transaction(
    transaction_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Delete a transaction and reverse its effect on customer balance."""
    result = await db.execute(select(Transaction).where(Transaction.id == transaction_id))
    txn = result.scalar_one_or_none()
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")

    # Reverse balance
    cust_result = await db.execute(select(Customer).where(Customer.id == txn.customer_id))
    customer = cust_result.scalar_one_or_none()
    if customer:
        if txn.transaction_type == TransactionType.CREDIT:
            customer.total_paid -= txn.amount
            customer.due_amount += txn.amount
        else:
            customer.due_amount -= txn.amount

    await db.delete(txn)
    await log_action(db, current_user.id, txn.business_id, "DELETE", "transaction", str(transaction_id))
    await db.commit()
