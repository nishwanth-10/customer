"""
Audit logging service.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional, Dict, Any
import uuid
from app.models.audit_logs import AuditLog


async def log_action(
    db: AsyncSession,
    user_id: uuid.UUID,
    business_id: Optional[uuid.UUID],
    action: str,
    resource_type: str,
    resource_id: Optional[str] = None,
    old_values: Optional[Dict[str, Any]] = None,
    new_values: Optional[Dict[str, Any]] = None,
    ip_address: Optional[str] = None,
) -> None:
    """Log an audit event."""
    log = AuditLog(
        id=uuid.uuid4(),
        user_id=user_id,
        business_id=business_id,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        old_values=old_values,
        new_values=new_values,
        ip_address=ip_address,
    )
    db.add(log)
    # Don't commit here — let the calling function commit
