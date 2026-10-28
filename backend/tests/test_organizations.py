from fastapi import status
from app.services.firestore_service import firestore_service
from app.schemas.user import UserRole, AccountStatus


def test_organization_registration_and_verification_flow(
    client, police_user_token, admin_user_token, setup_admin_user
):
    # Setup applicant user
    applicant_data = {
        "uid": "police_789",
        "full_name": "Sergeant Mike Adams",
        "email": "m.adams@metro-police.gov",
        "role": UserRole.NORMAL_USER.value,
        "account_status": AccountStatus.ACTIVE.value,
        "email_verified": True,
    }
    firestore_service.create_user("police_789", applicant_data)

    applicant_headers = {"Authorization": f"Bearer {police_user_token}"}
    admin_headers = {"Authorization": f"Bearer {admin_user_token}"}

    # 1. Applicant submits organization verification
    org_payload = {
        "organization_type": "police",
        "organization_name": "Metro Central Police Precinct 5",
        "official_email": "dispatch@metro-police.gov",
        "official_phone": "+18005550199",
        "address": "100 Police Plaza, City Center",
        "service_area": "Precinct 5 Metro Zone",
    }
    reg_res = client.post("/api/v1/organizations/registration", json=org_payload, headers=applicant_headers)
    assert reg_res.status_code == status.HTTP_202_ACCEPTED
    org = reg_res.json()
    org_id = org["organization_id"]
    assert org["verification_status"] == "pending"

    # User's account_status is now PENDING_VERIFICATION and role is POLICE
    user_doc = firestore_service.get_user("police_789")
    assert user_doc["role"] == "police"
    assert user_doc["account_status"] == "pending_verification"

    # 2. Admin views pending list
    pending_res = client.get("/api/v1/admin/organizations/pending", headers=admin_headers)
    assert pending_res.status_code == status.HTTP_200_OK
    pending_list = pending_res.json()
    assert any(p["organization_id"] == org_id for p in pending_list)

    # 3. Non-admin attempting to verify org -> 403 Forbidden
    hack_res = client.patch(
        f"/api/v1/admin/organizations/{org_id}/verification",
        json={"verification_status": "approved"},
        headers=applicant_headers,
    )
    assert hack_res.status_code == status.HTTP_403_FORBIDDEN

    # 4. Admin approves organization
    approve_res = client.patch(
        f"/api/v1/admin/organizations/{org_id}/verification",
        json={"verification_status": "approved", "admin_notes": "Official badge and precinct confirmed."},
        headers=admin_headers,
    )
    assert approve_res.status_code == status.HTTP_200_OK
    assert approve_res.json()["verification_status"] == "approved"

    # Applicant account is now ACTIVE
    updated_user = firestore_service.get_user("police_789")
    assert updated_user["account_status"] == "active"
