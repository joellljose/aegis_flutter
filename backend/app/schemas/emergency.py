from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, ConfigDict


class EmergencyType(str, Enum):
    SOS = "sos"
    FALL_DETECTION = "fall_detection"
    MEDICAL = "medical"
    MANUAL = "manual"


class EmergencyStatus(str, Enum):
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESPONDING = "responding"
    RESOLVED = "resolved"
    FALSE_ALARM = "false_alarm"


class EmergencyEventCreate(BaseModel):
    device_id: str = Field(..., min_length=3, max_length=64)
    event_type: EmergencyType = EmergencyType.SOS
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    location_accuracy: float = Field(default=5.0, ge=0.0)
    assigned_organization_ids: Optional[List[str]] = Field(default_factory=list)
    metadata: Optional[Dict[str, Any]] = None


class EmergencyStatusUpdate(BaseModel):
    event_status: EmergencyStatus
    notes: Optional[str] = Field(None, max_length=500)


class EmergencyEventResponse(BaseModel):
    event_id: str
    owner_uid: str
    device_id: str
    event_type: EmergencyType
    timestamp: str
    latitude: float
    longitude: float
    location_accuracy: float
    event_status: EmergencyStatus
    assigned_organization_ids: List[str] = Field(default_factory=list)
    owner_name: Optional[str] = None
    emergency_profile: Optional[Dict[str, Any]] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
