"""
Customers API — Full CRUD with search, filters, and balance tracking.
"""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_, and_
from typing import Optional
import uuid

from app.core.database import get_db
from app.core.deps import get_current_active_user, require_staff
from app.models.customers import Customer, PaymentStatus
from app.models.users import User
from app.schemas.customers import (
    CustomerCreate, CustomerUpdate, CustomerResponse, CustomerListResponse
)
from app.services.audit_service import log_action

router = APIRouter(prefix="/customers", tags=["Customers"])


@router.get("", response_model=CustomerListResponse)
async def list_customers(
    business_id: uuid.UUID = Query(...),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None),
    status: Optional[PaymentStatus] = Query(None),
    sort_by: str = Query("name"),
    sort_order: str = Query("asc"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """List all customers for a business with pagination, search, and filters."""
    query = select(Customer).where(
        Customer.business_id == business_id,
        Customer.is_active == True
    )

    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                Customer.name.ilike(search_term),
                Customer.mobile_number.ilike(search_term),
                Customer.email.ilike(search_term),
            )
        )

    if status:
        query = query.where(Customer.payment_status == status)

    # Sorting
    sort_col = getattr(Customer, sort_by, Customer.name)
    if sort_order == "desc":
        sort_col = sort_col.desc()
    query = query.order_by(sort_col)

    # Count
    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar()

    # Paginate
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)
    result = await db.execute(query)
    customers = result.scalars().all()

    return CustomerListResponse(
        items=[CustomerResponse.model_validate(c) for c in customers],
        total=total,
        page=page,
        page_size=page_size,
        pages=(total + page_size - 1) // page_size,
    )


@router.post("", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
async def create_customer(
    payload: CustomerCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Create a new customer."""
    customer = Customer(**payload.model_dump())
    customer.id = uuid.uuid4()
    db.add(customer)
    await db.flush()
    await log_action(db, current_user.id, payload.business_id, "CREATE", "customer", str(customer.id))
    await db.commit()
    return CustomerResponse.model_validate(customer)


@router.get("/{customer_id}", response_model=CustomerResponse)
async def get_customer(
    customer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get a single customer by ID."""
    result = await db.execute(select(Customer).where(Customer.id == customer_id))
    customer = result.scalar_one_or_none()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    return CustomerResponse.model_validate(customer)


@router.put("/{customer_id}", response_model=CustomerResponse)
async def update_customer(
    customer_id: uuid.UUID,
    payload: CustomerUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Update a customer's details."""
    result = await db.execute(select(Customer).where(Customer.id == customer_id))
    customer = result.scalar_one_or_none()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    old_values = {k: str(getattr(customer, k)) for k in payload.model_fields_set}

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(customer, field, value)

    await log_action(
        db, current_user.id, customer.business_id, "UPDATE", "customer",
        str(customer_id), old_values=old_values
    )
    await db.commit()
    return CustomerResponse.model_validate(customer)


@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_customer(
    customer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Soft delete a customer."""
    result = await db.execute(select(Customer).where(Customer.id == customer_id))
    customer = result.scalar_one_or_none()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    customer.is_active = False
    await log_action(db, current_user.id, customer.business_id, "DELETE", "customer", str(customer_id))
    await db.commit()


@router.get("/{customer_id}/summary")
async def customer_summary(
    customer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get customer financial summary."""
    result = await db.execute(select(Customer).where(Customer.id == customer_id))
    customer = result.scalar_one_or_none()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    return {
        "customer_id": str(customer.id),
        "name": customer.name,
        "due_amount": float(customer.due_amount),
        "total_paid": float(customer.total_paid),
        "monthly_payment": float(customer.monthly_payment_amount),
        "payment_status": customer.payment_status,
        "last_payment_date": customer.last_payment_date,
    }
