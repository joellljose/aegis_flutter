# AEGIS One — Role-Based Authentication & User-Management System

Secure, modular role-based authentication, authorization, and emergency access control backend for the **AEGIS One** smart personal emergency response device.

---

## 1. Architecture & Tech Stack

- **Framework:** Python 3.12+ with FastAPI (Asynchronous REST API, OpenAPI / Swagger UI at `/docs`)
- **Authentication:** Firebase Authentication (Passwords handled strictly on Firebase; client obtains cryptographic ID tokens)
- **Database:** Google Cloud Firestore (Collections: `users`, `devices`, `trusted_contacts`, `organizations`, `emergency_events`, `audit_logs`)
- **Backend Admin SDK:** `firebase-admin` (Cryptographic verification of ID tokens; privileged database operations)
- **Rate Limiting:** `slowapi` (Protects sensitive and authentication-adjacent endpoints)
- **Data Validation:** Pydantic v2 schemas with comprehensive field validation
- **Testing:** Pytest & FastAPI TestClient

---

## 2. User Roles & RBAC Matrix

| Role | Public Registration? | Requires Admin Verification? | Permissions & Capabilities |
| :--- | :---: | :---: | :--- |
| **Normal User / Device Owner** | Yes (via Firebase Auth) | No | Manage personal profile, emergency profile (blood group, allergies), pair AEGIS devices, add/edit/delete trusted contacts, trigger emergencies, view own emergency history & location data. |
| **Trusted Contact** | Notification-only or User | No (Invited by owner) | View emergency details and location **only** when authorized by the device owner and when invitation status is accepted. |
| **Police / Emergency Authority** | Application submitted | **Yes** | Access **only** emergency cases routed to their verified precinct/organization ID; update emergency status to `responding`, `resolved`. |
| **Hospital / Ambulance Service** | Application submitted | **Yes** | Access **only** medical emergencies routed to their verified organization ID; update assigned case status. |
| **Administrator** | **No** (Secure bootstrap) | Pre-configured secret | Verify and approve police/hospital organizations, manage role assignments, inspect system audit logs. |

---

## 3. Database Schema (Firestore Collections)

### `users`
- `uid` (string, document ID)
- `full_name` (string)
- `email` (string)
- `phone` (string)
- `role` (`normal_user`, `trusted_contact`, `police`, `hospital`, `admin`)
- `account_status` (`active`, `pending_verification`, `suspended`, `inactive`)
- `email_verified` (boolean, synced from token)
- `emergency_profile` (map: `blood_group`, `allergies`, `medical_notes`, `emergency_note`)
- `paired_device_id` (string, optional)
- `notification_preferences` (map: `sms`, `push`, `email`)
- `created_at` (ISO timestamp)
- `updated_at` (ISO timestamp)

### `devices`
- `device_id` (string, document ID)
- `owner_uid` (string)
- `device_name` (string)
- `device_status` (`paired`, `online`, `offline`, `sos`, `unpaired`)
- `created_at` (ISO timestamp)
- `last_seen` (ISO timestamp)

### `trusted_contacts`
- `contact_id` (string, document ID)
- `owner_uid` (string)
- `contact_name` (string)
- `phone` (string, optional)
- `email` (string, optional)
- `relationship` (string)
- `invitation_status` (`pending`, `accepted`, `declined`)
- `notification_preferences` (map: `sms`, `push`, `email`, `call`)
- `created_at` (ISO timestamp)
- `updated_at` (ISO timestamp)

### `organizations`
- `organization_id` (string, document ID)
- `organization_type` (`police`, `hospital`, `ambulance`)
- `organization_name` (string)
- `official_email` (string)
- `official_phone` (string)
- `address` (string)
- `service_area` (string)
- `verification_status` (`pending`, `approved`, `rejected`)
- `registered_by_uid` (string)
- `admin_notes` (string, optional)
- `created_at` (ISO timestamp)
- `verified_at` (ISO timestamp, optional)

### `emergency_events`
- `event_id` (string, document ID)
- `owner_uid` (string)
- `device_id` (string)
- `event_type` (`sos`, `fall_detection`, `medical`, `manual`)
- `timestamp` (ISO timestamp)
- `latitude` (float)
- `longitude` (float)
- `location_accuracy` (float, meters)
- `event_status` (`active`, `acknowledged`, `responding`, `resolved`, `false_alarm`)
- `assigned_organization_ids` (array of organization IDs)
- `owner_name` (string)
- `emergency_profile` (map)
- `created_at` (ISO timestamp)
- `updated_at` (ISO timestamp)

### `audit_logs`
- `log_id` (string, document ID)
- `actor_uid` (string)
- `action` (string, e.g. `admin_bootstrap_attempt`, `organization_verification_approved`)
- `resource_type` (string)
- `resource_id` (string)
- `timestamp` (ISO timestamp)
- `result` (`success`, `denied`, `failed`)
- `details` (map)

---

## 4. API Endpoints

### Health Check
- `GET /health` — Service health and environment status

### User Profile
- `POST /api/v1/profile` — Create profile for authenticated Firebase user (UID derived from token)
- `GET /api/v1/profile/me` — Retrieve authenticated user profile
- `PATCH /api/v1/profile/me` — Update full name, phone, emergency profile, notification preferences

### Trusted Contacts
- `POST /api/v1/contacts` — Add a trusted contact (supports notification-only contacts)
- `GET /api/v1/contacts` — List contacts belonging to current user
- `PATCH /api/v1/contacts/{contact_id}` — Update contact details or invitation status (ownership verified)
- `DELETE /api/v1/contacts/{contact_id}` — Remove contact (ownership verified)

### Devices
- `POST /api/v1/devices` — Pair / register an AEGIS hardware device with current owner
- `GET /api/v1/devices` — List devices owned by current user

### Organizations & Authority Registration
- `POST /api/v1/organizations/registration` — Submit police/hospital verification request

### Administrator
- `POST /api/v1/admin/bootstrap` — Elevate initial administrator via `ADMIN_BOOTSTRAP_SECRET`
- `GET /api/v1/admin/organizations/pending` — List pending authority verification applications
- `PATCH /api/v1/admin/organizations/{organization_id}/verification` — Approve or reject organization application
- `GET /api/v1/admin/audit-logs` — Paginated audit log retrieval

### Emergency Events
- `POST /api/v1/emergencies` — Trigger emergency event from device/app
- `GET /api/v1/emergencies` — List authorized emergencies (filtered by user/organization ownership)
- `GET /api/v1/emergencies/{event_id}` — Retrieve emergency event details with location & medical notes
- `PATCH /api/v1/emergencies/{event_id}/status` — Update emergency status (`responding`, `resolved`)

---

## 5. Security & Authorization Guarantees

1. **Client UID Never Trusted:** The authenticated user ID (`uid`) is always derived from the cryptographically verified Firebase ID token via `auth.verify_id_token(token, check_revoked=True)`.
2. **No Passwords Stored in Firestore:** Firebase Authentication handles credentials and hashing.
3. **Prevention of Role Self-Escalation:** Users cannot modify their role or status via profile endpoints. Admin elevation requires server deployment secret or admin role.
4. **Least-Privilege Organization Access:** Police and Hospital accounts cannot access any emergency cases unless their organization has been administratively verified (`account_status == active`) and the case is explicitly routed to their `organization_id`.
5. **Audit Trail:** All administrative promotions, organization approvals/rejections, and emergency triggers are recorded in the immutable `audit_logs` collection.

---

## 6. How Mobile App (Flutter/React Native) Integrates with Backend

### Step 1: User Signs in via Firebase Auth on Client
```dart
import 'package:firebase_auth/firebase_auth.dart';

// User logs in with email & password or phone auth
final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

### Step 2: Retrieve the ID Token
```dart
// Retrieve the fresh cryptographic ID token
final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
```

### Step 3: Pass Token in the `Authorization` Header
```dart
import 'package:http/http.dart' as http;

final response = await http.get(
  Uri.parse('https://api.aegis-response.org/api/v1/profile/me'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $idToken',
  },
);
```

---

## 7. Local Setup & Running Tests

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure Environment
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Set `FIREBASE_PROJECT_ID` and (optional for local mock testing) `FIREBASE_CREDENTIALS_PATH`.

### 3. Run FastAPI Dev Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
Interactive Swagger UI is accessible at: `http://localhost:8000/docs`.

### 4. Run Pytest Suite
```bash
pytest -v
```
