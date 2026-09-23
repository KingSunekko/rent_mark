# Phase 11I — Administration and reporting backend

Phase 11I moves the administrator dashboard, user suspension, listing
moderation, and aggregate reporting to protected FastAPI endpoints. Phase 11J
is not included, so the existing offline/demo fallback remains available.

## Database migration

Apply `supabase/migrations/202609090012_add_admin_moderation.sql` once in the
Supabase SQL editor. It backfills server-side profile emails, records suspension
and moderation reasons/timestamps, and prevents authenticated clients from
selecting profile email addresses directly. Keep the service-role key only in
the backend `.env`.

## Endpoints

All routes require `Authorization: Bearer <admin access token>`.

| Method | Route | Result |
| --- | --- | --- |
| `GET` | `/api/v1/admin/dashboard` | Users, listings, rentals, reviews, and calculated metrics |
| `PATCH` | `/api/v1/admin/users/{user_id}` | Suspend or restore a non-admin account |
| `PATCH` | `/api/v1/admin/items/{item_id}` | Hide or restore a listing |

Suspending and hiding require a non-empty reason. No token returns `401`, a
non-admin returns `403`, self-suspension returns `409`, invalid input returns
`422`, and a missing record returns `404`.

```json
{"is_suspended": true, "reason": "Repeated policy violations"}
```

```json
{"moderation_status": "hidden", "reason": "Unsafe listing"}
```

## Run and test

```powershell
cd C:\dev\rent_mark\backend
uv sync --dev
uv run pytest -q
uv run fastapi dev src/backend/main.py --host 0.0.0.0
```

```powershell
cd C:\dev\rent_mark\frontend
flutter test
flutter analyze
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8000
```

The environment variables remain `SUPABASE_URL` and the server-only
`SUPABASE_SERVICE_ROLE_KEY`. No package was added. The dashboard currently
loads complete prototype tables rather than paginating, and applying the SQL
migration remains a manual Supabase step.
