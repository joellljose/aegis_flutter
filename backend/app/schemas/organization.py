from enum import Enum
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, ConfigDict


class OrganizationType(str, Enum):
    POLICE = "police"
    HOSPITAL = "hospital"
    AMBULANCE = "ambulance"


class VerificationStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class OrganizationRegistrationCreate(BaseModel):
    organization_type: OrganizationType
    organization_name: str = Field(..., min_length=2, max_length=150)
    official_email: EmailStr
    official_phone: str = Field(..., min_length=5, max_length=25)
    address: str = Field(..., min_length=5, max_length=255)
    service_area: str = Field(..., min_length=2, max_length=100, json_schema_extra={"example": "Central District / Zone 4"})


class OrganizationVerificationUpdate(BaseModel):
    verification_status: VerificationStatus
    admin_notes: Optional[str] = Field(None, max_length=500)


class OrganizationResponse(BaseModel):
    organization_id: str
    organization_type: OrganizationType
    organization_name: str
    official_email: EmailStr
    official_phone: str
    address: str
    verification_status: VerificationStatus
    service_area: str
    registered_by_uid: Optional[str] = None
    admin_notes: Optional[str] = None
    created_at: Optional[str] = None
    verified_at: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
