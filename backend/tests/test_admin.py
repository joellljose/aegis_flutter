from fastapi import status
from app.services.firestore_service import firestore_service
from app.schemas.user import UserRole


def test_admin_bootstrap_and_audit_logging(
    client, normal_user_token, setup_normal_user, admin_user_token, setup_admin_user
):
    user_headers = {"Authorization": f"Bearer {normal_user_token}"}
    admin_headers = {"Authorization": f"Bearer {admin_user_token}"}

    # 1. Invalid bootstrap secret
    bad_res = client.post(
        "/api/v1/admin/bootstrap",
        json={"bootstrap_secret": "wrong-secret"},
        headers=user_headers,
    )
    assert bad_res.status_code == status.HTTP_403_FORBIDDEN

    # 2. Valid bootstrap secret
    from app.core.config import settings
    good_res = client.post(
        "/api/v1/admin/bootstrap",
        json={"bootstrap_secret": settings.ADMIN_BOOTSTRAP_SECRET},
        headers=user_headers,
    )
    assert good_res.status_code == status.HTTP_200_OK
    assert good_res.json()["user"]["role"] == UserRole.ADMIN.value

    # 3. Retrieve audit logs as admin
    audit_res = client.get("/api/v1/admin/audit-logs", headers=admin_headers)
    assert audit_res.status_code == status.HTTP_200_OK
    logs = audit_res.json()
    assert len(logs) >= 2
    # Check that both the failed attempt and the successful bootstrap were recorded
    actions = [l["action"] for l in logs]
    assert "admin_bootstrap_attempt" in actions
    assert "admin_bootstrap_success" in actions
