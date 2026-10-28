from typing import Dict, Any
from fastapi import HTTPException, status
from app.schemas.user import UserRole, AccountStatus
from app.services.firestore_service import firestore_service


def verify_user_owns_resource(current_user: Dict[str, Any], resource_owner_uid: str, resource_name: str = "resource"):
    """
    Ensures that the current user matches the owner_uid of the resource.
    Prevents Horizontal Privilege Escalation.
    """
    if current_user.get("uid") != resource_owner_uid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access denied: You do not have permission to access or modify this {resource_name}.",
        )


def verify_emergency_access(current_user: Dict[str, Any], emergency_event: Dict[str, Any]) -> bool:
    """
    Checks if current_user is authorized to view or manage an emergency event:
    1. Owner of the emergency.
    2. Admin has system audit access.
    3. Police / Hospital if their verified organization_id is in assigned_organization_ids.
    4. Trusted contact of the owner if owner authorized contacts.
    """
    uid = current_user.get("uid")
    role = current_user.get("role")
    owner_uid = emergency_event.get("owner_uid")

    # 1. Direct Owner
    if uid == owner_uid:
        return True

    # 2. System Admin
    if role == UserRole.ADMIN.value:
        return True

    # 3. Verified Emergency Responders (Police/Hospital)
    if role in [UserRole.POLICE.value, UserRole.HOSPITAL.value]:
        if current_user.get("account_status") != AccountStatus.ACTIVE.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Organization account is not verified by administrator.",
            )
        # Check organization assignment
        org = firestore_service.get_user_organization(uid)
        assigned_orgs = emergency_event.get("assigned_organization_ids") or []
        if org and org.get("organization_id") in assigned_orgs:
            return True
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This emergency case has not been routed to your organization.",
        )

    # 4. Trusted Contact
    if role == UserRole.TRUSTED_CONTACT.value:
        # Check if this user is a confirmed trusted contact for the owner
        contacts = firestore_service.list_user_contacts(owner_uid)
        user_email = current_user.get("email")
        user_phone = current_user.get("phone")
        for c in contacts:
            is_matching = (user_email and c.get("email") == user_email) or (user_phone and c.get("phone") == user_phone)
            if is_matching and c.get("invitation_status") == "accepted":
                return True
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized by the device owner to view this emergency.",
        )

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Unauthorized to access this emergency case.",
    )
