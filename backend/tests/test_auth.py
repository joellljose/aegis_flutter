from fastapi import status


def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data


def test_root_portal(client):
    response = client.get("/")
    assert response.status_code == status.HTTP_200_OK
    assert "AEGIS ONE" in response.text



def test_missing_auth_header(client):
    response = client.get("/api/v1/profile/me")
    assert response.status_code == status.HTTP_403_FORBIDDEN or response.status_code == status.HTTP_401_UNAUTHORIZED


def test_profile_creation_flow(client, normal_user_token):
    headers = {"Authorization": f"Bearer {normal_user_token}"}
    payload = {
        "full_name": "Alice Wonderland",
        "phone": "+1555019283",
        "emergency_profile": {
            "blood_group": "O-",
            "allergies": "Peanuts",
            "medical_notes": "None",
        },
    }
    response = client.post("/api/v1/profile", json=payload, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["uid"] == "user_123"
    assert data["full_name"] == "Alice Wonderland"
    assert data["role"] == "normal_user"
    assert data["account_status"] == "active"

    # Duplicate profile registration should return 409 Conflict
    dup_response = client.post("/api/v1/profile", json=payload, headers=headers)
    assert dup_response.status_code == status.HTTP_409_CONFLICT


def test_get_profile_me(client, normal_user_token, setup_normal_user):
    headers = {"Authorization": f"Bearer {normal_user_token}"}
    response = client.get("/api/v1/profile/me", headers=headers)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["uid"] == "user_123"
    assert data["full_name"] == "Jane Doe"
    assert data["emergency_profile"]["blood_group"] == "A+"
