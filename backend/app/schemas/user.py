from enum import Enum
from typing import Optional, Dict, Any
from pydantic import BaseModel, EmailStr, Field, ConfigDict


class UserRole(str, Enum):
    NORMAL_USER = "normal_user"
    TRUSTED_CONTACT = "trusted_contact"
    POLICE = "police"
    HOSPITAL = "hospital"
    ADMIN = "admin"


class AccountStatus(str, Enum):
    ACTIVE = "active"
    PENDING_VERIFICATION = "pending_verification"
    SUSPENDED = "suspended"
    INACTIVE = "inactive"


class EmergencyProfile(BaseModel):
    blood_group: Optional[str] = Field(None, json_schema_extra={"example": "O+"})
    allergies: Optional[str] = Field(None, json_schema_extra={"example": "Penicillin"})
    medical_notes: Optional[str] = Field(None, json_schema_extra={"example": "Asthma"})
    emergency_note: Optional[str] = Field(None, json_schema_extra={"example": "In case of emergency call spouse first"})


class UserProfileCreate(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    emergency_profile: Optional[EmergencyProfile] = None


class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    emergency_profile: Optional[EmergencyProfile] = None
    notification_preferences: Optional[Dict[str, bool]] = None


class UserProfileResponse(BaseModel):
    uid: str
    full_name: str
    email: EmailStr
    phone: Optional[str] = None
    role: UserRole
    account_status: AccountStatus
    email_verified: bool = False
    emergency_profile: Optional[Dict[str, Any]] = None
    paired_device_id: Optional[str] = None
    notification_preferences: Optional[Dict[str, bool]] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
