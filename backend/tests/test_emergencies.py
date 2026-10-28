from fastapi import status
from app.services.firestore_service import firestore_service
from app.schemas.user import UserRole, AccountStatus


def test_emergency_incident_workflow(
    client, normal_user_token, setup_normal_user, other_user_token, setup_other_user
):
    owner_headers = {"Authorization": f"Bearer {normal_user_token}"}
    other_headers = {"Authorization": f"Bearer {other_user_token}"}

    # 1. Trigger emergency event
    event_payload = {
        "device_id": "AEGIS-DEV-01",
        "event_type": "sos",
        "latitude": 37.7749,
        "longitude": -122.4194,
        "location_accuracy": 3.2,
        "assigned_organization_ids": ["org_precinct_01"],
    }
    trigger_res = client.post("/api/v1/emergencies", json=event_payload, headers=owner_headers)
    assert trigger_res.status_code == status.HTTP_201_CREATED
    event = trigger_res.json()
    event_id = event["event_id"]
    assert event["event_status"] == "active"
    assert event["latitude"] == 37.7749
    assert event["owner_name"] == "Jane Doe"
    assert event["emergency_profile"]["blood_group"] == "A+"

    # 2. Owner can view the emergency incident
    get_res = client.get(f"/api/v1/emergencies/{event_id}", headers=owner_headers)
    assert get_res.status_code == status.HTTP_200_OK
    assert get_res.json()["event_id"] == event_id

    # 3. Another unrelated user CANNOT view the emergency incident
    forbidden_res = client.get(f"/api/v1/emergencies/{event_id}", headers=other_headers)
    assert forbidden_res.status_code == status.HTTP_403_FORBIDDEN

    # 4. Another user cannot update emergency status
    patch_forbidden = client.patch(
        f"/api/v1/emergencies/{event_id}/status",
        json={"event_status": "resolved"},
        headers=other_headers,
    )
    assert patch_forbidden.status_code == status.HTTP_403_FORBIDDEN


def test_assigned_police_responder_access(client, setup_normal_user):
    # Setup owner emergency
    emergency_data = {
        "event_id": "em_test_police",
        "owner_uid": "user_123",
        "device_id": "AEGIS-DEV-01",
        "event_type": "sos",
        "timestamp": "2026-10-28T10:00:00Z",
        "latitude": 40.7128,
        "longitude": -74.0060,
        "location_accuracy": 4.0,
        "event_status": "active",
        "assigned_organization_ids": ["org_assigned_police"],
    }
    firestore_service.create_emergency("em_test_police", emergency_data)

    # Setup verified assigned police user & org
    police_uid = "police_assigned"
    firestore_service.create_user(police_uid, {
        "uid": police_uid,
        "full_name": "Officer Friendly",
        "email": "friendly@police.gov",
        "role": UserRole.POLICE.value,
        "account_status": AccountStatus.ACTIVE.value,
    })
    firestore_service.create_organization("org_assigned_police", {
        "organization_id": "org_assigned_police",
        "organization_name": "Downtown Police",
        "verification_status": "approved",
        "registered_by_uid": police_uid,
    })

    # Setup unassigned police user & org
    unassigned_uid = "police_unassigned"
    firestore_service.create_user(unassigned_uid, {
        "uid": unassigned_uid,
        "full_name": "Officer Faraway",
        "email": "faraway@police.gov",
        "role": UserRole.POLICE.value,
        "account_status": AccountStatus.ACTIVE.value,
    })
    firestore_service.create_organization("org_other_police", {
        "organization_id": "org_other_police",
        "organization_name": "Faraway Police",
        "verification_status": "approved",
        "registered_by_uid": unassigned_uid,
    })

    assigned_headers = {"Authorization": f"Bearer mock-token:{police_uid}:police"}
    unassigned_headers = {"Authorization": f"Bearer mock-token:{unassigned_uid}:police"}

    # Assigned police can view emergency
    res_assigned = client.get("/api/v1/emergencies/em_test_police", headers=assigned_headers)
    assert res_assigned.status_code == status.HTTP_200_OK

    # Assigned police can update status to responding
    update_res = client.patch(
        "/api/v1/emergencies/em_test_police/status",
        json={"event_status": "responding", "notes": "Patrol unit 12 en route."},
        headers=assigned_headers,
    )
    assert update_res.status_code == status.HTTP_200_OK
    assert update_res.json()["event_status"] == "responding"

    # Unassigned police is rejected
    res_unassigned = client.get("/api/v1/emergencies/em_test_police", headers=unassigned_headers)
    assert res_unassigned.status_code == status.HTTP_403_FORBIDDEN
