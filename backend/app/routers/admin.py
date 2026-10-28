import logging
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Header, status, Query
from app.auth.dependencies import get_current_user, require_admin
from app.services.firestore_service import firestore_service
from app.services.audit_service import record_audit_log
from app.core.config import settings
from app.schemas.organization import (
    OrganizationResponse,
    OrganizationVerificationUpdate,
    VerificationStatus,
)
from app.schemas.audit import AuditLogResponse, AuditResult
from app.schemas.user import UserRole, AccountStatus
from pydantic import BaseModel

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin", tags=["Administrator"])


class AdminBootstrapRequest(BaseModel):
    bootstrap_secret: str
    target_uid: Optional[str] = None


@router.post("/bootstrap", status_code=status.HTTP_200_OK)
async def bootstrap_administrator(
    bootstrap_payload: AdminBootstrapRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Secure deployment bootstrap to elevate an initial account to Administrator.
    Requires the exact server-side ADMIN_BOOTSTRAP_SECRET.
    Never exposed for public self-registration.
    """
    if bootstrap_payload.bootstrap_secret != settings.ADMIN_BOOTSTRAP_SECRET:
        record_audit_log(
            actor_uid=current_user.get("uid", "unknown"),
            action="admin_bootstrap_attempt",
            resource_type="user",
            resource_id=current_user.get("uid", "unknown"),
            result=AuditResult.DENIED,
            details={"reason": "Invalid bootstrap secret provided"},
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid administrative bootstrap secret.",
        )

    target_uid = bootstrap_payload.target_uid or current_user["uid"]
    updated = firestore_service.update_user(target_uid, {
        "role": UserRole.ADMIN.value,
        "account_status": AccountStatus.ACTIVE.value,
    })

    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Target user not found")

    record_audit_log(
        actor_uid=current_user["uid"],
        action="admin_bootstrap_success",
        resource_type="user",
        resource_id=target_uid,
        result=AuditResult.SUCCESS,
        details={"elevated_to": UserRole.ADMIN.value},
    )

    return {"message": f"Successfully elevated user {target_uid} to Administrator.", "user": updated}


@router.get("/organizations/pending", response_model=List[OrganizationResponse])
async def list_pending_organizations(
    admin_user: Dict[str, Any] = Depends(require_admin),
):
    """
    Lists all pending organization verification applications.
    Strictly restricted to verified Administrators.
    """
    return firestore_service.list_pending_organizations()


@router.patch("/organizations/{organization_id}/verification", response_model=OrganizationResponse)
async def verify_organization(
    organization_id: str,
    verification: OrganizationVerificationUpdate,
    admin_user: Dict[str, Any] = Depends(require_admin),
):
    """
    Approves or rejects an emergency authority (Police / Hospital) application.
    When approved, activates the organization user's account.
    """
    org = firestore_service.get_organization(organization_id)
    if not org:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Organization not found")

    status_value = verification.verification_status.value
    updated_org = firestore_service.update_organization(organization_id, {
        "verification_status": status_value,
        "admin_notes": verification.admin_notes,
    })

    # If approved, update applicant user's account_status to ACTIVE
    applicant_uid = org.get("registered_by_uid")
    if applicant_uid:
        new_account_status = (
            AccountStatus.ACTIVE.value
            if status_value == VerificationStatus.APPROVED.value
            else AccountStatus.SUSPENDED.value
        )
        firestore_service.update_user(applicant_uid, {"account_status": new_account_status})

    record_audit_log(
        actor_uid=admin_user["uid"],
        action=f"organization_verification_{status_value}",
        resource_type="organization",
        resource_id=organization_id,
        result=AuditResult.SUCCESS,
        details={"status": status_value, "applicant_uid": applicant_uid, "notes": verification.admin_notes},
    )

    logger.info("Admin %s updated org %s status to %s", admin_user["uid"], organization_id, status_value)
    return updated_org


@router.get("/audit-logs", response_model=List[AuditLogResponse])
async def list_audit_logs(
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    admin_user: Dict[str, Any] = Depends(require_admin),
):
    """
    Retrieves system audit logs for administrative review and security monitoring.
    Strictly restricted to verified Administrators.
    """
    return firestore_service.list_audit_logs(limit=limit, offset=offset)
