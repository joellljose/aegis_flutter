import logging
from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth.dependencies import get_token_payload, get_current_user
from app.services.firestore_service import firestore_service
from app.schemas.user import (
    UserProfileCreate,
    UserProfileUpdate,
    UserProfileResponse,
    UserRole,
    AccountStatus,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/profile", tags=["Profile"])


@router.post("", response_model=UserProfileResponse, status_code=status.HTTP_201_CREATED)
async def create_profile(
    profile_data: UserProfileCreate,
    token_payload: Dict[str, Any] = Depends(get_token_payload),
):
    """
    Creates a new user profile for an authenticated Firebase user.
    The UID is cryptographically derived from the verified token.
    Prevents self-escalation of roles: default role is always normal_user.
    """
    uid = token_payload.get("uid") or token_payload.get("sub")
    if not uid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid token UID")

    # Check if profile already exists
    existing = firestore_service.get_user(uid)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User profile already exists for this account.",
        )

    email = token_payload.get("email") or f"{uid}@aegis-user.com"
    email_verified = token_payload.get("email_verified", False)

    user_data = {
        "uid": uid,
        "full_name": profile_data.full_name,
        "email": email,
        "phone": profile_data.phone,
        "role": UserRole.NORMAL_USER.value,
        "account_status": AccountStatus.ACTIVE.value,
        "email_verified": email_verified,
        "emergency_profile": profile_data.emergency_profile.model_dump() if profile_data.emergency_profile else None,
        "paired_device_id": None,
        "notification_preferences": {
            "sms": True,
            "push": True,
            "email": True,
        },
    }

    created = firestore_service.create_user(uid, user_data)
    logger.info("Created user profile for UID: %s", uid)
    return created


@router.get("/me", response_model=UserProfileResponse)
async def get_my_profile(current_user: Dict[str, Any] = Depends(get_current_user)):
    """
    Retrieves the authenticated user's profile.
    """
    return current_user


@router.patch("/me", response_model=UserProfileResponse)
async def update_my_profile(
    update_data: UserProfileUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Updates the authenticated user's profile fields.
    Does not allow modifying UID, role, or account_status directly.
    """
    uid = current_user["uid"]
    patch_fields = update_data.model_dump(exclude_unset=True)

    if "emergency_profile" in patch_fields and patch_fields["emergency_profile"] is not None:
        patch_fields["emergency_profile"] = (
            update_data.emergency_profile.model_dump() if update_data.emergency_profile else None
        )

    updated = firestore_service.update_user(uid, patch_fields)
    return updated
