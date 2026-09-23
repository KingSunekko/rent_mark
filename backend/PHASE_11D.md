# Phase 11D — Rental requests

Persistent Pending requests with renter/owner lists and participant-only details.
Backend approval/rejection, status changes, returns, reviews, notifications, and
administration remain deferred to 11E–11I. Existing demo flows remain until 11J.

## Database and installation

Apply `supabase/migrations/202609070006_create_rental_requests.sql` in Supabase
SQL Editor after migrations 001–005. Run the complete transaction once. It is
not intended to be rerun after success; do not delete existing tables on errors.

It creates `rental_requests`, immutable item/price snapshots, participant and
booking indexes, RLS, and a participants-only SELECT policy. Authenticated users
have no INSERT/UPDATE/DELETE grants. Only service_role may execute the new
`create_rental_request` transaction function.

No new packages: existing FastAPI, Pydantic, Supabase/postgrest, uv, Flutter and
provider are reused. No new environment variables: backend `.env` needs
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`; Flutter uses `API_BASE_URL`.
Never put the service-role key in Flutter or source control.

Backend installation/startup:

```powershell
cd C:\dev\rent_mark\backend
uv sync
uv run fastapi dev src/backend/main.py --host 0.0.0.0
```

In a second terminal:

```powershell
cd C:\dev\rent_mark\frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8000
```

## API and expected responses

| Method | Route | Access and result |
| --- | --- | --- |
| POST | `/api/v1/rental-requests` | Renter; 201 saved request |
| GET | `/api/v1/rental-requests?limit=50&offset=0` | Renter's outgoing or owner's incoming; 200 |
| GET | `/api/v1/rental-requests/{request_id}` | Current participant; 200 or 404 |

Use a registered renter bearer token and real item UUID. Replace dates if past:

```json
{
  "client_request_id": "d6d976ca-a4cc-4f46-9be1-6d87a8da316a",
  "item_id": "REPLACE_WITH_ITEM_UUID",
  "start_date": "2026-09-10",
  "end_date": "2026-09-12",
  "message": "I can collect it in the morning.",
  "pickup_method": "Community meetup"
}
```

Do not send renter/owner identity, prices, discount, total, or status: extra
fields return 422. FastAPI supplies the authenticated renter ID. The transaction
reads owner/base price/discount from the listing and inserts Pending status.
For ₱99/day, 15% off and three inclusive days, the response has
`daily_price_centavos: 8415`, `total_centavos: 25245` (₱252.45),
`duration_days: 3`, `status: "pending"`, and the original `item_snapshot`.

Status codes: 401 missing/invalid token; 403 suspended/wrong role/self-rental;
404 inaccessible request or hidden/missing item; 409 unavailable item, booking
conflict, or reused submission key with changed details; 422 invalid input;
502 unexpected database failure. Raw database errors are not returned.
Admin-wide request access is deferred to 11I.

Dates must start today or later in Philippine time, end on/after the start, and
span at most 365 inclusive days. Messages allow 2000 characters. Pickup methods:
Community meetup, Pickup from owner, Local delivery. Unavailable/hidden listings
and suspended owners are rejected. Approved, Active and Return Requested
bookings block overlapping dates. Pending requests do not reserve inventory.

## Architecture and behavior

The new router is included through the existing API router, keeping `main.py`
as bootstrap. Pydantic validates inputs/outputs; the existing auth dependency
checks identity/suspension. A server-only SQL function atomically checks the
listing and stores the quote. It locks the renter row to serialize retries and
the item row while capturing its current price/owner/availability. A unique
`(renter_id, client_request_id)` prevents duplicate rows. Identical retries return
201 with the same ID; changed details with that key return 409.

Flutter reuses `ItemApiService.requestJson` as its authenticated JSON transport.
`RentalRequestApiService` sends only allowed fields. Existing request state
listens to auth changes, clears remote records, ignores late responses, fetches
all pages, and stores the returned snapshot. Review disables duplicate taps,
keeps its retry key on errors, and shows loading/error feedback. Backend errors
never fall back to a local request. Seeded non-UUID items retain mock behavior;
real UUID items require registered login. Changing to a demo account clears the
old backend token.

The preview uses the loaded listing; server pricing at submission is authoritative
if an owner edits the price meanwhile. Confirmation/details display the saved
total. Subsequent listing edits do not reprice the request. Backend request details
are read-only in 11D; demo approval/returns remain functional. Refresh/Retry loads
new requests; there is no polling/push sync. Notifications remain local.

Listings with request history cannot be deleted (409); mark them unavailable.
Storage cleanup preserves image paths referenced by rental snapshots as well as
other listings. Apply migration 006 before running the updated backend.

## Verification and remaining manual work

```powershell
cd C:\dev\rent_mark\backend
uv run pytest -q -p no:cacheprovider
```

```powershell
cd C:\dev\rent_mark\frontend
flutter test
flutter analyze
```

2026-09-07 results: 65 backend tests passed; one unrelated auth test failed;
two existing dependency warnings. `test_registration_reports_an_existing_email`
expects a specific duplicate-email message, but existing `auth.py` returns
`Account could not be created`. That behavior was left unchanged. New request
tests passed. Flutter: 29 tests passed. Dart files formatted; no Python
formatter/linter is configured. FastAPI/Uvicorn started successfully, health
returned 200, OpenAPI registered the three routes, and unauthenticated list/create
returned 401.

Final Flutter analysis: zero errors/warnings, 63 existing informational notices
(nonzero analyzer exit because of those notices).

RPCs are mocked in API tests. SQL execution, live RLS, transaction/concurrency
behavior and Supabase/phone persistence have NOT been verified here. No local
PostgreSQL or Docker executable is available. Required manual checks:

1. Apply migration 006 and confirm RLS and the participant SELECT policy.
2. Create a discounted listing as a registered owner; submit as a registered
   renter. Check Pending in My Rentals and the correct discounted server total.
3. Restart/relogin and refresh: request/quote remain. Log in as that owner and
   refresh Rental Requests; open its details (online approval stays unavailable).
4. Use another renter/owner token for the detail ID: expect 404. No token gives
   401; suspended users get 403. Direct authenticated table writes must fail.
5. Replay the same POST/key: same ID, one row. Change dates with that key: 409.
   After a timeout retry from the same review screen and confirm no duplicate.
6. Try hidden/unavailable/self-owned items, past/reversed dates, long messages,
   and supplied prices/owners/status; expect the documented errors.
7. In isolated test data, test overlap with approved/active/return_requested
   records; expect 409. This phase provides no mutation endpoint for those states.
8. Edit listing prices/photos: old quotes/photos remain. Delete a referenced
   listing: 409. Use demo accounts to verify the previous local workflows.

Limits: the retry key lasts for the mounted review screen, not across app
termination/reopening. After an ambiguous timeout, refresh My Rentals before
creating a new submission. Pending requests do not guarantee a booking; 11E
must atomically enforce conflicts at approval. Existing auth session/refresh
limitations remain. Storage cleanup is best-effort; paginated lists are not a
fixed database snapshot. No later Phase 11 subphase is implemented.

## Files changed

Created: this report; migration 006; backend `schemas/rental_request.py`,
`api/routes/rental_requests.py`, `tests/test_rental_requests.py`; Flutter
`services/rental_request_api_service.dart`, `widgets/rental_request_sync_status.dart`,
and `test/rental_request_backend_test.dart`.

Modified: backend API router, items route, item tests and README; Flutter
`main.dart`, rental-request model, auth/request states, item API transport,
rental-request form/review/details, renter/owner request lists, owner request
details and README. Existing dependencies and secrets were not changed.
