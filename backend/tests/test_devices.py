from fastapi import status


def test_device_pairing_and_conflict(client, normal_user_token, setup_normal_user, other_user_token, setup_other_user):
    headers = {"Authorization": f"Bearer {normal_user_token}"}
    other_headers = {"Authorization": f"Bearer {other_user_token}"}

    # 1. Register device
    device_payload = {
        "device_id": "AEGIS-BAND-9001",
        "device_name": "Living Room SOS Button",
    }
    res = client.post("/api/v1/devices", json=device_payload, headers=headers)
    assert res.status_code == status.HTTP_201_CREATED
    data = res.json()
    assert data["device_id"] == "AEGIS-BAND-9001"
    assert data["owner_uid"] == "user_123"
    assert data["device_status"] == "paired"

    # 2. Check profile updated
    profile_res = client.get("/api/v1/profile/me", headers=headers)
    assert profile_res.json()["paired_device_id"] == "AEGIS-BAND-9001"

    # 3. Another user attempts to register the same device -> 409 Conflict
    conflict_res = client.post("/api/v1/devices", json=device_payload, headers=other_headers)
    assert conflict_res.status_code == status.HTTP_409_CONFLICT

    # 4. List devices returns only owner devices
    list_res = client.get("/api/v1/devices", headers=headers)
    assert len(list_res.json()) >= 1
    assert any(d["device_id"] == "AEGIS-BAND-9001" for d in list_res.json())

    other_list = client.get("/api/v1/devices", headers=other_headers)
    assert not any(d["device_id"] == "AEGIS-BAND-9001" for d in other_list.json())
