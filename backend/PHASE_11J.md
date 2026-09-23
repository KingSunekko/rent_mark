# Phase 11J — Final integration and mock-data removal

Phase 11J makes the existing Phase 11A–11I FastAPI APIs authoritative in the
Flutter application. It does not add a database migration or a new endpoint.

## Runtime changes

- Login and registration always call FastAPI; seeded passwords and account
  shortcuts are no longer accepted.
- Renter Home, Search, featured/popular sections, and related items use the
  authenticated Supabase catalog.
- Owner listings and rental requests begin empty and load only records returned
  for the authenticated account.
- Admin screens use only the protected Phase 11I dashboard response.
- Profile name, community, phone, and bio edits persist through
  `PATCH /api/v1/auth/me` and retain the server response.
- Missing `API_BASE_URL` produces a configuration error instead of silently
  entering a local demo session.
- Local mock catalog and request source files were removed. Unit tests now use
  dedicated fixtures under `frontend/test/`.

Saved items, recently viewed history, and selected profile-image bytes remain
device-session UI preferences. They are not substituted marketplace records.

## Run

No new package or migration is required. Apply migrations 001–012, then run:

```powershell
cd C:\dev\rent_mark\backend
uv sync --dev
uv run fastapi dev src/backend/main.py --host 0.0.0.0
```

```powershell
cd C:\dev\rent_mark\frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8000
```

## Verify

```powershell
cd C:\dev\rent_mark\backend
uv run pytest -q

cd C:\dev\rent_mark\frontend
flutter test --no-pub
flutter analyze --no-pub
```
