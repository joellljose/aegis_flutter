import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.services.firestore_service import firestore_service
from app.schemas.user import UserRole, AccountStatus


@pytest.fixture(autouse=True)
def clean_database():
    """Ensure in-memory store is reset before each test."""
    firestore_service.clear_in_memory_data()
    yield
    firestore_service.clear_in_memory_data()


@pytest.fixture
def client():
    """FastAPI TestClient fixture."""
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def normal_user_token():
    return "mock-token:user_123:normal_user"


@pytest.fixture
def other_user_token():
    return "mock-token:user_456:normal_user"


@pytest.fixture
def police_user_token():
    return "mock-token:police_789:police"


@pytest.fixture
def admin_user_token():
    return "mock-token:admin_001:admin"


@pytest.fixture
def setup_normal_user():
    """Creates a seeded normal user in the database."""
    user_data = {
        "uid": "user_123",
        "full_name": "Jane Doe",
        "email": "jane@example.com",
        "phone": "+1234567890",
        "role": UserRole.NORMAL_USER.value,
        "account_status": AccountStatus.ACTIVE.value,
        "email_verified": True,
        "emergency_profile": {"blood_group": "A+", "allergies": "None"},
        "paired_device_id": "AEGIS-DEV-01",
        "notification_preferences": {"sms": True, "push": True, "email": True},
    }
    return firestore_service.create_user("user_123", user_data)


@pytest.fixture
def setup_other_user():
    """Creates another seeded user for permission tests."""
    user_data = {
        "uid": "user_456",
        "full_name": "Bob Smith",
        "email": "bob@example.com",
        "phone": "+1987654321",
        "role": UserRole.NORMAL_USER.value,
        "account_status": AccountStatus.ACTIVE.value,
        "email_verified": True,
    }
    return firestore_service.create_user("user_456", user_data)


@pytest.fixture
def setup_admin_user():
    """Creates a seeded admin user."""
    user_data = {
        "uid": "admin_001",
        "full_name": "AEGIS System Admin",
        "email": "admin@aegis-security.internal",
        "role": UserRole.ADMIN.value,
        "account_status": AccountStatus.ACTIVE.value,
        "email_verified": True,
    }
    return firestore_service.create_user("admin_001", user_data)
