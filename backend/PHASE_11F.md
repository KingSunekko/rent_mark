# Phase 11F — Return Tracking Backend

Phase 11F completes the persisted return flow:

- renter: `active -> return_requested`
- owner: `return_requested -> completed`

## Database setup

Apply this migration after migration 008:

```text
supabase/migrations/202609080009_add_return_tracking.sql
```

It adds `return_requested_at` and `completed_at` and replaces the existing
server-only transition function with participant-aware authorization. A renter
can request return only for their own active rental. The listing owner can
complete only their own return-requested rental.

## API examples

Renter requests a return:

```json
{"status":"return_requested","rejection_reason":""}
```

Owner confirms receipt:

```json
{"status":"completed","rejection_reason":""}
```

Both use:

```http
PATCH /api/v1/rental-requests/{request_id}/status
Authorization: Bearer <access_token>
```

Expected responses are `200` success, `403` wrong role, `404` missing or
non-owned request, `409` invalid transition, and `422` invalid request body.

## Commands

No package or environment-variable changes are required.

```powershell
cd C:\dev\rent_mark\backend
uv sync
uv run fastapi dev src/backend/main.py --host 0.0.0.0
```

```powershell
cd C:\dev\rent_mark\backend
uv run pytest -q

cd C:\dev\rent_mark\frontend
flutter test
flutter analyze
```

Required server variables remain `SUPABASE_URL` and
`SUPABASE_SERVICE_ROLE_KEY`. The service-role key must never be placed in
Flutter.

## Manual test

Start an approved rental as its owner. Log in as its renter, open My Rentals,
and request return. Log back in as the owner, refresh Rental Requests, and
confirm the return. The renter should then see Completed after refreshing.

Backend reviews and ratings remain deferred to Phase 11G. Notifications are
still local until Phase 11H.
