"""
Dashboard API — Aggregated business stats for home screen.
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from datetime import date, datetime, timezone
import uuid

from app.core.database import get_db
from app.core.deps import get_current_active_user
from app.models.customers import Customer, PaymentStatus
from app.models.transactions import Transaction, TransactionType
from app.models.payments import Payment
from app.models.users import User

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("")
async def get_dashboard(
    business_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get complete dashboard stats for the business home screen."""
    now = datetime.now(timezone.utc)
    current_month_start = date(now.year, now.month, 1)
    today = now.date()

    # Total customers
    total_customers = (await db.execute(
        select(func.count(Customer.id)).where(
            Customer.business_id == business_id,
            Customer.is_active == True
        )
    )).scalar() or 0

    # Pending customers count
    pending_customers = (await db.execute(
        select(func.count(Customer.id)).where(
            Customer.business_id == business_id,
            Customer.is_active == True,
            Customer.payment_status.in_([PaymentStatus.PENDING, PaymentStatus.OVERDUE])
        )
    )).scalar() or 0

    # Total pending amount
    total_pending = (await db.execute(
        select(func.sum(Customer.due_amount)).where(
            Customer.business_id == business_id,
            Customer.is_active == True,
            Customer.due_amount > 0
        )
    )).scalar() or 0

    # This month collections
    monthly_collection = (await db.execute(
        select(func.sum(Transaction.amount)).where(
            Transaction.business_id == business_id,
            Transaction.transaction_type == TransactionType.CREDIT,
            Transaction.transaction_date >= current_month_start,
            Transaction.transaction_date <= today,
        )
    )).scalar() or 0

    # Today's collection
    today_collection = (await db.execute(
        select(func.sum(Transaction.amount)).where(
            Transaction.business_id == business_id,
            Transaction.transaction_type == TransactionType.CREDIT,
            Transaction.transaction_date == today,
        )
    )).scalar() or 0

    # Total all-time income
    total_income = (await db.execute(
        select(func.sum(Transaction.amount)).where(
            Transaction.business_id == business_id,
            Transaction.transaction_type == TransactionType.CREDIT,
        )
    )).scalar() or 0

    # Recent transactions (last 10)
    recent_txns_result = await db.execute(
        select(Transaction)
        .where(Transaction.business_id == business_id)
        .order_by(Transaction.created_at.desc())
        .limit(10)
    )
    recent_transactions = recent_txns_result.scalars().all()

    # Monthly trend (last 6 months)
    monthly_trend = []
    for i in range(5, -1, -1):
        import calendar
        month = (now.month - i - 1) % 12 + 1
        year = now.year - ((now.month - i - 1) // 12)
        _, last_day = calendar.monthrange(year, month)
        m_start = date(year, month, 1)
        m_end = date(year, month, last_day)

        m_collection = (await db.execute(
            select(func.sum(Transaction.amount)).where(
                Transaction.business_id == business_id,
                Transaction.transaction_type == TransactionType.CREDIT,
                Transaction.transaction_date >= m_start,
                Transaction.transaction_date <= m_end,
            )
        )).scalar() or 0

        monthly_trend.append({
            "month": month,
            "year": year,
            "month_name": datetime(year, month, 1).strftime("%b"),
            "collection": float(m_collection),
        })

    return {
        "total_customers": total_customers,
        "pending_customers": pending_customers,
        "paid_customers": total_customers - pending_customers,
        "total_pending_amount": float(total_pending),
        "monthly_collection": float(monthly_collection),
        "today_collection": float(today_collection),
        "total_income": float(total_income),
        "recent_transactions": [
            {
                "id": str(t.id),
                "customer_id": str(t.customer_id),
                "type": t.transaction_type,
                "amount": float(t.amount),
                "date": t.transaction_date.isoformat(),
                "description": t.description,
            }
            for t in recent_transactions
        ],
        "monthly_trend": monthly_trend,
    }
