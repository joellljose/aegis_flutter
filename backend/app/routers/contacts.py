import uuid
import logging
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth.dependencies import get_current_user
from app.auth.permissions import verify_user_owns_resource
from app.services.firestore_service import firestore_service
from app.schemas.contact import (
    ContactCreate,
    ContactUpdate,
    ContactResponse,
    InvitationStatus,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/contacts", tags=["Trusted Contacts"])


@router.post("", response_model=ContactResponse, status_code=status.HTTP_201_CREATED)
async def add_trusted_contact(
    contact_data: ContactCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Adds a new trusted contact for the device owner.
    Supports notification-only contacts without requiring a registered account.
    """
    owner_uid = current_user["uid"]
    contact_id = f"tc_{uuid.uuid4().hex[:12]}"

    prefs = (
        contact_data.notification_preferences.model_dump()
        if contact_data.notification_preferences
        else {"sms": True, "push": True, "email": True, "call": False}
    )

    data = {
        "contact_id": contact_id,
        "owner_uid": owner_uid,
        "contact_name": contact_data.contact_name,
        "phone": contact_data.phone,
        "email": contact_data.email,
        "relationship": contact_data.relationship,
        "invitation_status": InvitationStatus.PENDING.value,
        "notification_preferences": prefs,
    }

    created = firestore_service.create_contact(contact_id, data)
    logger.info("User %s added trusted contact %s", owner_uid, contact_id)
    return created


@router.get("", response_model=List[ContactResponse])
async def list_trusted_contacts(
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Lists only the contacts belonging to the authenticated user.
    """
    owner_uid = current_user["uid"]
    return firestore_service.list_user_contacts(owner_uid)


@router.patch("/{contact_id}", response_model=ContactResponse)
async def update_trusted_contact(
    contact_id: str,
    update_data: ContactUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Updates a contact's details or invitation status.
    Guarantees strict ownership verification.
    """
    contact = firestore_service.get_contact(contact_id)
    if not contact:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contact not found")

    verify_user_owns_resource(current_user, contact["owner_uid"], "contact")

    patch_dict = update_data.model_dump(exclude_unset=True)
    if "notification_preferences" in patch_dict and patch_dict["notification_preferences"] is not None:
        patch_dict["notification_preferences"] = (
            update_data.notification_preferences.model_dump()
            if update_data.notification_preferences
            else None
        )
    if "invitation_status" in patch_dict and patch_dict["invitation_status"] is not None:
        patch_dict["invitation_status"] = patch_dict["invitation_status"].value

    updated = firestore_service.update_contact(contact_id, patch_dict)
    return updated


@router.delete("/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_trusted_contact(
    contact_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Removes a trusted contact.
    Guarantees strict ownership verification.
    """
    contact = firestore_service.get_contact(contact_id)
    if not contact:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contact not found")

    verify_user_owns_resource(current_user, contact["owner_uid"], "contact")

    firestore_service.delete_contact(contact_id)
    return None
