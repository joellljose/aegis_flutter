from fastapi import status


def test_contact_management_lifecycle(client, normal_user_token, setup_normal_user, other_user_token, setup_other_user):
    headers = {"Authorization": f"Bearer {normal_user_token}"}
    other_headers = {"Authorization": f"Bearer {other_user_token}"}

    # 1. Add Contact
    contact_data = {
        "contact_name": "Emergency Brother",
        "phone": "+1999888777",
        "email": "brother@family.org",
        "relationship": "Brother",
        "notification_preferences": {"sms": True, "push": True, "email": False, "call": True},
    }
    create_res = client.post("/api/v1/contacts", json=contact_data, headers=headers)
    assert create_res.status_code == status.HTTP_201_CREATED
    contact = create_res.json()
    contact_id = contact["contact_id"]
    assert contact["owner_uid"] == "user_123"
    assert contact["contact_name"] == "Emergency Brother"
    assert contact["invitation_status"] == "pending"

    # 2. List Contacts (Owner)
    list_res = client.get("/api/v1/contacts", headers=headers)
    assert list_res.status_code == status.HTTP_200_OK
    assert len(list_res.json()) == 1

    # 3. Another user should NOT see or update this contact
    other_list_res = client.get("/api/v1/contacts", headers=other_headers)
    assert len(other_list_res.json()) == 0

    other_patch_res = client.patch(
        f"/api/v1/contacts/{contact_id}",
        json={"contact_name": "Hacked Name"},
        headers=other_headers,
    )
    assert other_patch_res.status_code == status.HTTP_403_FORBIDDEN

    # 4. Owner updates contact
    update_res = client.patch(
        f"/api/v1/contacts/{contact_id}",
        json={"relationship": "Elder Brother", "invitation_status": "accepted"},
        headers=headers,
    )
    assert update_res.status_code == status.HTTP_200_OK
    assert update_res.json()["relationship"] == "Elder Brother"
    assert update_res.json()["invitation_status"] == "accepted"

    # 5. Owner deletes contact
    del_res = client.delete(f"/api/v1/contacts/{contact_id}", headers=headers)
    assert del_res.status_code == status.HTTP_204_NO_CONTENT

    # Verification: contact is gone
    list_res_after = client.get("/api/v1/contacts", headers=headers)
    assert len(list_res_after.json()) == 0
