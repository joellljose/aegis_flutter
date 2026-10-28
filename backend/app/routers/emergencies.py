import uuid
import logging
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth.dependencies import get_current_user
from app.auth.permissions import verify_emergency_access
from app.services.firestore_service import firestore_service
from app.services.audit_service import record_audit_log
from app.schemas.emergency import (
    EmergencyEventCreate,
    EmergencyStatusUpdate,
    EmergencyEventResponse,
    EmergencyStatus,
)
from app.schemas.user import UserRole
from app.schemas.audit import AuditResult

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/emergencies", tags=["Emergency Events"])


@router.post("", response_model=EmergencyEventResponse, status_code=status.HTTP_201_CREATED)
async def trigger_emergency(
    event_data: EmergencyEventCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Triggers an emergency incident from the device owner or companion application.
    Derives the owner strictly from the authenticated token.
    Attaches the owner's emergency profile for authorized responders.
    """
    owner_uid = current_user["uid"]
    event_id = f"em_{uuid.uuid4().hex[:12]}"

    # Verify device belongs to user if devices are registered
    user_devices = firestore_service.list_user_devices(owner_uid)
    if user_devices:
        device_ids = [d["device_id"] for d in user_devices]
        if event_data.device_id not in device_ids:
            logger.warning("User %s triggered alert with unassociated device %s", owner_uid, event_data.device_id)

    data = {
        "event_id": event_id,
        "owner_uid": owner_uid,
        "device_id": event_data.device_id,
        "event_type": event_data.event_type.value,
        "timestamp": firestore_service.get_user(owner_uid).get("updated_at") or "now",
        "latitude": event_data.latitude,
        "longitude": event_data.longitude,
        "location_accuracy": event_data.location_accuracy,
        "event_status": EmergencyStatus.ACTIVE.value,
        "assigned_organization_ids": event_data.assigned_organization_ids or [],
        "owner_name": current_user.get("full_name"),
        "emergency_profile": current_user.get("emergency_profile"),
    }

    created = firestore_service.create_emergency(event_id, data)

    record_audit_log(
        actor_uid=owner_uid,
        action="emergency_triggered",
        resource_type="emergency_event",
        resource_id=event_id,
        result=AuditResult.SUCCESS,
        details={"type": event_data.event_type.value, "lat": event_data.latitude, "lon": event_data.longitude},
    )

    logger.critical("EMERGENCY EVENT CREATED: %s for user %s at (%s, %s)",
                    event_id, owner_uid, event_data.latitude, event_data.longitude)
    return created


@router.get("", response_model=List[EmergencyEventResponse])
async def list_emergencies(
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Lists ONLY emergency events the caller is authorized to view:
    - Normal user: their own emergency incidents
    - Police / Hospital: incidents explicitly routed to their verified organization
    - Admin: all incidents for monitoring
    """
    uid = current_user["uid"]
    role = current_user.get("role")

    if role == UserRole.ADMIN.value:
        # Admin can view all
        all_emergencies = list(firestore_service._in_memory["emergency_events"].values())
        return all_emergencies

    if role in [UserRole.POLICE.value, UserRole.HOSPITAL.value]:
        org = firestore_service.get_user_organization(uid)
        if not org or org.get("verification_status") != "approved":
            return []
        return firestore_service.list_organization_emergencies(org["organization_id"])

    # Normal user
    return firestore_service.list_user_emergencies(uid)


@router.get("/{event_id}", response_model=EmergencyEventResponse)
async def get_emergency(
    event_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Retrieves a specific emergency event if the caller has authorized access.
    """
    event = firestore_service.get_emergency(event_id)
    if not event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Emergency incident not found")

    verify_emergency_access(current_user, event)
    return event


@router.patch("/{event_id}/status", response_model=EmergencyEventResponse)
async def update_emergency_status(
    event_id: str,
    status_update: EmergencyStatusUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Updates the status of an emergency (e.g. responding, resolved, false_alarm).
    Restricted to authorized responders, the owner, or an administrator.
    """
    event = firestore_service.get_emergency(event_id)
    if not event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Emergency incident not found")

    verify_emergency_access(current_user, event)

    updated = firestore_service.update_emergency(event_id, {
        "event_status": status_update.event_status.value,
        "last_status_notes": status_update.notes,
    })

    record_audit_log(
        actor_uid=current_user["uid"],
        action="emergency_status_updated",
        resource_type="emergency_event",
        resource_id=event_id,
        result=AuditResult.SUCCESS,
        details={"new_status": status_update.event_status.value, "notes": status_update.notes},
    )

    return updated
