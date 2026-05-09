"""
Reminders API — Trigger and schedule SMS/WhatsApp/Push reminders.
"""
from fastapi import APIRouter, Depends, BackgroundTasks, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
import uuid

from app.core.database import get_db
from app.core.deps import get_current_active_user, require_business_owner
from app.models.customers import Customer, PaymentStatus
from app.models.notifications import Notification, NotificationType, NotificationStatus
from app.models.users import User
from app.services.notification_service import (
    send_whatsapp_reminder, send_sms_reminder, send_push_reminder
)

router = APIRouter(prefix="/reminders", tags=["Reminders"])


@router.post("/send-bulk")
async def send_bulk_reminders(
    business_id: uuid.UUID = Query(...),
    background_tasks: BackgroundTasks = BackgroundTasks(),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_business_owner),
):
    """Send payment reminders to ALL pending customers in background."""
    result = await db.execute(
        select(Customer).where(
            Customer.business_id == business_id,
            Customer.is_active == True,
            Customer.payment_status.in_([PaymentStatus.PENDING, PaymentStatus.OVERDUE]),
            Customer.due_amount > 0,
            Customer.reminder_enabled == True,
        )
    )
    customers = result.scalars().all()

    if not customers:
        return {"message": "No pending customers found", "count": 0}

    background_tasks.add_task(_send_reminders_to_customers, customers, db)

    return {
        "message": f"Sending reminders to {len(customers)} customers in background",
        "count": len(customers),
    }


async def _send_reminders_to_customers(customers: list[Customer], db: AsyncSession):
    """Background task to send all reminders."""
    for customer in customers:
        if customer.whatsapp_reminder and customer.whatsapp_number:
            await send_whatsapp_reminder(customer, db)
        if customer.sms_reminder and customer.mobile_number:
            await send_sms_reminder(customer, db)
        if customer.push_reminder:
            await send_push_reminder(customer, db)


@router.post("/send/{customer_id}")
async def send_single_reminder(
    customer_id: uuid.UUID,
    notification_type: NotificationType = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Send a reminder to a single customer."""
    result = await db.execute(select(Customer).where(Customer.id == customer_id))
    customer = result.scalar_one_or_none()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    success = False
    if notification_type == NotificationType.WHATSAPP:
        success = await send_whatsapp_reminder(customer, db)
    elif notification_type == NotificationType.SMS:
        success = await send_sms_reminder(customer, db)
    elif notification_type == NotificationType.PUSH:
        success = await send_push_reminder(customer, db)

    return {
        "success": success,
        "customer": customer.name,
        "type": notification_type,
    }


@router.get("/history")
async def reminder_history(
    business_id: uuid.UUID = Query(...),
    page: int = Query(1, ge=1),
    page_size: int = Query(20),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get notification history for a business."""
    from sqlalchemy import func
    query = select(Notification).where(
        Notification.business_id == business_id
    ).order_by(Notification.created_at.desc())

    offset = (page - 1) * page_size
    result = await db.execute(query.offset(offset).limit(page_size))
    notifications = result.scalars().all()

    return {
        "items": [
            {
                "id": str(n.id),
                "type": n.notification_type,
                "status": n.status,
                "customer_id": str(n.customer_id) if n.customer_id else None,
                "message": n.message,
                "sent_at": n.sent_at.isoformat() if n.sent_at else None,
                "error": n.error_message,
            }
            for n in notifications
        ],
        "page": page,
        "page_size": page_size,
    }
