"""
Notification / Reminder service — SMS via Twilio, WhatsApp via Twilio, Push via Firebase.
"""
import logging
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.notifications import Notification, NotificationType, NotificationStatus
from app.models.customers import Customer
import uuid

logger = logging.getLogger(__name__)


def _build_reminder_message(customer: Customer) -> str:
    """Build the payment reminder message template."""
    due_date = customer.due_date.strftime("%d %B %Y") if customer.due_date else "this month"
    return (
        f"Hello {customer.name}, your payment of ₹{customer.due_amount:,.0f} "
        f"is pending for this month. Kindly pay before {due_date}. "
        f"Thank you!"
    )


async def _log_notification(
    db: AsyncSession,
    customer: Customer,
    notification_type: NotificationType,
    message: str,
    status: NotificationStatus,
    provider_id: Optional[str] = None,
    error: Optional[str] = None,
    recipient: Optional[str] = None,
) -> None:
    """Save notification attempt to database."""
    notif = Notification(
        id=uuid.uuid4(),
        business_id=customer.business_id,
        customer_id=customer.id,
        notification_type=notification_type,
        status=status,
        recipient_number=recipient,
        title="Payment Reminder",
        message=message,
        provider_message_id=provider_id,
        error_message=error,
        sent_at=datetime.now(timezone.utc) if status == NotificationStatus.SENT else None,
    )
    db.add(notif)
    await db.flush()


async def send_sms_reminder(customer: Customer, db: AsyncSession) -> bool:
    """Send SMS reminder via Twilio."""
    if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_AUTH_TOKEN:
        logger.warning("Twilio credentials not configured — SMS not sent")
        return False

    message = _build_reminder_message(customer)
    phone = customer.mobile_number

    try:
        from twilio.rest import Client
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        twilio_message = client.messages.create(
            body=message,
            from_=settings.TWILIO_FROM_NUMBER,
            to=phone,
        )
        await _log_notification(
            db, customer, NotificationType.SMS, message,
            NotificationStatus.SENT, provider_id=twilio_message.sid, recipient=phone
        )
        logger.info(f"SMS sent to {phone}: {twilio_message.sid}")
        return True
    except Exception as e:
        await _log_notification(
            db, customer, NotificationType.SMS, message,
            NotificationStatus.FAILED, error=str(e), recipient=phone
        )
        logger.error(f"SMS failed for {customer.name}: {e}")
        return False


async def send_whatsapp_reminder(customer: Customer, db: AsyncSession) -> bool:
    """Send WhatsApp message via Twilio WhatsApp API."""
    if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_WHATSAPP_FROM:
        logger.warning("Twilio WhatsApp not configured")
        return False

    message = _build_reminder_message(customer)
    wa_number = f"whatsapp:{customer.whatsapp_number or customer.mobile_number}"

    try:
        from twilio.rest import Client
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        twilio_message = client.messages.create(
            body=message,
            from_=settings.TWILIO_WHATSAPP_FROM,
            to=wa_number,
        )
        await _log_notification(
            db, customer, NotificationType.WHATSAPP, message,
            NotificationStatus.SENT, provider_id=twilio_message.sid,
            recipient=customer.whatsapp_number or customer.mobile_number
        )
        return True
    except Exception as e:
        await _log_notification(
            db, customer, NotificationType.WHATSAPP, message,
            NotificationStatus.FAILED, error=str(e)
        )
        logger.error(f"WhatsApp failed for {customer.name}: {e}")
        return False


async def send_push_reminder(customer: Customer, db: AsyncSession) -> bool:
    """Send Firebase push notification."""
    # Get business owner FCM token through relationship
    # In real implementation, fetch business owner's FCM token
    message = _build_reminder_message(customer)
    try:
        import firebase_admin.messaging as messaging
        msg = messaging.Message(
            notification=messaging.Notification(
                title="💰 Payment Reminder",
                body=f"{customer.name} — ₹{customer.due_amount:,.0f} pending",
            ),
            data={"customer_id": str(customer.id), "amount": str(customer.due_amount)},
            topic=f"business_{customer.business_id}",
        )
        response = messaging.send(msg)
        await _log_notification(
            db, customer, NotificationType.PUSH, message,
            NotificationStatus.SENT, provider_id=response
        )
        return True
    except Exception as e:
        await _log_notification(
            db, customer, NotificationType.PUSH, message,
            NotificationStatus.FAILED, error=str(e)
        )
        logger.error(f"Push notification failed for {customer.name}: {e}")
        return False


async def send_otp_sms(phone_number: str, otp: str) -> bool:
    """Send OTP via SMS."""
    if not settings.TWILIO_ACCOUNT_SID:
        logger.warning(f"[DEV] OTP for {phone_number}: {otp}")
        return True
    try:
        from twilio.rest import Client
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        client.messages.create(
            body=f"Your Customer Ledger Pro OTP is: {otp}. Valid for {settings.OTP_EXPIRE_MINUTES} minutes.",
            from_=settings.TWILIO_FROM_NUMBER,
            to=phone_number,
        )
        return True
    except Exception as e:
        logger.error(f"OTP SMS failed: {e}")
        return False
