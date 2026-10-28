import os
import logging
from typing import Optional
import firebase_admin
from firebase_admin import credentials, auth, firestore
from app.core.config import settings

logger = logging.getLogger(__name__)

_firebase_app: Optional[firebase_admin.App] = None
_db = None


def resolve_credentials_path() -> Optional[str]:
    """
    Resolves the Firebase service account JSON file.
    Supports absolute paths, paths relative to the backend directory,
    or auto-discovery of 'serviceAccountKey.json' in the backend root.
    """
    path = settings.FIREBASE_CREDENTIALS_PATH.strip() if settings.FIREBASE_CREDENTIALS_PATH else ""
    backend_root = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))

    if path:
        if os.path.isabs(path) and os.path.exists(path):
            return path
        rel_path = os.path.join(backend_root, path)
        if os.path.exists(rel_path):
            return rel_path
        if os.path.exists(path):
            return path

    # Auto-detect default serviceAccountKey.json in backend directory
    default_key = os.path.join(backend_root, "serviceAccountKey.json")
    if os.path.exists(default_key):
        return default_key

    return None


def has_live_credentials() -> bool:
    if os.environ.get("AEGIS_TEST_MODE") == "1":
        return False
    return bool(
        resolve_credentials_path()
        or os.environ.get("FIRESTORE_EMULATOR_HOST")
        or settings.FIRESTORE_EMULATOR_HOST
    )


def initialize_firebase() -> Optional[firebase_admin.App]:
    global _firebase_app, _db

    if _firebase_app is not None:
        return _firebase_app

    if not has_live_credentials():
        logger.info("No live Firebase credentials or emulator configured. Operating in local in-memory fallback mode.")
        _db = None
        return None

    try:
        if len(firebase_admin._apps) > 0:
            _firebase_app = firebase_admin.get_app()
            _db = firestore.client()
            return _firebase_app

        cred_path = resolve_credentials_path()
        if cred_path:
            logger.info("Loading Firebase credentials from %s", cred_path)
            cred = credentials.Certificate(cred_path)
            _firebase_app = firebase_admin.initialize_app(cred, {
                'projectId': settings.FIREBASE_PROJECT_ID
            })
        else:
            _firebase_app = firebase_admin.initialize_app(options={
                'projectId': settings.FIREBASE_PROJECT_ID
            })

        try:
            _db = firestore.client()
        except Exception as e:
            logger.warning("Firestore client initialization deferred: %s", e)
            _db = None

        return _firebase_app
    except Exception as e:
        logger.error("Failed to initialize Firebase Admin SDK: %s", e)
        raise e


def get_firestore_client():
    global _db
    if not has_live_credentials():
        return None
    if _db is None:
        initialize_firebase()
    return _db


def get_firebase_auth():
    if not has_live_credentials():
        return None
    if _firebase_app is None:
        initialize_firebase()
    return auth
