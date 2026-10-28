import logging
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from app.core.firebase import get_firestore_client

logger = logging.getLogger(__name__)


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class FirestoreService:
    """
    Data Access Layer for Cloud Firestore.
    Provides seamless fallback to in-memory store when Firestore client is not configured
    (e.g., during unit tests and offline development).
    """

    def __init__(self):
        self._in_memory: Dict[str, Dict[str, Dict[str, Any]]] = {
            "users": {},
            "devices": {},
            "trusted_contacts": {},
            "organizations": {},
            "emergency_events": {},
            "audit_logs": {},
        }

    def _get_db(self):
        return get_firestore_client()

    def clear_in_memory_data(self):
        """Used in test fixtures for isolation"""
        for col in self._in_memory:
            self._in_memory[col].clear()

    # ================= USER OPERATIONS =================
    def get_user(self, uid: str) -> Optional[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                doc = db.collection("users").document(uid).get()
                if doc.exists:
                    data = doc.to_dict()
                    data["uid"] = uid
                    return data
                return None
            except Exception as e:
                logger.warning("Firestore get_user error, fallback to memory: %s", e)
        return self._in_memory["users"].get(uid)

    def create_user(self, uid: str, user_data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now_iso()
        data = {
            **user_data,
            "uid": uid,
            "created_at": user_data.get("created_at") or now,
            "updated_at": now,
        }
        db = self._get_db()
        if db:
            try:
                db.collection("users").document(uid).set(data)
            except Exception as e:
                logger.warning("Firestore create_user error, saving to memory: %s", e)
        self._in_memory["users"][uid] = data
        return data

    def update_user(self, uid: str, update_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        existing = self.get_user(uid)
        if not existing:
            return None
        now = utc_now_iso()
        data = {**existing, **update_data, "updated_at": now}
        db = self._get_db()
        if db:
            try:
                db.collection("users").document(uid).set(data, merge=True)
            except Exception as e:
                logger.warning("Firestore update_user error: %s", e)
        self._in_memory["users"][uid] = data
        return data

    # ================= DEVICE OPERATIONS =================
    def get_device(self, device_id: str) -> Optional[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                doc = db.collection("devices").document(device_id).get()
                if doc.exists:
                    data = doc.to_dict()
                    data["device_id"] = device_id
                    return data
                return None
            except Exception as e:
                logger.warning("Firestore get_device error: %s", e)
        return self._in_memory["devices"].get(device_id)

    def list_user_devices(self, owner_uid: str) -> List[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                docs = db.collection("devices").where("owner_uid", "==", owner_uid).stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.warning("Firestore list_user_devices error: %s", e)
        return [
            d for d in self._in_memory["devices"].values()
            if d.get("owner_uid") == owner_uid
        ]

    def register_device(self, device_id: str, device_data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now_iso()
        data = {
            **device_data,
            "device_id": device_id,
            "created_at": device_data.get("created_at") or now,
            "last_seen": now,
        }
        db = self._get_db()
        if db:
            try:
                db.collection("devices").document(device_id).set(data)
            except Exception as e:
                logger.warning("Firestore register_device error: %s", e)
        self._in_memory["devices"][device_id] = data
        return data

    # ================= TRUSTED CONTACT OPERATIONS =================
    def get_contact(self, contact_id: str) -> Optional[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                doc = db.collection("trusted_contacts").document(contact_id).get()
                if doc.exists:
                    data = doc.to_dict()
                    data["contact_id"] = contact_id
                    return data
                return None
            except Exception as e:
                logger.warning("Firestore get_contact error: %s", e)
        return self._in_memory["trusted_contacts"].get(contact_id)

    def list_user_contacts(self, owner_uid: str) -> List[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                docs = db.collection("trusted_contacts").where("owner_uid", "==", owner_uid).stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.warning("Firestore list_user_contacts error: %s", e)
        return [
            c for c in self._in_memory["trusted_contacts"].values()
            if c.get("owner_uid") == owner_uid
        ]

    def create_contact(self, contact_id: str, contact_data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now_iso()
        data = {
            **contact_data,
            "contact_id": contact_id,
            "created_at": now,
            "updated_at": now,
        }
        db = self._get_db()
        if db:
            try:
                db.collection("trusted_contacts").document(contact_id).set(data)
            except Exception as e:
                logger.warning("Firestore create_contact error: %s", e)
        self._in_memory["trusted_contacts"][contact_id] = data
        return data

    def update_contact(self, contact_id: str, update_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        existing = self.get_contact(contact_id)
        if not existing:
            return None
        now = utc_now_iso()
        data = {**existing, **update_data, "updated_at": now}
        db = self._get_db()
        if db:
            try:
                db.collection("trusted_contacts").document(contact_id).set(data, merge=True)
            except Exception as e:
                logger.warning("Firestore update_contact error: %s", e)
        self._in_memory["trusted_contacts"][contact_id] = data
        return data

    def delete_contact(self, contact_id: str) -> bool:
        existing = self.get_contact(contact_id)
        if not existing:
            return False
        db = self._get_db()
        if db:
            try:
                db.collection("trusted_contacts").document(contact_id).delete()
            except Exception as e:
                logger.warning("Firestore delete_contact error: %s", e)
        self._in_memory["trusted_contacts"].pop(contact_id, None)
        return True

    # ================= ORGANIZATION OPERATIONS =================
    def get_organization(self, organization_id: str) -> Optional[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                doc = db.collection("organizations").document(organization_id).get()
                if doc.exists:
                    data = doc.to_dict()
                    data["organization_id"] = organization_id
                    return data
                return None
            except Exception as e:
                logger.warning("Firestore get_organization error: %s", e)
        return self._in_memory["organizations"].get(organization_id)

    def get_user_organization(self, registered_by_uid: str) -> Optional[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                docs = db.collection("organizations").where("registered_by_uid", "==", registered_by_uid).limit(1).stream()
                for d in docs:
                    data = d.to_dict()
                    data["organization_id"] = d.id
                    return data
            except Exception as e:
                logger.warning("Firestore get_user_organization error: %s", e)
        for org in self._in_memory["organizations"].values():
            if org.get("registered_by_uid") == registered_by_uid:
                return org
        return None

    def create_organization(self, organization_id: str, org_data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now_iso()
        data = {
            **org_data,
            "organization_id": organization_id,
            "created_at": now,
        }
        db = self._get_db()
        if db:
            try:
                db.collection("organizations").document(organization_id).set(data)
            except Exception as e:
                logger.warning("Firestore create_organization error: %s", e)
        self._in_memory["organizations"][organization_id] = data
        return data

    def list_pending_organizations(self) -> List[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                docs = db.collection("organizations").where("verification_status", "==", "pending").stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.warning("Firestore list_pending_organizations error: %s", e)
        return [
            org for org in self._in_memory["organizations"].values()
            if org.get("verification_status") == "pending"
        ]

    def update_organization(self, organization_id: str, update_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        existing = self.get_organization(organization_id)
        if not existing:
            return None
        now = utc_now_iso()
        data = {**existing, **update_data}
        if "verification_status" in update_data and update_data["verification_status"] in ["approved", "rejected"]:
            data["verified_at"] = now
        db = self._get_db()
        if db:
            try:
                db.collection("organizations").document(organization_id).set(data, merge=True)
            except Exception as e:
                logger.warning("Firestore update_organization error: %s", e)
        self._in_memory["organizations"][organization_id] = data
        return data

    # ================= EMERGENCY OPERATIONS =================
    def get_emergency(self, event_id: str) -> Optional[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                doc = db.collection("emergency_events").document(event_id).get()
                if doc.exists:
                    data = doc.to_dict()
                    data["event_id"] = event_id
                    return data
                return None
            except Exception as e:
                logger.warning("Firestore get_emergency error: %s", e)
        return self._in_memory["emergency_events"].get(event_id)

    def list_user_emergencies(self, owner_uid: str) -> List[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                docs = db.collection("emergency_events").where("owner_uid", "==", owner_uid).stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.warning("Firestore list_user_emergencies error: %s", e)
        return [
            ev for ev in self._in_memory["emergency_events"].values()
            if ev.get("owner_uid") == owner_uid
        ]

    def list_organization_emergencies(self, org_id: str) -> List[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                docs = db.collection("emergency_events").where("assigned_organization_ids", "array_contains", org_id).stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.warning("Firestore list_organization_emergencies error: %s", e)
        return [
            ev for ev in self._in_memory["emergency_events"].values()
            if org_id in (ev.get("assigned_organization_ids") or [])
        ]

    def create_emergency(self, event_id: str, event_data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now_iso()
        data = {
            **event_data,
            "event_id": event_id,
            "created_at": now,
            "updated_at": now,
        }
        db = self._get_db()
        if db:
            try:
                db.collection("emergency_events").document(event_id).set(data)
            except Exception as e:
                logger.warning("Firestore create_emergency error: %s", e)
        self._in_memory["emergency_events"][event_id] = data
        return data

    def update_emergency(self, event_id: str, update_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        existing = self.get_emergency(event_id)
        if not existing:
            return None
        now = utc_now_iso()
        data = {**existing, **update_data, "updated_at": now}
        db = self._get_db()
        if db:
            try:
                db.collection("emergency_events").document(event_id).set(data, merge=True)
            except Exception as e:
                logger.warning("Firestore update_emergency error: %s", e)
        self._in_memory["emergency_events"][event_id] = data
        return data

    # ================= AUDIT LOG OPERATIONS =================
    def create_audit_log(self, log_id: str, log_data: Dict[str, Any]) -> Dict[str, Any]:
        now = utc_now_iso()
        data = {
            **log_data,
            "log_id": log_id,
            "timestamp": log_data.get("timestamp") or now,
        }
        db = self._get_db()
        if db:
            try:
                db.collection("audit_logs").document(log_id).set(data)
            except Exception as e:
                logger.warning("Firestore create_audit_log error: %s", e)
        self._in_memory["audit_logs"][log_id] = data
        return data

    def list_audit_logs(self, limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
        db = self._get_db()
        if db:
            try:
                docs = db.collection("audit_logs").order_by("timestamp", direction="DESCENDING").limit(limit).offset(offset).stream()
                return [d.to_dict() for d in docs]
            except Exception as e:
                logger.warning("Firestore list_audit_logs error: %s", e)
        logs = list(self._in_memory["audit_logs"].values())
        logs.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        return logs[offset : offset + limit]


firestore_service = FirestoreService()
