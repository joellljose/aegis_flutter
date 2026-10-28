import uuid
import logging
from typing import Optional, Dict, Any
from app.services.firestore_service import firestore_service
from app.schemas.audit import AuditResult

logger = logging.getLogger(__name__)


def record_audit_log(
    actor_uid: str,
    action: str,
    resource_type: str,
    resource_id: str,
    result: AuditResult = AuditResult.SUCCESS,
    details: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Persist an audit log entry for sensitive administrative or authorization events.
    """
    log_id = f"audit_{uuid.uuid4().hex}"
    log_data = {
        "actor_uid": actor_uid,
        "action": action,
        "resource_type": resource_type,
        "resource_id": resource_id,
        "result": result.value if isinstance(result, AuditResult) else str(result),
        "details": details or {},
    }
    logger.info("AUDIT: [%s] Actor: %s Action: %s Resource: %s/%s Result: %s",
                log_id, actor_uid, action, resource_type, resource_id, result)
    return firestore_service.create_audit_log(log_id, log_data)
