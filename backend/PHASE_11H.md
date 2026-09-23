# Phase 11H — Notifications Backend

Phase 11H persists notifications for rental requests, status changes, returns,
completion, and reviews. Database triggers create recipient-controlled events in
the same transaction as the source change.

## Database setup

Apply migration 011 after migration 010:

```text
supabase/migrations/202609090011_create_notifications.sql
```

The migration creates `public.notifications`, user-scoped RLS, event indexes,
deduplication keys, and triggers for rental-request and review events.

## API

```http
GET /api/v1/notifications?limit=50&offset=0
PATCH /api/v1/notifications/{notification_id}
PATCH /api/v1/notifications
```

Single update body:

```json
{"is_read":true}
```

Dismiss or restore with `is_deleted`. Bulk read/unread accepts up to 100 IDs:

```json
{"notification_ids":["<uuid>"],"is_read":true}
```

All operations are scoped to the authenticated user. Another user's record is
not returned or modified.

## Commands

No new packages or environment variables are required.

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
`SUPABASE_SERVICE_ROLE_KEY`. The service-role key stays server-side.

## Manual test

Create a rental request, switch to its owner, and refresh Alerts. Repeat after
approval, rental start, return request, completion, and review. Verify unread
counts, mark-read, mark-all-read, undo, dismiss, restore, and persistence after
restart.

Admin notification management remains deferred to Phase 11I. Remaining mock
notification fallbacks are removed only in Phase 11J.
