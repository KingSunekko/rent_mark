# Phase 11E — Approval and Rental Status Backend

Phase 11E persists owner decisions and rental starts in Supabase. It implements
only these transitions:

- `pending -> approved`
- `pending -> rejected`
- `approved -> active`

Return requests and completion remain deferred to Phase 11F.

## Database setup

Apply this migration in order after migrations 001–007:

```text
supabase/migrations/202609080008_add_rental_status_transitions.sql
```

The migration adds `rejection_reason`, `approved_at`, `rejected_at`, and
`started_at`, plus the server-only `transition_rental_request` function. The
function verifies a non-suspended owner, hides requests belonging to another
owner behind a 404 response, locks the request, enforces valid transitions, and
rechecks date conflicts while approving.

## API

```http
PATCH /api/v1/rental-requests/{request_id}/status
Authorization: Bearer <owner_access_token>
Content-Type: application/json

{"status":"approved","rejection_reason":""}
```

Allowed Phase 11E statuses are `approved`, `rejected`, and `active`. A rejection
reason is optional and limited to 500 characters. Prices, owners, renter IDs,
totals, and timestamps cannot be supplied through this endpoint.

Expected results include `200` for a successful transition, `403` for a
non-owner, `404` for a missing or other owner's request, `409` for an invalid
transition or booking conflict, and `422` for an invalid body.

## Commands

No new package is required. Install the locked environment and start the API:

```powershell
cd C:\dev\rent_mark\backend
uv sync
uv run fastapi dev src/backend/main.py --host 0.0.0.0
```

Required server variables remain:

```text
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
```

Run verification:

```powershell
cd C:\dev\rent_mark\backend
uv run pytest -q

cd C:\dev\rent_mark\frontend
flutter test
flutter analyze
```

Manual test: create a request as a renter, log in as the listing owner, open
Rental Requests, approve it, then start it. Log back in as the renter and refresh
My Rentals to confirm the persisted status and timestamps.

## Limitations

- Migration 008 must be applied manually before the endpoint can work live.
- Notifications are still local; backend notifications belong to Phase 11H.
- Return and completion actions remain local for demo records and are deferred
  for backend records until Phase 11F.
