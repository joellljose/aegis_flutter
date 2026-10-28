from fastapi import status
from app.services.firestore_service import firestore_service
from app.schemas.user import AccountStatus


def test_update_profile(client, normal_user_token, setup_normal_user):
    headers = {"Authorization": f"Bearer {normal_user_token}"}
    patch_payload = {
        "full_name": "Jane Updated Doe",
        "emergency_profile": {"blood_group": "AB+", "allergies": "Pollen"},
    }
    response = client.patch("/api/v1/profile/me", json=patch_payload, headers=headers)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["full_name"] == "Jane Updated Doe"
    assert data["emergency_profile"]["blood_group"] == "AB+"


def test_suspended_user_forbidden(client, normal_user_token, setup_normal_user):
    # Suspend user
    firestore_service.update_user("user_123", {"account_status": AccountStatus.SUSPENDED.value})

    headers = {"Authorization": f"Bearer {normal_user_token}"}
    response = client.get("/api/v1/profile/me", headers=headers)
    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert "suspended" in response.json()["detail"].lower()
