from enum import Enum
from typing import Optional, Dict
from pydantic import BaseModel, EmailStr, Field, ConfigDict, model_validator


class InvitationStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"


class ContactNotificationPrefs(BaseModel):
    sms: bool = True
    push: bool = True
    email: bool = True
    call: bool = False


class ContactCreate(BaseModel):
    contact_name: str = Field(..., min_length=2, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    email: Optional[EmailStr] = None
    relationship: str = Field(..., min_length=2, max_length=50, json_schema_extra={"example": "Spouse"})
    notification_preferences: Optional[ContactNotificationPrefs] = None

    @model_validator(mode="after")
    def check_phone_or_email(self):
        if not self.phone and not self.email:
            raise ValueError("At least one contact method (phone or email) must be provided.")
        return self


class ContactUpdate(BaseModel):
    contact_name: Optional[str] = Field(None, min_length=2, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    email: Optional[EmailStr] = None
    relationship: Optional[str] = Field(None, min_length=2, max_length=50)
    invitation_status: Optional[InvitationStatus] = None
    notification_preferences: Optional[ContactNotificationPrefs] = None


class ContactResponse(BaseModel):
    contact_id: str
    owner_uid: str
    contact_name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    relationship: str
    invitation_status: InvitationStatus
    notification_preferences: Dict[str, bool]
    created_at: Optional[str] = None
    updated_at: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
