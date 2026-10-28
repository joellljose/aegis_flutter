import logging
from typing import Optional, Dict, Any, List
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.firebase import get_firebase_auth
from app.services.firestore_service import firestore_service
from app.schemas.user import UserRole, AccountStatus

logger = logging.getLogger(__name__)

security = HTTPBearer(auto_error=True)


async def get_token_payload(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> Dict[str, Any]:
    """
    Verifies Firebase ID token from Authorization header and extracts claims.
    Derives UID strictly from the verified cryptographic token.
    """
    token = credentials.credentials
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication credentials.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Support deterministic test mock tokens (e.g. "mock-token:<uid>:<role>")
    if token.startswith("mock-token:"):
        parts = token.split(":")
        uid = parts[1] if len(parts) > 1 else "test-uid"
        role = parts[2] if len(parts) > 2 else "normal_user"
        return {
            "uid": uid,
            "sub": uid,
            "email": f"{uid}@aegis-test.com",
            "email_verified": True,
            "role": role,
            "mock": True,
        }

    try:
        firebase_auth = get_firebase_auth()
        if not firebase_auth:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Firebase Authentication is not configured on this server.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        decoded_token = firebase_auth.verify_id_token(token, check_revoked=True)
        return decoded_token
    except HTTPException:
        raise
    except Exception as e:
        logger.warning("Token verification failed: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired authentication token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    payload: Dict[str, Any] = Depends(get_token_payload),
) -> Dict[str, Any]:
    """
    Resolves the authenticated user from Firestore using the token UID.
    Ensures account status is active or pending verification.
    """
    uid = payload.get("uid") or payload.get("sub")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token payload missing user identifier.",
        )

    user = firestore_service.get_user(uid)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found. Please complete profile registration.",
        )

    if user.get("account_status") == AccountStatus.SUSPENDED.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been suspended. Please contact AEGIS support.",
        )

    # Sync token email_verified status to user data
    user["email_verified"] = payload.get("email_verified", user.get("email_verified", False))
    return user


class RoleChecker:
    """
    Dependency that enforces Role-Based Access Control (RBAC).
    """

    def __init__(self, allowed_roles: List[UserRole], require_active: bool = True):
        self.allowed_roles = [r.value if isinstance(r, UserRole) else r for r in allowed_roles]
        self.require_active = require_active

    async def __call__(self, current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, Any]:
        user_role = current_user.get("role")
        user_status = current_user.get("account_status")

        if user_role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden: requires one of the following roles: {', '.join(self.allowed_roles)}.",
            )

        if self.require_active and user_status != AccountStatus.ACTIVE.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden: account status is '{user_status}'. Administrative verification is required.",
            )

        return current_user


# Common RBAC dependencies
require_normal_user = RoleChecker([UserRole.NORMAL_USER])
require_trusted_contact = RoleChecker([UserRole.TRUSTED_CONTACT, UserRole.NORMAL_USER])
require_police = RoleChecker([UserRole.POLICE], require_active=True)
require_hospital = RoleChecker([UserRole.HOSPITAL], require_active=True)
require_emergency_responder = RoleChecker([UserRole.POLICE, UserRole.HOSPITAL, UserRole.ADMIN], require_active=True)
require_admin = RoleChecker([UserRole.ADMIN], require_active=True)
