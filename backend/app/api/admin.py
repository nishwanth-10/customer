"""
Admin API — Super admin panel for managing businesses and users.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, update
import uuid

from app.core.database import get_db
from app.core.deps import require_super_admin
from app.models.users import User, UserRole
from app.models.businesses import Business
from app.models.customers import Customer
from app.models.transactions import Transaction

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/stats")
async def platform_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):
    """Super admin platform-wide statistics."""
    total_users = (await db.execute(select(func.count(User.id)))).scalar()
    total_businesses = (await db.execute(select(func.count(Business.id)))).scalar()
    total_customers = (await db.execute(select(func.count(Customer.id)))).scalar()
    total_transactions = (await db.execute(select(func.count(Transaction.id)))).scalar()
    active_businesses = (await db.execute(
        select(func.count(Business.id)).where(Business.is_active == True, Business.is_suspended == False)
    )).scalar()

    return {
        "total_users": total_users,
        "total_businesses": total_businesses,
        "active_businesses": active_businesses,
        "suspended_businesses": total_businesses - active_businesses,
        "total_customers": total_customers,
        "total_transactions": total_transactions,
    }


@router.get("/businesses")
async def list_all_businesses(
    page: int = Query(1, ge=1),
    page_size: int = Query(20),
    search: str = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):
    """List all businesses on the platform."""
    query = select(Business)
    if search:
        query = query.where(Business.name.ilike(f"%{search}%"))
    query = query.order_by(Business.created_at.desc())

    offset = (page - 1) * page_size
    result = await db.execute(query.offset(offset).limit(page_size))
    businesses = result.scalars().all()

    return {
        "items": [
            {
                "id": str(b.id),
                "name": b.name,
                "owner_id": str(b.owner_id),
                "is_active": b.is_active,
                "is_suspended": b.is_suspended,
                "created_at": b.created_at.isoformat(),
            }
            for b in businesses
        ],
        "page": page,
    }


@router.post("/businesses/{business_id}/suspend")
async def suspend_business(
    business_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):
    """Suspend a business account."""
    result = await db.execute(select(Business).where(Business.id == business_id))
    business = result.scalar_one_or_none()
    if not business:
        raise HTTPException(status_code=404, detail="Business not found")
    business.is_suspended = True
    business.is_active = False
    await db.commit()
    return {"message": f"Business '{business.name}' suspended"}


@router.post("/businesses/{business_id}/activate")
async def activate_business(
    business_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):
    """Reactivate a suspended business."""
    result = await db.execute(select(Business).where(Business.id == business_id))
    business = result.scalar_one_or_none()
    if not business:
        raise HTTPException(status_code=404, detail="Business not found")
    business.is_suspended = False
    business.is_active = True
    await db.commit()
    return {"message": f"Business '{business.name}' activated"}


@router.get("/users")
async def list_all_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):
    """List all users."""
    query = select(User).order_by(User.created_at.desc())
    offset = (page - 1) * page_size
    result = await db.execute(query.offset(offset).limit(page_size))
    users = result.scalars().all()

    return {
        "items": [
            {
                "id": str(u.id),
                "email": u.email,
                "phone": u.phone_number,
                "name": u.full_name,
                "role": u.role,
                "is_active": u.is_active,
                "created_at": u.created_at.isoformat(),
            }
            for u in users
        ],
        "page": page,
    }


@router.patch("/users/{user_id}/deactivate")
async def deactivate_user(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):
    """Deactivate a user account."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = False
    await db.commit()
    return {"message": "User deactivated"}
