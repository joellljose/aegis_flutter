from enum import Enum
from typing import Optional, Dict, Any
from pydantic import BaseModel, ConfigDict


class AuditResult(str, Enum):
    SUCCESS = "success"
    DENIED = "denied"
    FAILED = "failed"


class AuditLogCreate(BaseModel):
    actor_uid: str
    action: str
    resource_type: str
    resource_id: str
    result: AuditResult = AuditResult.SUCCESS
    details: Optional[Dict[str, Any]] = None


class AuditLogResponse(BaseModel):
    log_id: str
    actor_uid: str
    action: str
    resource_type: str
    resource_id: str
    timestamp: str
    result: AuditResult
    details: Optional[Dict[str, Any]] = None

    model_config = ConfigDict(from_attributes=True)
