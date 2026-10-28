from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class DeviceStatus(str, Enum):
    PAIRED = "paired"
    ONLINE = "online"
    OFFLINE = "offline"
    SOS = "sos"
    UNPAIRED = "unpaired"


class DeviceRegister(BaseModel):
    device_id: str = Field(..., min_length=4, max_length=64, json_schema_extra={"example": "AEGIS-ONE-9821"})
    device_name: str = Field(..., min_length=2, max_length=100, json_schema_extra={"example": "My AEGIS Pendant"})


class DeviceResponse(BaseModel):
    device_id: str
    owner_uid: str
    device_name: str
    device_status: DeviceStatus
    created_at: Optional[str] = None
    last_seen: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
