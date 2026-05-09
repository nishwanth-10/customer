"""
Reminder scheduler — APScheduler cron jobs for monthly automated reminders.
"""
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import logging

from app.core.database import AsyncSessionLocal
from app.models.businesses import Business
from app.models.customers import Customer, PaymentStatus

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler(timezone="Asia/Kolkata")


async def _run_monthly_reminders():
    """Run every day at 9am — send reminders to businesses whose reminder_day matches today."""
    from datetime import date
    from app.services.notification_service import (
        send_sms_reminder, send_whatsapp_reminder, send_push_reminder
    )

    today = date.today()
    logger.info(f"Running monthly reminder check for day={today.day}")

    async with AsyncSessionLocal() as db:
        try:
            # Get all active businesses whose reminder day is today
            businesses_result = await db.execute(
                select(Business).where(
                    Business.is_active == True,
                    Business.is_suspended == False,
                    Business.reminder_day == today.day,
                )
            )
            businesses = businesses_result.scalars().all()
            logger.info(f"Found {len(businesses)} businesses to remind today")

            for business in businesses:
                # Get all pending customers
                customers_result = await db.execute(
                    select(Customer).where(
                        Customer.business_id == business.id,
                        Customer.is_active == True,
                        Customer.payment_status.in_([PaymentStatus.PENDING, PaymentStatus.OVERDUE]),
                        Customer.due_amount > 0,
                        Customer.reminder_enabled == True,
                    )
                )
                customers = customers_result.scalars().all()
                logger.info(f"Business {business.name}: {len(customers)} customers to remind")

                for customer in customers:
                    try:
                        if customer.whatsapp_reminder and (customer.whatsapp_number or customer.mobile_number):
                            await send_whatsapp_reminder(customer, db)
                        if customer.sms_reminder and customer.mobile_number:
                            await send_sms_reminder(customer, db)
                        if customer.push_reminder:
                            await send_push_reminder(customer, db)
                    except Exception as e:
                        logger.error(f"Error sending reminder to {customer.name}: {e}")

            await db.commit()
        except Exception as e:
            logger.error(f"Monthly reminder job failed: {e}")
            await db.rollback()


def start_scheduler():
    """Start the background scheduler. Called during app startup."""
    # Run every day at 9:00 AM IST
    scheduler.add_job(
        _run_monthly_reminders,
        CronTrigger(hour=9, minute=0, timezone="Asia/Kolkata"),
        id="monthly_reminders",
        replace_existing=True,
    )
    scheduler.start()
    logger.info("APScheduler started — monthly reminders scheduled for 9:00 AM IST daily")


def stop_scheduler():
    """Stop the scheduler on app shutdown."""
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("APScheduler stopped")
