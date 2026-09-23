# Phase 11G — Ratings and Reviews Backend

Phase 11G persists renter reviews for completed rentals. A review is created
only by the rental's renter, only after completion, and only once per rental.

## Database setup

Apply migration 010 after migration 009:

```text
supabase/migrations/202609080010_create_reviews.sql
```

The migration creates `public.reviews`, authenticated read-only RLS, indexes for
owner/renter/item lookups, and the server-only `create_rental_review` function.
The function reads the renter, owner, item, and completion status from trusted
database records. Flutter cannot choose ownership or snapshot names.

## API

Create a review:

```http
POST /api/v1/reviews
Authorization: Bearer <renter_access_token>
Content-Type: application/json

{"rental_request_id":"<uuid>","rating":5,"comment":"Excellent item."}
```

Load reviews, optionally filtered by one user:

```http
GET /api/v1/reviews?limit=50&offset=0
GET /api/v1/reviews?owner_id=<uuid>
GET /api/v1/reviews?renter_id=<uuid>
```

Expected responses include `201` created, `200` list, `401` unauthenticated,
`403` non-renter submission, `404` inaccessible rental, `409` incomplete or
already-reviewed rental, and `422` invalid rating/comment/body.

## Commands

No new package or environment variable is required.

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
`SUPABASE_SERVICE_ROLE_KEY`. Never place the service-role key in Flutter.

## Manual test

Complete a backend rental, log in as its renter, submit a one-to-five-star
review, and restart the app. The completed rental must show Review Submitted;
the owner profile and item details must show the persisted review/rating.

Backend notifications remain deferred to Phase 11H. Admin review reporting
remains deferred to Phase 11I.
