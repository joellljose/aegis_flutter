import uuid
import logging
from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth.dependencies import get_current_user
from app.services.firestore_service import firestore_service
from app.services.audit_service import record_audit_log
from app.schemas.organization import (
    OrganizationRegistrationCreate,
    OrganizationResponse,
    VerificationStatus,
)
from app.schemas.user import UserRole, AccountStatus
from app.schemas.audit import AuditResult

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/organizations", tags=["Organizations"])


@router.post("/registration", response_model=OrganizationResponse, status_code=status.HTTP_202_ACCEPTED)
async def submit_organization_registration(
    org_data: OrganizationRegistrationCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Submits a verification request for Police, Hospital, or Ambulance service.
    Administrative verification is strictly required before organization privileges are granted.
    """
    uid = current_user["uid"]

    # Check if user already submitted an organization
    existing_org = firestore_service.get_user_organization(uid)
    if existing_org:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An organization application is already registered for this account.",
        )

    org_id = f"org_{uuid.uuid4().hex[:12]}"
    data = {
        "organization_id": org_id,
        "organization_type": org_data.organization_type.value,
        "organization_name": org_data.organization_name,
        "official_email": org_data.official_email,
        "official_phone": org_data.official_phone,
        "address": org_data.address,
        "service_area": org_data.service_area,
        "verification_status": VerificationStatus.PENDING.value,
        "registered_by_uid": uid,
        "admin_notes": None,
    }

    created = firestore_service.create_organization(org_id, data)

    # Set user role to the requested organization type but keep account_status as PENDING_VERIFICATION
    target_role = (
        UserRole.POLICE.value
        if org_data.organization_type.value == "police"
        else UserRole.HOSPITAL.value
    )
    firestore_service.update_user(uid, {
        "role": target_role,
        "account_status": AccountStatus.PENDING_VERIFICATION.value,
    })

    # Record audit log
    record_audit_log(
        actor_uid=uid,
        action="submit_organization_registration",
        resource_type="organization",
        resource_id=org_id,
        result=AuditResult.SUCCESS,
        details={"org_type": org_data.organization_type.value, "org_name": org_data.organization_name},
    )

    logger.info("User %s submitted org registration %s (%s)", uid, org_id, org_data.organization_name)
    return created
