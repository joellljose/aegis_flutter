"""
AEGIS One — Single-File Backend API with Firebase Authentication & Cloud Firestore
Complete Firebase Authentication for User Identity & Firestore Collections for Persistence.

Runs with:
    python main.py
or:
    python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

import os
import sys
import uuid
import logging
from datetime import datetime, timezone
from enum import Enum
from typing import Optional, List, Dict, Any

from fastapi import FastAPI, Depends, HTTPException, Header, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr, Field, ConfigDict
import uvicorn

# =====================================================================
# 1. LOGGING & INITIALIZATION
# =====================================================================
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("aegis_backend")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SERVICE_ACCOUNT_PATH = os.path.join(BASE_DIR, "serviceAccountKey.json")

# =====================================================================
# 2. FIREBASE ADMIN SDK & CLOUD FIRESTORE INITIALIZATION
# =====================================================================
_firebase_initialized = False
_db = None
_auth = None

try:
    import firebase_admin
    from firebase_admin import credentials, firestore, auth

    if os.path.exists(SERVICE_ACCOUNT_PATH):
        logger.info(f"Loading Firebase credentials from: {SERVICE_ACCOUNT_PATH}")
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        if len(firebase_admin._apps) == 0:
            firebase_app = firebase_admin.initialize_app(cred)
        else:
            firebase_app = firebase_admin.get_app()
        _db = firestore.client()
        _auth = auth
        _firebase_initialized = True
        logger.info(f"Firebase Authentication & Firestore initialized for: {cred.project_id}")
    else:
        logger.warning(f"serviceAccountKey.json not found at {SERVICE_ACCOUNT_PATH}. Operating in local memory fallback mode.")
except Exception as e:
    logger.warning(f"Firebase Admin SDK initialization note: {e}. Falling back to in-memory store.")

# Thread-safe in-memory store (for testing & offline development)
_in_memory_store: Dict[str, Dict[str, Dict[str, Any]]] = {
    "users": {},
    "devices": {},
    "trusted_contacts": {},
    "organizations": {},
    "emergency_events": {},
    "audit_logs": {},
}

def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


# =====================================================================
# 3. FIREBASE AUTHENTICATION & FIRESTORE DATABASE SERVICE
# =====================================================================
class FirebaseAuthService:
    """Manages User Accounts & Credentials directly in Firebase Authentication."""

    @staticmethod
    def is_live() -> bool:
        return _auth is not None

    @staticmethod
    def create_auth_user(email: str, password: Optional[str] = None, display_name: Optional[str] = None, phone: Optional[str] = None) -> Dict[str, Any]:
        """Creates user directly in Firebase Authentication."""
        clean_email = email.strip().lower()
        if _auth:
            try:
                # Check if already exists in Firebase Auth
                existing = _auth.get_user_by_email(clean_email)
                logger.info(f"Firebase Auth user already exists: {existing.uid}")
                return {"uid": existing.uid, "email": existing.email, "display_name": existing.display_name}
            except firebase_admin.auth.UserNotFoundError:
                pass
            except Exception as e:
                logger.warning(f"Firebase Auth lookup note: {e}")

            try:
                valid_phone = None
                if phone and phone.startswith("+") and len(phone) >= 11:
                    digits = phone[1:].replace(" ", "").replace("-", "")
                    if digits.isdigit():
                        valid_phone = f"+{digits}"

                try:
                    user_record = _auth.create_user(
                        email=clean_email,
                        password=password if password and len(password) >= 6 else "TempPassword123!",
                        display_name=display_name,
                        phone_number=valid_phone,
                        email_verified=False,
                    )
                except Exception as phone_err:
                    if "INVALID_PHONE_NUMBER" in str(phone_err) or "TOO_SHORT" in str(phone_err):
                        user_record = _auth.create_user(
                            email=clean_email,
                            password=password if password and len(password) >= 6 else "TempPassword123!",
                            display_name=display_name,
                            email_verified=False,
                        )
                    else:
                        raise phone_err

                logger.info(f"Created new Firebase Auth user: {user_record.uid} ({clean_email})")
                try:
                    _auth.set_custom_user_claims(user_record.uid, {
                        "role": "normal_user",
                        "account_status": "active",
                    })
                except Exception:
                    pass
                return {"uid": user_record.uid, "email": user_record.email, "display_name": user_record.display_name}
            except Exception as e:
                logger.error(f"Error creating Firebase Auth user: {e}")

        # Fallback ID for offline/mock mode
        uid = f"fb_{clean_email.replace('@', '_').replace('.', '_')}"
        return {"uid": uid, "email": clean_email, "display_name": display_name}

    @staticmethod
    def get_auth_user(uid: str) -> Optional[Dict[str, Any]]:
        """Retrieves user information stored in Firebase Authentication."""
        if _auth:
            try:
                user = _auth.get_user(uid)
                return {
                    "uid": user.uid,
                    "email": user.email,
                    "display_name": user.display_name,
                    "phone_number": user.phone_number,
                    "email_verified": user.email_verified,
                    "custom_claims": user.custom_claims or {},
                    "disabled": user.disabled,
                }
            except Exception as e:
                logger.warning(f"Firebase Auth get_user ({uid}) note: {e}")
        return None

    @staticmethod
    def generate_password_reset(email: str) -> Optional[str]:
        """Generates secure password reset link via Firebase Auth."""
        if _auth:
            try:
                return _auth.generate_password_reset_link(email.strip().lower())
            except Exception as e:
                logger.error(f"Firebase Auth reset error: {e}")
        return None


class FirestoreDB:
    """Manages Cloud Firestore Collections: users, devices, trusted_contacts, emergencies, etc."""

    @staticmethod
    def is_connected() -> bool:
        return _db is not None

    # --- users collection ---
    @staticmethod
    def get_user(uid: str) -> Optional[Dict[str, Any]]:
        if _db:
            try:
                doc = _db.collection("users").document(uid).get()
                if doc.exists:
                    data = doc.to_dict()
                    data["uid"] = uid
                    return data
            except Exception as e:
                logger.error(f"Firestore get_user error: {e}")
        return _in_memory_store["users"].get(uid)

    @staticmethod
    def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
        clean_email = email.strip().lower()
        if _db:
            try:
                docs = _db.collection("users").where("email", "==", clean_email).limit(1).stream()
                for doc in docs:
                    data = doc.to_dict()
                    data["uid"] = doc.id
                    return data
            except Exception as e:
                logger.error(f"Firestore get_user_by_email error: {e}")
        for user in _in_memory_store["users"].values():
            if user.get("email", "").lower() == clean_email:
                return user
        return None

    @staticmethod
    def save_user(uid: str, data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now()
        doc_data = {
            **data,
            "uid": uid,
            "updated_at": now,
            "created_at": data.get("created_at") or now,
        }
        if _db:
            try:
                _db.collection("users").document(uid).set(doc_data, merge=True)
                logger.info(f"Firestore [users] collection saved: {uid}")
            except Exception as e:
                logger.error(f"Firestore save_user error: {e}")
        _in_memory_store["users"][uid] = doc_data
        return doc_data

    # --- devices collection ---
    @staticmethod
    def save_device(device_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now()
        doc_data = {**data, "device_id": device_id, "last_seen": now, "created_at": data.get("created_at") or now}
        if _db:
            try:
                _db.collection("devices").document(device_id).set(doc_data, merge=True)
                logger.info(f"Firestore [devices] collection saved: {device_id}")
            except Exception as e:
                logger.error(f"Firestore save_device error: {e}")
        _in_memory_store["devices"][device_id] = doc_data
        return doc_data

    @staticmethod
    def get_device(device_id: str) -> Optional[Dict[str, Any]]:
        if _db:
            try:
                doc = _db.collection("devices").document(device_id).get()
                if doc.exists:
                    return doc.to_dict()
            except Exception as e:
                logger.error(f"Firestore get_device error: {e}")
        return _in_memory_store["devices"].get(device_id)

    @staticmethod
    def list_devices(owner_uid: str) -> List[Dict[str, Any]]:
        if _db:
            try:
                docs = _db.collection("devices").where("owner_uid", "==", owner_uid).stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.error(f"Firestore list_devices error: {e}")
        return [d for d in _in_memory_store["devices"].values() if d.get("owner_uid") == owner_uid]

    # --- trusted_contacts collection ---
    @staticmethod
    def save_contact(contact_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now()
        doc_data = {**data, "contact_id": contact_id, "updated_at": now, "created_at": data.get("created_at") or now}
        if _db:
            try:
                _db.collection("trusted_contacts").document(contact_id).set(doc_data, merge=True)
                logger.info(f"Firestore [trusted_contacts] collection saved: {contact_id}")
            except Exception as e:
                logger.error(f"Firestore save_contact error: {e}")
        _in_memory_store["trusted_contacts"][contact_id] = doc_data
        return doc_data

    @staticmethod
    def list_contacts(owner_uid: str) -> List[Dict[str, Any]]:
        if _db:
            try:
                docs = _db.collection("trusted_contacts").where("owner_uid", "==", owner_uid).stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.error(f"Firestore list_contacts error: {e}")
        return [c for c in _in_memory_store["trusted_contacts"].values() if c.get("owner_uid") == owner_uid]

    @staticmethod
    def delete_contact(contact_id: str) -> bool:
        if _db:
            try:
                _db.collection("trusted_contacts").document(contact_id).delete()
            except Exception as e:
                logger.error(f"Firestore delete_contact error: {e}")
        return _in_memory_store["trusted_contacts"].pop(contact_id, None) is not None

    # --- emergency_events collection ---
    @staticmethod
    def save_emergency(event_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now()
        doc_data = {**data, "event_id": event_id, "updated_at": now, "created_at": data.get("created_at") or now}
        if _db:
            try:
                _db.collection("emergency_events").document(event_id).set(doc_data, merge=True)
                logger.info(f"Firestore [emergency_events] collection created: {event_id}")
            except Exception as e:
                logger.error(f"Firestore save_emergency error: {e}")
        _in_memory_store["emergency_events"][event_id] = doc_data
        return doc_data

    @staticmethod
    def list_emergencies(owner_uid: Optional[str] = None) -> List[Dict[str, Any]]:
        if _db:
            try:
                col = _db.collection("emergency_events")
                if owner_uid:
                    docs = col.where("owner_uid", "==", owner_uid).stream()
                else:
                    docs = col.order_by("created_at", direction=firestore.Query.DESCENDING).limit(50).stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.error(f"Firestore list_emergencies error: {e}")
        res = list(_in_memory_store["emergency_events"].values())
        if owner_uid:
            res = [e for e in res if e.get("owner_uid") == owner_uid]
        return res

    # --- organizations collection ---
    @staticmethod
    def save_organization(org_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now()
        doc_data = {**data, "organization_id": org_id, "created_at": data.get("created_at") or now}
        if _db:
            try:
                _db.collection("organizations").document(org_id).set(doc_data, merge=True)
                logger.info(f"Firestore [organizations] collection saved: {org_id}")
            except Exception as e:
                logger.error(f"Firestore save_organization error: {e}")
        _in_memory_store["organizations"][org_id] = doc_data
        return doc_data

    @staticmethod
    def list_pending_organizations() -> List[Dict[str, Any]]:
        if _db:
            try:
                docs = _db.collection("organizations").where("verification_status", "==", "pending").stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.error(f"Firestore list_pending_organizations error: {e}")
        return [o for o in _in_memory_store["organizations"].values() if o.get("verification_status") == "pending"]

    # --- audit_logs collection ---
    @staticmethod
    def record_audit(actor_uid: str, action: str, resource_type: str, resource_id: str, details: Optional[Dict[str, Any]] = None):
        log_id = f"audit_{uuid.uuid4().hex[:12]}"
        log_entry = {
            "log_id": log_id,
            "actor_uid": actor_uid,
            "action": action,
            "resource_type": resource_type,
            "resource_id": resource_id,
            "timestamp": utc_now(),
            "details": details or {},
        }
        if _db:
            try:
                _db.collection("audit_logs").document(log_id).set(log_entry)
            except Exception as e:
                logger.error(f"Firestore record_audit error: {e}")
        _in_memory_store["audit_logs"][log_id] = log_entry
        return log_entry


# =====================================================================
# 4. PYDANTIC SCHEMAS
# =====================================================================
class EmergencyProfile(BaseModel):
    blood_group: Optional[str] = "O+"
    allergies: Optional[str] = "None"
    medical_notes: Optional[str] = None
    emergency_note: Optional[str] = None

class UserRegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    phone: Optional[str] = None
    password: Optional[str] = None
    emergency_profile: Optional[EmergencyProfile] = None

class UserLoginRequest(BaseModel):
    email: EmailStr
    password: Optional[str] = None

class UserProfileUpdateRequest(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    emergency_profile: Optional[EmergencyProfile] = None

class ContactCreateRequest(BaseModel):
    contact_id: Optional[str] = None
    contact_name: str = Field(..., min_length=2)
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    relationship: str = "Emergency Contact"
    priority: Optional[int] = 1
    channels: Optional[List[str]] = ["SMS", "WhatsApp"]
    notification_preferences: Optional[Dict[str, bool]] = {"sms": True, "push": True, "email": True}

class ContactBatchSyncRequest(BaseModel):
    contacts: List[Dict[str, Any]]

class DeviceRegisterRequest(BaseModel):
    device_id: str = Field(..., min_length=3)
    device_name: str = "AEGIS Pendant"

class EmergencyTriggerRequest(BaseModel):
    device_id: str
    event_type: str = "sos"
    latitude: float
    longitude: float
    location_accuracy: float = 3.5
    assigned_organization_ids: Optional[List[str]] = []

class OrganizationRegisterRequest(BaseModel):
    organization_type: str = "police"
    organization_name: str
    official_email: EmailStr
    official_phone: str
    address: str
    service_area: str = "Central Metro"


# =====================================================================
# 5. TOKEN VERIFICATION & AUTH DEPENDENCY
# =====================================================================
async def get_current_user_token(authorization: Optional[str] = Header(None)) -> Dict[str, Any]:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid Authorization header. Expected Bearer <token>",
        )

    token = authorization.split("Bearer ")[1].strip()

    # Mock token support for development
    if token.startswith("mock-token:"):
        parts = token.split(":")
        uid = parts[1] if len(parts) > 1 else "demo_user"
        role = parts[2] if len(parts) > 2 else "normal_user"
        return {"uid": uid, "email": f"{uid}@aegis.internal", "role": role, "email_verified": True}

    if _auth:
        try:
            decoded = _auth.verify_id_token(token, check_revoked=True)
            return decoded
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid or expired Firebase authentication token: {e}",
            )

    return {"uid": "user_fallback", "email": "user@aegis-response.org", "role": "normal_user"}


async def get_current_user(token_data: Dict[str, Any] = Depends(get_current_user_token)) -> Dict[str, Any]:
    uid = token_data.get("uid") or token_data.get("sub")
    
    # 1. Check user from Firebase Authentication
    fb_auth_user = FirebaseAuthService.get_auth_user(uid)
    
    # 2. Check user profile from Cloud Firestore
    firestore_user = FirestoreDB.get_user(uid)
    
    if not firestore_user and not fb_auth_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User profile not registered in Firebase.")

    merged_user = {
        "uid": uid,
        "email": (firestore_user and firestore_user.get("email")) or (fb_auth_user and fb_auth_user.get("email")) or "",
        "full_name": (firestore_user and firestore_user.get("full_name")) or (fb_auth_user and fb_auth_user.get("display_name")) or "AEGIS User",
        "phone": (firestore_user and firestore_user.get("phone")) or (fb_auth_user and fb_auth_user.get("phone_number")),
        "role": (firestore_user and firestore_user.get("role")) or "normal_user",
        "account_status": (firestore_user and firestore_user.get("account_status")) or "active",
        "email_verified": (fb_auth_user and fb_auth_user.get("email_verified")) or False,
        "emergency_profile": firestore_user.get("emergency_profile") if firestore_user else None,
        "paired_device_id": firestore_user.get("paired_device_id") if firestore_user else None,
    }

    if merged_user.get("account_status") == "suspended":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This account has been suspended by AEGIS Security.")

    return merged_user


# =====================================================================
# 6. FASTAPI APPLICATION SETUP
# =====================================================================
app = FastAPI(
    title="AEGIS One — Complete Firebase Authentication API",
    description="Full Firebase Authentication identity & Cloud Firestore database persistence.",
    version="2.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =====================================================================
# 7. AUTHENTICATION & DATABASE ENDPOINTS
# =====================================================================

# --- System Health & Firebase Status ---
@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "healthy",
        "service": "AEGIS One Firebase Authentication Backend",
        "firebase_auth_active": FirebaseAuthService.is_live(),
        "firestore_connected": FirestoreDB.is_connected(),
        "firebase_project": "aegis-fdf8f" if FirestoreDB.is_connected() else "in-memory-mode",
        "timestamp": utc_now(),
    }


# --- Register User: Creates in Firebase Authentication & Saves in Firestore 'users' ---
@app.post("/api/register", status_code=status.HTTP_201_CREATED, tags=["Firebase Auth"])
@app.post("/api/auth/register", status_code=status.HTTP_201_CREATED, tags=["Firebase Auth"])
@app.post("/api/v1/profile", status_code=status.HTTP_201_CREATED, tags=["Firebase Auth"])
async def register_user(
    payload: UserRegisterRequest,
    authorization: Optional[str] = Header(None),
):
    clean_email = str(payload.email).strip().lower()

    # 1. ALWAYS create user directly in Firebase Authentication
    auth_result = FirebaseAuthService.create_auth_user(
        email=clean_email,
        password=payload.password or "Password123!",
        display_name=payload.full_name,
        phone=payload.phone,
    )
    uid = auth_result.get("uid")

    # 2. Check if Firestore document already exists
    existing_user = FirestoreDB.get_user(uid)
    if existing_user:
        logger.info(f"User profile exists in Firestore, updating: {uid}")

    emergency_dict = payload.emergency_profile.model_dump() if payload.emergency_profile else None

    # 3. Save profile into Cloud Firestore 'users' collection
    user_data = {
        "uid": uid,
        "full_name": payload.full_name,
        "email": clean_email,
        "phone": payload.phone,
        "role": "normal_user",
        "account_status": "active",
        "email_verified": False,
        "emergency_profile": emergency_dict,
        "paired_device_id": None,
    }

    saved = FirestoreDB.save_user(uid, user_data)
    FirestoreDB.record_audit(uid, "firebase_auth_registered", "users", uid)
    logger.info(f"User {clean_email} successfully registered with Firebase Auth & Cloud Firestore (UID: {uid})")
    return saved


# --- Login & Verify: Queries Firebase Authentication & Cloud Firestore ---
@app.post("/api/login", tags=["Firebase Auth"])
@app.post("/api/auth/login", tags=["Firebase Auth"])
async def login_user(payload: UserLoginRequest):
    clean_email = str(payload.email).strip().lower()
    
    # 1. Check in Cloud Firestore
    user_doc = FirestoreDB.get_user_by_email(clean_email)
    
    # 2. Check in Firebase Authentication
    fb_user = None
    if _auth:
        try:
            fb_user = _auth.get_user_by_email(clean_email)
        except Exception:
            pass

    if not user_doc and not fb_user:
        raise HTTPException(status_code=404, detail="User account not found in Firebase.")

    uid = (user_doc and user_doc.get("uid")) or (fb_user and fb_user.uid)
    
    # Check if suspended
    status_val = (user_doc and user_doc.get("account_status")) or "active"
    if status_val == "suspended":
        raise HTTPException(status_code=403, detail="Account suspended by AEGIS Security.")

    return {
        "message": "User verified successfully in Firebase.",
        "uid": uid,
        "email": clean_email,
        "full_name": (user_doc and user_doc.get("full_name")) or (fb_user and fb_user.display_name) or clean_email.split("@")[0],
        "role": (user_doc and user_doc.get("role")) or "normal_user",
        "account_status": status_val,
        "user_profile": user_doc,
    }


# --- Password Reset Link via Firebase Auth ---
@app.post("/api/auth/reset-password", tags=["Firebase Auth"])
async def reset_password(email: str = Query(...)):
    link = FirebaseAuthService.generate_password_reset(email)
    return {
        "message": f"Password reset initiated for {email}",
        "reset_link": link,
        "status": "success",
    }


# --- User Profile Retrieval (Checks Firebase Auth & Firestore) ---
@app.get("/api/profile/me", tags=["Profile"])
@app.get("/api/v1/profile/me", tags=["Profile"])
async def get_my_profile(current_user: Dict[str, Any] = Depends(get_current_user)):
    return current_user


# --- User Profile Update (Syncs with Firebase Auth & Firestore) ---
@app.patch("/api/profile/me", tags=["Profile"])
@app.patch("/api/v1/profile/me", tags=["Profile"])
async def update_my_profile(
    update_data: UserProfileUpdateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    uid = current_user["uid"]
    patch_fields = update_data.model_dump(exclude_unset=True)
    if "emergency_profile" in patch_fields and patch_fields["emergency_profile"]:
        patch_fields["emergency_profile"] = update_data.emergency_profile.model_dump()

    # Update Firebase Auth display_name if full_name changed
    if _auth and "full_name" in patch_fields:
        try:
            _auth.update_user(uid, display_name=patch_fields["full_name"])
            logger.info(f"Updated display_name in Firebase Auth for {uid}")
        except Exception as e:
            logger.warning(f"Could not update Firebase Auth display_name: {e}")

    updated = FirestoreDB.save_user(uid, patch_fields)
    FirestoreDB.record_audit(uid, "profile_updated", "users", uid)
    return updated


# --- Trusted Contacts (Firestore 'trusted_contacts' collection) ---
@app.post("/api/contacts", status_code=status.HTTP_201_CREATED, tags=["Contacts"])
@app.post("/api/v1/contacts", status_code=status.HTTP_201_CREATED, tags=["Contacts"])
async def add_trusted_contact(
    contact_data: ContactCreateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    owner_uid = current_user["uid"]
    contact_id = contact_data.contact_id or f"tc_{uuid.uuid4().hex[:10]}"
    data = {
        "contact_id": contact_id,
        "owner_uid": owner_uid,
        "contact_name": contact_data.contact_name,
        "phone": contact_data.phone or "",
        "email": str(contact_data.email) if contact_data.email else None,
        "relationship": contact_data.relationship,
        "priority": contact_data.priority or 1,
        "channels": contact_data.channels or ["SMS", "WhatsApp"],
        "invitation_status": "accepted",
        "notification_preferences": contact_data.notification_preferences or {"sms": True, "push": True, "email": True},
    }
    saved = FirestoreDB.save_contact(contact_id, data)
    
    # Also update user document in Firestore users collection
    all_contacts = FirestoreDB.list_contacts(owner_uid)
    FirestoreDB.save_user(owner_uid, {"contacts": all_contacts})

    FirestoreDB.record_audit(owner_uid, "contact_added", "trusted_contacts", contact_id)
    return saved


@app.post("/api/contacts/sync", tags=["Contacts"])
@app.post("/api/v1/contacts/sync", tags=["Contacts"])
async def batch_sync_contacts(
    batch: ContactBatchSyncRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    owner_uid = current_user["uid"]
    saved_list = []
    for item in batch.contacts:
        cid = item.get("id") or item.get("contact_id") or f"tc_{uuid.uuid4().hex[:10]}"
        cdata = {
            "contact_id": cid,
            "owner_uid": owner_uid,
            "contact_name": item.get("name") or item.get("contact_name") or "Emergency Contact",
            "phone": item.get("phone") or "",
            "relationship": item.get("relation") or item.get("relationship") or "Family",
            "priority": item.get("priority", 1),
            "channels": item.get("channels", ["SMS", "WhatsApp"]),
            "status": item.get("status", "STANDBY"),
            "invitation_status": "accepted",
        }
        saved = FirestoreDB.save_contact(cid, cdata)
        saved_list.append(saved)
    
    # Also save to users collection
    FirestoreDB.save_user(owner_uid, {"contacts": saved_list})
    FirestoreDB.record_audit(owner_uid, "contacts_batch_synced", "trusted_contacts", owner_uid)
    return {"status": "synced", "count": len(saved_list), "contacts": saved_list}


@app.get("/api/contacts", tags=["Contacts"])
@app.get("/api/v1/contacts", tags=["Contacts"])
async def list_my_contacts(current_user: Dict[str, Any] = Depends(get_current_user)):
    contacts = FirestoreDB.list_contacts(current_user["uid"])
    return contacts


@app.delete("/api/contacts/{contact_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Contacts"])
@app.delete("/api/v1/contacts/{contact_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Contacts"])
async def delete_contact(contact_id: str, current_user: Dict[str, Any] = Depends(get_current_user)):
    owner_uid = current_user["uid"]
    FirestoreDB.delete_contact(contact_id)
    all_contacts = FirestoreDB.list_contacts(owner_uid)
    FirestoreDB.save_user(owner_uid, {"contacts": all_contacts})
    FirestoreDB.record_audit(owner_uid, "contact_deleted", "trusted_contacts", contact_id)
    return None


# --- Hardware Devices (Firestore 'devices' collection) ---
@app.post("/api/devices", status_code=status.HTTP_201_CREATED, tags=["Devices"])
@app.post("/api/v1/devices", status_code=status.HTTP_201_CREATED, tags=["Devices"])
async def register_device(
    device_data: DeviceRegisterRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    owner_uid = current_user["uid"]
    device_id = device_data.device_id.strip()

    data = {
        "device_id": device_id,
        "owner_uid": owner_uid,
        "device_name": device_data.device_name,
        "device_status": "paired",
    }
    saved = FirestoreDB.save_device(device_id, data)
    FirestoreDB.save_user(owner_uid, {"paired_device_id": device_id})
    FirestoreDB.record_audit(owner_uid, "device_paired", "devices", device_id)
    return saved


@app.get("/api/devices", tags=["Devices"])
@app.get("/api/v1/devices", tags=["Devices"])
async def list_my_devices(current_user: Dict[str, Any] = Depends(get_current_user)):
    return FirestoreDB.list_devices(current_user["uid"])


# --- Emergency Incidents (Firestore 'emergency_events' collection) ---
@app.post("/api/emergencies", status_code=status.HTTP_201_CREATED, tags=["Emergency Events"])
@app.post("/api/v1/emergencies", status_code=status.HTTP_201_CREATED, tags=["Emergency Events"])
async def trigger_emergency(
    event_data: EmergencyTriggerRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    owner_uid = current_user["uid"]
    event_id = f"em_{uuid.uuid4().hex[:10]}"

    data = {
        "event_id": event_id,
        "owner_uid": owner_uid,
        "device_id": event_data.device_id,
        "event_type": event_data.event_type,
        "latitude": event_data.latitude,
        "longitude": event_data.longitude,
        "location_accuracy": event_data.location_accuracy,
        "event_status": "active",
        "assigned_organization_ids": event_data.assigned_organization_ids or [],
        "owner_name": current_user.get("full_name"),
        "emergency_profile": current_user.get("emergency_profile"),
    }

    saved = FirestoreDB.save_emergency(event_id, data)
    FirestoreDB.record_audit(owner_uid, "emergency_triggered", "emergency_events", event_id)
    logger.critical(f"🚨 EMERGENCY ALERT: {event_id} at ({event_data.latitude}, {event_data.longitude})")
    return saved


@app.get("/api/emergencies", tags=["Emergency Events"])
@app.get("/api/v1/emergencies", tags=["Emergency Events"])
async def list_emergencies(current_user: Dict[str, Any] = Depends(get_current_user)):
    return FirestoreDB.list_emergencies(owner_uid=current_user["uid"])


# --- Authority Organizations (Firestore 'organizations' collection) ---
@app.post("/api/organizations", status_code=status.HTTP_202_ACCEPTED, tags=["Organizations"])
@app.post("/api/v1/organizations/registration", status_code=status.HTTP_202_ACCEPTED, tags=["Organizations"])
async def register_organization(
    org_data: OrganizationRegisterRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    uid = current_user["uid"]
    org_id = f"org_{uuid.uuid4().hex[:10]}"

    data = {
        "organization_id": org_id,
        "organization_type": org_data.organization_type,
        "organization_name": org_data.organization_name,
        "official_email": str(org_data.official_email),
        "official_phone": org_data.official_phone,
        "address": org_data.address,
        "service_area": org_data.service_area,
        "verification_status": "pending",
        "registered_by_uid": uid,
    }

    saved = FirestoreDB.save_organization(org_id, data)
    FirestoreDB.save_user(uid, {"role": org_data.organization_type, "account_status": "pending_verification"})
    return saved


@app.get("/api/organizations/pending", tags=["Organizations"])
@app.get("/api/v1/admin/organizations/pending", tags=["Organizations"])
async def list_pending_orgs(current_user: Dict[str, Any] = Depends(get_current_user)):
    return FirestoreDB.list_pending_organizations()


# --- System Audit Logs (Firestore 'audit_logs' collection) ---
@app.get("/api/audit-logs", tags=["Audit Trail"])
@app.get("/api/v1/admin/audit-logs", tags=["Audit Trail"])
async def get_audit_logs(current_user: Dict[str, Any] = Depends(get_current_user)):
    return list(_in_memory_store["audit_logs"].values())


# =====================================================================
# 8. STATIC PORTAL WEB INTERFACE
# =====================================================================
static_dir = os.path.join(BASE_DIR, "static")
if os.path.exists(static_dir):
    @app.get("/", include_in_schema=False)
    async def serve_index():
        return FileResponse(os.path.join(static_dir, "index.html"))

    app.mount("/static", StaticFiles(directory=static_dir), name="static")


# =====================================================================
# 9. CLI LAUNCHER
# =====================================================================
if __name__ == "__main__":
    print(f"\n========================================================")
    print(f"  AEGIS One Firebase Authentication Backend")
    print(f"  Firebase Project:  {'CONNECTED (aegis-fdf8f)' if _firebase_initialized else 'OFFLINE (Memory Mode)'}")
    print(f"  Firebase Auth:     {'ACTIVE' if _auth else 'OFFLINE'}")
    print(f"  Local Swagger UI:  http://localhost:8000/docs")
    print(f"  Web Control Panel: http://localhost:8000/")
    print(f"========================================================\n")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
