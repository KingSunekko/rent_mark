# RentMark Backend

FastAPI service for RentMark, managed with `uv` and backed by Supabase.
Phases 11A–11J provide the API foundation, authentication, profiles,
persistent item/listing management, rental requests, and owner-controlled
approval, rejection, rental-start, return-request, and completion transitions.
See [PHASE_11F.md](PHASE_11F.md) for return-tracking migration and API instructions.
Phase 11G persists completed-rental ratings and reviews; see
[PHASE_11G.md](PHASE_11G.md).
Phase 11H persists user-scoped event notifications; see
[PHASE_11H.md](PHASE_11H.md).
Phase 11I protects persistent administration, moderation, and reporting; see
[PHASE_11I.md](PHASE_11I.md).
Phase 11J removes runtime mock records and completes Flutter integration; see
[PHASE_11J.md](PHASE_11J.md).

## Setup and run

Requirements: Python 3.14 and `uv`.

```powershell
uv sync --dev
Copy-Item .env.example .env
uv run fastapi dev src/backend/main.py
```

Fill the server-side Supabase values in `.env`. Never place the service-role
key in Flutter, source control, screenshots, or client-visible responses.

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-server-only-service-role-key
```

Swagger documentation is at `http://127.0.0.1:8000/docs`.

## Foundation endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/` | Browser-friendly service health |
| GET | `/health` | Compatibility health route |
| GET | `/api/v1/health` | Versioned health/configuration status |

Expected response before credentials are configured:

```json
{
  "status": "ok",
  "service": "RentMark API",
  "version": "0.1.0",
  "environment": "development",
  "database": "not_configured"
}
```

`configured` means both required variables are present; the health endpoint
does not make a network query. Supabase access is deliberately lazy.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `APP_NAME` | `RentMark API` | OpenAPI/service name |
| `APP_VERSION` | `0.1.0` | Reported API version |
| `ENVIRONMENT` | `development` | development/test/staging/production |
| `API_V1_PREFIX` | `/api/v1` | Versioned router prefix |
| `DOCS_ENABLED` | `true` | Enables API documentation |
| `CORS_ALLOWED_ORIGINS` | localhost origins | Comma-separated origins |
| `SUPABASE_URL` | unset | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | unset | Server-only privileged key |

## Test

```powershell
uv run pytest -q
```

Missing-configuration tests are isolated from the developer's local `.env`, so
adding real Supabase credentials does not change their expected result.

## Structure

```text
src/backend/
  main.py                 app factory, middleware, compatibility routes
  api/router.py           top-level versioned router
  api/routes/health.py    health endpoint
  core/config.py          typed environment settings
  core/supabase.py        lazy server-only Supabase client
  schemas/health.py       validated health response
tests/
  test_config.py
  test_health.py
```

No database tables or policies are created in Phase 11A. Flutter mock data
remains active for Phases 1–10 until its scheduled replacement.

## Phase 11B — Authentication and users

Phase 11B adds validated registration, login, token refresh, current-user
lookup, backend bearer-token validation, and an authoritative `profiles` table.
Public registration accepts only `renter` and `owner`; clients cannot create an
admin or supply suspension state.

Apply this migration using the Supabase SQL Editor before testing real auth:

```text
supabase/migrations/202609050001_create_profiles.sql
```

The migration is safe to rerun after a partial SQL Editor execution: it keeps
an existing `user_role` enum, adds any missing enum values, creates the table
only when absent, and skips policies that already exist.

Endpoints:

| Method | Path | Authentication |
| --- | --- | --- |
| POST | `/api/v1/auth/register` | Public |
| POST | `/api/v1/auth/login` | Public |
| POST | `/api/v1/auth/refresh` | Refresh token |
| GET | `/api/v1/auth/me` | Bearer access token |
| PATCH | `/api/v1/auth/me` | Bearer access token |

Example registration body:

```json
{
  "email": "renter@example.com",
  "password": "at-least-eight-characters",
  "name": "Sample Renter",
  "community": "Davao Community",
  "role": "renter"
}
```

Run the Flutter app against FastAPI from an Android emulator with:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Use the computer's LAN IP instead of `10.0.2.2` on a physical Android device.
When `API_BASE_URL` is omitted, the Phase 1–10 local fallback remains active.

## Phase 11C — Items and owner listings

Public pickup location enhancement: apply
`supabase/migrations/202609080007_add_public_item_location.sql` after 006. It adds
optional `city` (120 characters), `barangay` (120), `meeting_point` (200), and
`pickup_instructions` (1000), with empty defaults and database length constraints.
The existing owner-only create/update endpoints accept and trim these fields;
catalog responses and new rental snapshots include them. Existing snapshots
default to empty fields when read. No new route, secret, or dependency is needed.
All four fields are PUBLIC. No private pickup addresses are collected or promised
to be protected by this change. Owner identity/community authorization is unchanged.

Example PATCH body:
`{"city":"Davao City","barangay":"Matina","meeting_point":"Barangay hall","pickup_instructions":"Meet at the main entrance."}`.
Expect 200 for an authorized owner; 422 for overlong fields, 403 for renters,
and 404 for another owner's listing. Apply the migration once through SQL Editor,
then restart the backend using the existing startup command. Live persistence
and map selection need manual verification; no GPS/geocoding service is added.

Phase 11D is documented in [PHASE_11D.md](PHASE_11D.md): persistent pending
requests, server-calculated discounts/totals, participant access, retry handling,
the required migration, verification results, and remaining manual setup.

### Optional daily discounts (2026-09-07)

After migrations `003` and `004`, apply
`supabase/migrations/202609070005_add_item_discounts.sql` through Supabase SQL
Editor. It adds `items.discount_percent` with a default of 0 and a database
constraint of 0–20. Existing listings retain their regular daily price.

The existing POST/PATCH owner item endpoints accept `discount_percent` as a
whole integer from 0 to 20. POST defaults to 0; PATCH omission preserves the
current discount, and PATCH with 0 disables it. Responses include the percentage.
Ownership and suspension checks remain on the backend; renters cannot set it.
No new routes, dependencies, or environment variables are introduced.

Example PATCH body: `{"discount_percent": 20}`. Expect `200` for an authorized
owner, `401` without a token, `403` for a renter, `404` for another owner's item,
and `422` for percentages outside 0–20, fractional values, strings, or booleans.
Create continues to return `201`. Only base price and percentage are stored;
clients cannot submit computed daily prices or booking totals as item fields.

Flutter applies the discount to every day using integer centavos before display.
For example, ₱99/day with 15% off gives ₱84.15/day and ₱252.45 over three days.
Rental requests remain local in this phase. Phase 11D must calculate and snapshot
booking prices on the server using database values rather than trust Flutter.

Run `uv run pytest -q` from `backend/`, and `flutter test` and `flutter analyze`
from `frontend/`. Verified 44 backend tests (two existing dependency warnings)
and 23 Flutter tests. Tests cover discount bounds, owner-only updates, disabling,
legacy defaults, centavo totals, and immutable request pricing. Live Supabase
migration execution and phone persistence tests remain manual.
The running API returned health `200`, exposed discount limits 0–20 in OpenAPI,
and rejected an unauthenticated discount update with `401`.

Start the API with `uv run fastapi dev src/backend/main.py --host 0.0.0.0`.
Run the phone app with `flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8000`.
No additional installation command is needed beyond the existing `uv sync` and
`flutter pub get` setup. After applying the migration, save/reopen a discounted
listing and test its renter date estimate before marking this change verified.

### Initial item setup

Apply these migrations in order using the Supabase SQL Editor:

```text
supabase/migrations/202609050002_restrict_profile_updates.sql
supabase/migrations/202609050003_create_items.sql
supabase/migrations/202609050004_track_item_image_paths.sql
```

The items migration creates the validated `items` table, discovery and owner
indexes, authenticated read policy, and public `item-images` Storage bucket.
All listing mutations and uploads go through FastAPI with the server-side
service role. Flutter never receives Supabase privileged credentials.

| Method | Path | Access |
| --- | --- | --- |
| GET | `/api/v1/items` | Authenticated users; visible listings only |
| GET | `/api/v1/items/{item_id}` | Authenticated; visibility enforced |
| GET | `/api/v1/owner/items` | Owner |
| POST | `/api/v1/owner/items` | Owner |
| PATCH | `/api/v1/owner/items/{item_id}` | Owning owner only |
| DELETE | `/api/v1/owner/items/{item_id}` | Owning owner only |
| POST | `/api/v1/owner/items/images` | Owner; JPEG/PNG/WebP, maximum 5 MB |
| POST | `/api/v1/owner/items/images/cleanup` | Owner; removes only own unreferenced uploads |

Owner identity and community are derived from the bearer token and profile.
Clients cannot submit ownership or moderation fields. Item request bodies
reject unknown fields, invalid categories, prices, conditions, availability,
and galleries containing more than five images.

Flutter loads persistent owner listings, uploads selected photos through the
API, and includes visible backend listings in Home and Search. If API mode is
disabled or a seeded local demo account has no backend token, the Phase 1–10
mock listing store remains available.

The Phase 11C hardening migration records authoritative Storage object paths.
Item create/update requests accept only paths under the authenticated owner's
folder; public URLs are generated by FastAPI. Removing a photo or deleting a
listing also removes its tracked Storage objects on a best-effort basis, after
checking that no remaining listing references each path. Failed reference
checks preserve the files. This also protects shared photos during failed creates.
Discovery is paginated with a default limit of 50 and a maximum of 100 items.
Discovery responses load owner names through the item/profile relationship in
the same Supabase query, avoiding a separate profile request per listing.

### Phase 11C regression fixes

- Flutter ignores late listing loads, save results, availability results, and
  delete results after logout or an owner switch. Older load errors cannot
  overwrite a new session's loading or error state.
- Flutter follows discovery pages until the last page and deduplicates by ID.
  The API orders by creation time and ID for consistent ordering of ties.
- Failed multi-photo uploads and failed listing saves request cleanup of only
  the paths uploaded in that attempt; existing photos are excluded. The draft
  keeps its original file selections so it can be retried.
- Cleanup validates the owner role and path ownership, accepts one to five
  paths, and checks database references before removing Storage objects.

Cleanup request (use a current owner bearer token and paths from that owner's
upload response):

```json
{"image_paths": ["OWNER_UUID/uploaded-photo.jpg"]}
```

Expected responses: `204` when cleanup completes (referenced photos are retained),
`401` without authentication, `403` for a non-owner, `422` for invalid paths or
payload, and `502` if the reference lookup or Storage removal fails.

No new packages, environment variables, or SQL migrations are required for
these four fixes. Migrations `003` and `004` must already be applied. Existing
server-only Supabase credentials and Flutter `API_BASE_URL` configuration apply.

Verification from the repository root:

```powershell
cd backend
uv sync
uv run pytest -q -p no:cacheprovider
uv run fastapi dev src/backend/main.py --host 0.0.0.0
```

In a second terminal:

```powershell
cd frontend
flutter pub get
flutter test
flutter analyze
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8000
```

Verified on 2026-09-05: 35 backend tests passed (two existing dependency
deprecation warnings), 19 Flutter tests passed, and analysis reported 63 existing
informational notices with zero warnings/errors. The analyzer exits nonzero for
those notices. No Python formatter or linter is configured; changed Dart files
were formatted. A temporary local Uvicorn server returned health `200`, registered
the cleanup endpoint, and returned `401` for unauthenticated cleanup/discovery.
Authenticated cleanup tests use mocked Supabase; live Storage and phone flows
still need manual verification.

Manual checks: switch owners while listings load; confirm only the new owner's
listings appear. Edit/remove photos and delete listings; photos still referenced
elsewhere should remain. Force the second photo upload or listing save to fail,
then confirm earlier unreferenced uploads are removed and the draft can retry.
With more than 50 visible listings, confirm older items appear in renter search.

Limitations: cleanup is best-effort if connectivity, authentication, or Storage
fails. A killed app or an upload whose response is lost can leave an unused file;
there is no scheduled orphan sweeper. Reference checks and Storage deletion are
separate operations, not a transaction; concurrent attachment of the same path
during deletion is not guaranteed safe. Offset pagination is not a snapshot of
a catalog that is changing while pages load.
