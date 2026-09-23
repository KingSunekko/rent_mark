# RentMark — Phases 1–10 + Phase 11A–11J

RentMark is a community item-rental prototype built with Flutter. Renters can
discover items and submit rental requests, owners can manage listings and the
full rental lifecycle, and administrators can monitor local prototype data.

Authentication, listings, rentals, reviews, notifications, and administration
use FastAPI and Supabase. Runtime marketplace records are no longer replaced
with local demo data.

## Implemented phases

### Phase 1 — Authentication and role selection

- Splash and welcome screens.
- Animated splash branding and a welcome page that explains the renter and
  owner benefits before authentication.
- Shared login for Renter, Owner, and Admin accounts.
- Public registration for Renter and Owner roles.
- Registration fields for name, email, password, community, and an optional
  profile photo selected from the device gallery.
- Role-based routing after login or registration.
- Mock authentication with no backend or password verification.
- Login includes a collapsible Renter/Owner demo-account panel, clear inline
  validation, and a visible loading state while the local session is resolved.

### Phase 2 — Item discovery

- Renter home screen with nearby, featured, and popular items.
- Search by item name, description, owner, or category.
- Search keeps its controls visible, displays result counts and removable
  active-filter chips, supports list/grid views, and allows deleting recent
  searches.
- Category, availability, and sorting filters.
- Loading skeletons, empty states, and pull-to-refresh behavior.
- Bottom navigation for Home, Search, Rentals, Alerts, and Profile.
- Network product images with an icon-based fallback.
- Personalized discovery now includes an active-rental banner, recommended
  nearby items, recently viewed history, and saved-item sections.

### Phase 3 — Item details

- Reusable details screen opened from Home or Search.
- Swipeable item image gallery.
- Price, availability, rating, condition, category, location, and description.
- Owner preview with a link to the owner profile.
- Local favorite toggle.
- Entry point into the rental-request flow.
- Item galleries include a photo counter and full-screen pinch-to-zoom viewer.
- Details include share/favorite actions, owner response context, rental rules,
  deposit and pickup guidance, unavailable date ranges, similar items, and an
  availability-aware rental button.

### Phase 4 — Rental requests

- Start and end date selection.
- Inclusive rental-duration and estimated-cost calculation.
- Date validation and optional renter message.
- Review screen before submission.
- Confirmation screen after submission.
- Submitted requests appear immediately in **My Rentals**.
- Rental request cards and renter-facing request details.
- Date-conflict checks for approved or active bookings.
- My Rentals uses status-count tabs for Upcoming, Active, Returns, Completed,
  and Cancelled, with countdown context and direct next-action buttons.
- Rental requests show a Dates → Details → Review → Submitted progress
  indicator, pickup/return method, terms agreement, inline validation, and the
  chosen method in the final review.

### Phase 5 — Owner request management

- Owner home screen with pending-request count.
- Incoming rental-request list with status filters.
- Owner-facing request details.
- Approve and reject actions.
- Optional rejection reason.
- Shared request state between the renter and owner flows.
- Owner request status controls display live counts and support sorting by
  newest request, rental date, or highest estimated value.

### Phase 6 — Rental status tracking

- Approved requests can be changed to **Active** by the owner.
- Renter and owner detail screens display the rental progress timeline.
- Request filters include Pending, Approved, Rejected, and Active states where
  applicable.
- Status timestamps are recorded in local state.

### Phase 7 — Owner listings

- Owner **My Listings** screen.
- Add and edit item forms.
- Local image selection for listing photos.
- Multi-photo galleries with up to five images, per-photo removal, a cover
  image, and preservation while editing.
- Name, description, category, condition, daily price, and availability fields.
- Mark listings available or unavailable.
- Delete listings with confirmation.
- Owner-created visible listings are included in renter discovery.
- Android listing uploads detect the photo format from the actual file bytes,
  preventing incorrect filename extensions from causing upload failures.
- Admin moderation visibility is respected by the renter catalog.
- Owner Home includes a detailed dashboard with estimated completed-rental
  earnings, request and listing metrics, attention alerts, recent requests,
  listing-health previews, and management shortcuts.
- Owners use persistent bottom navigation for Dashboard, Requests, Listings,
  Alerts, and Profile; each tab preserves its state while switching sections.

### Phase 8 — Return and completion flow

- Renters can request a return for an active rental.
- Owners can confirm a requested return.
- `Return Requested` and `Completed` request states.
- Return and completion timestamps.
- Rental timeline covers request, approval, active rental, return, and
  completion.

### Phase 9 — Ratings, reviews, and profiles

- Completed rentals can be rated from one to five stars.
- Optional written review.
- Reviews are shown on renter and owner profiles.
- Completed-rental, listing, review, and rating statistics.
- Current-user and public owner profile views.
- Registered users can choose a profile photo during account creation.
- Profile photos use in-memory image data and fall back to the user's initial.
- Editable name, community, phone number, bio, and profile photo.
- Profile-completion progress, rental activity, trust details, and role-aware
  owner/renter statistics.
- Shared saved-item favorites and a dedicated Saved Items screen.
- Quick-access links plus account, notification, privacy, and support settings.

### Phase 10 — Notifications and administration

- Role-specific notifications for requests, status changes, returns, reviews,
  and system events.
- Rentals and Notifications use a compact, high-contrast horizontal filter
  component with stable labels, a selected checkmark, and live counts.
- Unread indicators, mark-as-read, and mark-all-read behavior.
- Tapping a notification marks it read and opens a dedicated details screen.
- Notifications are grouped by date, display relative timestamps, offer type
  filters, support swipe-to-delete with Undo, and deep-link to related rental
  requests when metadata is available.
- Mark All Read includes confirmation and an Undo action.
- Admin dashboard with user, listing, request, and active-rental metrics.
- Responsive Admin workspace: phones use bottom navigation while tablets and
  landscape layouts switch to a navigation rail.
- Platform-health summary with pending, active, completed, and completion-rate
  indicators.
- Search, role filters, result counts, and useful empty states for user
  management; listing management supports search and a hidden-only filter.
- User roles use a full-width segmented control with explicit labels, live
  counts, accessible selection semantics, and a high-contrast active state.
- Suspension and listing-hide actions require confirmation, moderation actions
  require a reason, and successful changes provide visible feedback.
- User suspension and restoration.
- Listing hide and restore moderation.
- Rental and review reports.
- Admin access remains available through manual login but is hidden from the
  public mock-account shortcuts and registration roles.
- Accounts created during the current session are recorded in the shared
  account registry, can log in again after logout, and appear in Admin user
  management with their profile photo.

## Phase 11D — Persistent rental requests

Registered renters can submit requests for backend listings. My Rentals and
owner Rental Requests load each participant's saved requests with Refresh/Retry.
The backend calculates inclusive duration and discounted prices from the stored
item, preserving the accepted quote as a snapshot. Review-screen retry keys
prevent duplicate submissions; API failures do not create a mock substitute.
Account changes clear backend requests and discard late responses.
The shared request provider follows authentication changes automatically, and
the item-details location card uses the current item-based location component.
Backend request screens show loading, refresh, retry, and sync-error states;
late responses are ignored after the active account changes.
Backend request screens show loading, refresh, retry, and readable sync-error
states without allowing late responses from an earlier session to appear.

Apply `backend/supabase/migrations/202609070006_create_rental_requests.sql` after
migrations 001–005, then restart FastAPI and Flutter. No additional packages or
environment variables are required. Backend requests stay Pending/read-only until
11E; demo requests retain their local approval/return workflow. Listings with
rental history must be marked unavailable instead of deleted.

See [Phase 11D setup, API, tests, changed files and limitations](../backend/PHASE_11D.md).
Live migration/RLS and phone persistence verification remain manual. Results:
29 Flutter tests passed; 65 backend tests passed with one existing registration
error-message test failure. Online approval/returns/notifications/admin reporting
are deferred to later subphases.

## Phase 11E — Approval and rental status backend

Owners can approve or reject backend requests and start approved rentals from
the existing request-details screen. Supabase remains authoritative: the API
checks ownership and valid transitions, stores rejection reasons and status
timestamps, and rechecks overlapping bookings during approval. Failed updates
leave the displayed request unchanged and show a retryable message. Mock/demo
requests keep their existing local workflow.

Apply `backend/supabase/migrations/202609080008_add_rental_status_transitions.sql`
after migration 007. Backend return and completion transitions are intentionally
deferred to Phase 11F, and notifications remain local until Phase 11H. See
[Phase 11E setup and API details](../backend/PHASE_11E.md).

## Phase 11F — Return tracking backend

Renters can mark their own active backend rental as Return Requested. The
listing owner can then confirm receipt and persist Completed. The existing
details screens show progress while saving, retain the previous state when an
API call fails, and create local notifications only after a successful update.
Supabase records authoritative return-request and completion timestamps.

Apply `backend/supabase/migrations/202609080009_add_return_tracking.sql` after
migration 008. Reviews remain local until Phase 11G and notifications remain
local until Phase 11H. See [Phase 11F details](../backend/PHASE_11F.md).

## Phase 11G — Ratings and reviews backend

Completed backend rentals can be reviewed once by their renter. Ratings and
optional comments persist in Supabase, reload after login, and appear on the
existing renter/owner profile and item-details UI. Profile filtering uses
authoritative user IDs while retaining name-based fallback for demo reviews.
Review submission shows progress and leaves local state unchanged on failure.

Apply `backend/supabase/migrations/202609080010_create_reviews.sql` after
migration 009. Notifications remain local until Phase 11H and admin review
reporting remains local until Phase 11I. See
[Phase 11G setup and API details](../backend/PHASE_11G.md).

## Phase 11H — Notifications backend

Authenticated alerts now load from the backend and preserve unread, read,
dismissed, and restored state. Supabase triggers generate authoritative alerts
for requests, approval/rejection, rental starts, returns, completion, and
reviews. Flutter avoids creating duplicate local alerts for backend events while
retaining the complete demo notification flow.

Apply `backend/supabase/migrations/202609090011_create_notifications.sql` after
migration 010. Remaining mock fallback removal remains Phase 11J. See
[Phase 11H setup and API details](../backend/PHASE_11H.md).

## Phase 11I — Administration and reporting backend

The admin dashboard now loads authoritative backend users, listings, rentals,
reviews, and aggregate metrics for authenticated administrators. User
suspension and listing hide/restore actions persist required reasons and
timestamps. Online admin sessions show loading, failure, and retry states; the
demo fallback remains available until Phase 11J.

Apply `backend/supabase/migrations/202609090012_add_admin_moderation.sql` after
migration 011. See
[Phase 11I setup and API details](../backend/PHASE_11I.md).

## Phase 11J — Final integration

Backend authentication and all marketplace workflows are now authoritative.
Home, Search, related items, owner listings, rental requests, reviews,
notifications, and administration no longer fall back to seeded records.
Profile text fields persist through FastAPI, and missing API configuration is
reported clearly. Saved/recently-viewed items and selected profile photos remain
device-session presentation preferences rather than fabricated marketplace
data.

Run Flutter with `--dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8000`. See
[Phase 11J integration and verification details](../backend/PHASE_11J.md).

## Run the app

### Frontend analyzer cleanup (2026-09-08)

Replaced deprecated color opacity calls and dropdown `value` arguments with
their current Flutter equivalents. Cleaned unused callback parameters/imports,
string interpolation, null-aware entries, braces, and documentation comments.
The post-review snackbar now checks `context.mounted` before using the context
after navigation. No new packages, migrations, or backend changes are required.

Verification: `flutter analyze --no-pub` reports **No issues found**; the previous
63 informational notices are resolved. `flutter test --no-pub` verifies the
existing frontend regression suite. Earlier analyzer counts in this README
describe historical verification runs.

### Public location and pickup details

Owner Add/Edit Item includes optional City/Municipality, Barangay, Public meeting
point, and Public pickup instructions. These fields are catalog-visible: choose
a public landmark and never enter a private home address/contact information.
Private address collection and approval-gated sharing are not implemented.

Item Details shows the area (falling back to community for older listings), the
meeting point and instructions. **Open in Google Maps** opens an external search
using the public landmark and area; Android may use Maps or a browser. It does
not promise an exact pin or route. With no meeting point, the button is hidden.
No Maps API key, billing setup, new Flutter package, or GPS permission is needed.
The current launcher uses a small Android MethodChannel in `MainActivity.kt`;
other platforms show a graceful failure rather than a map.

Apply `backend/supabase/migrations/202609080007_add_public_item_location.sql`
after migration 006, restart FastAPI, then fully rebuild/install Flutter because
native Android code changed. Existing `API_BASE_URL` configuration still applies.
Existing listings default to empty new fields and can be edited to add them.
New request snapshots capture public pickup details; old snapshots are unchanged.

Mock numerical distance labels are replaced with “Area only”; location details
state that distance is not calculated. “Nearest” is now “Recommended” and the
home heading is “Recommended Items”. No GPS-based proximity claim or sorting is
made. Mock coordinates/distances remain internal demo data pending a GPS phase.

Manual check: save/reopen an owner listing with a public landmark, view it as a
renter, and tap Maps. Check the search area is correct. Test an old listing with
no meeting point; it should display its community and no Maps button. Actual
phone intent handling and live Supabase migration execution remain manual.

Validation: 32 Flutter tests passed; backend 70 passed with the existing
registration error-message mismatch (1 failure) and two dependency warnings.

### Android launcher icon

The launcher uses the supplied RentMark logo, with the display name `RentMark`.
The original artwork is stored at `assets/branding/rentmark_logo.png`. Generated
Android resources include five legacy icon densities and an Android 8+ adaptive
icon with a white background and padding for launcher masks. The full artwork,
including its text, is preserved; small text may be hard to read at launcher size.

To regenerate the resources on Windows after replacing the source artwork:

```powershell
powershell -ExecutionPolicy Bypass -File tool/generate_launcher_icons.ps1
```

Rebuild and install with `flutter run` (include your existing `API_BASE_URL`
argument for backend access). Hot reload does not update launcher resources.
No new packages or backend changes are required for the icon.

Verified icon resource dimensions and built an ARM64 debug APK with
`flutter build apk --debug --no-pub --target-platform android-arm64`.
The all-architecture build was blocked by Maven DNS/download failures for
uncached engine artifacts. The verification APK has no backend URL configured;
use your normal `flutter run --dart-define=API_BASE_URL=...` to install for testing.

### Start Flutter

The Flutter splash screen and the welcome screen above “Find what you need.”
use the supplied blue RentMark artwork in
`assets/branding/rentmark_welcome.png`, rendered by `RentMarkBrandArtwork`.
The complete image is bundled for offline use and fitted without cropping;
the welcome header uses a text wordmark. Splash timing, Login, and Create Account
navigation remain the same. This artwork is separate from the Android launcher
icon. After changing bundled assets, fully restart the app.

```bash
flutter pub get
flutter run
```

For structural widget changes, use a full restart if hot reload leaves an old
Provider or `IndexedStack` tree mounted.

## Mock accounts

Any non-empty password works for these local accounts.

| Role | Email | Destination |
| --- | --- | --- |
| Renter | `renter@example.com` | Renter Home |
| Owner | `owner@example.com` | Owner Home |
| Admin | `admin@example.com` | Admin Dashboard |

The login helper only displays Renter and Owner. To access Admin, enter
`admin@example.com` manually. Registration intentionally offers only Renter and
Owner roles.

## Quick end-to-end test

1. Log in as `renter@example.com`.
2. Open an item and submit a rental request with valid dates.
3. Open **Rentals** and verify that the request is Pending.
4. Log out, then log in as `owner@example.com`.
5. Open **Rental Requests**, approve the request, and start the rental.
6. Return to the renter account and request the item's return.
7. Return to the owner account and confirm the return.
8. Log in as the renter and submit a review for the completed rental.
9. Check Alerts and Profile for the resulting notifications and review data.
10. Log in manually as `admin@example.com` to inspect users, listings, and
    reports.

## Project structure

```text
lib/
  main.dart
  data/
    owner_listings_store.dart
  models/
    app_notification.dart
    owner_listing.dart
    rental_item.dart
    rental_request.dart
    rental_review.dart
    user_role.dart
  navigation/
    destination_router.dart
  screens/
    admin_dashboard_screen.dart
    add_edit_item_screen.dart
    edit_profile_screen.dart
    favorites_screen.dart
    home_screen.dart
    item_details_screen.dart
    login_screen.dart
    my_rentals_screen.dart
    notification_details_screen.dart
    notifications_screen.dart
    owner_home_screen.dart
    owner_shell.dart
    owner_listings_screen.dart
    owner_request_details_screen.dart
    owner_requests_screen.dart
    register_screen.dart
    rental_request_details_screen.dart
    rental_request_review_screen.dart
    rental_request_screen.dart
    review_form_screen.dart
    search_screen.dart
    user_profile_screen.dart
  state/
    admin_state.dart
    auth_state.dart
    favorites_state.dart
    notifications_state.dart
    rental_requests_state.dart
    reviews_state.dart
  theme/
    app_theme.dart
  widgets/
    reusable presentation and form widgets
```

## Main dependencies

### Optional owner-controlled daily discounts

- In Add/Edit Item, owners can enable **Offer a daily discount** and choose a
  whole percentage from **0 to 20**. It is off by default; disabling it saves 0%.
- The discount applies to every rental day. The form previews the renter's daily
  rate; item details and rental review show the regular rate and owner discount.
- Cards, price sorting, date estimates, saved request totals, and owner/admin
  totals use the discounted rate. Rates retain centavos: ₱99 at 15% off is
  ₱84.15/day and ₱252.45 for three inclusive days.
- A submitted local request keeps its immutable item price/discount snapshot.
  Editing the listing later does not change that request's quote.
- Apply `backend/supabase/migrations/202609070005_add_item_discounts.sql` in
  Supabase SQL Editor after migration `004`, then restart FastAPI and Flutter.
  Existing rows default to 0%; no package or environment changes are needed.
- Listing discounts persist through the existing owner-authorized item API.
  Phase 11D saves backend request totals from stored item prices and discounts;
  previews and demo requests still use local calculations.
- Verified 44 backend tests and 23 Flutter tests after this change. Manual test:
  save a ₱500/day listing at 20%, reopen it to confirm persistence, then request
  three days as a renter; expect ₱400/day and ₱1,200 total. Disable the discount
  and confirm new requests use ₱500/day while the old request remains ₱1,200.

### Packages

- `provider` for local reactive state.
- `image_picker` for profile and listing photo selection.
- Flutter Material components for the interface.

## UI design system

- Shared semantic colors distinguish pending, approved, active, rejected,
  return-requested, and completed rental states.
- Inputs, filled buttons, outlined buttons, text buttons, navigation bars,
  bottom sheets, snackbars, and chips use centralized component themes.
- Renter, owner, profile, notification, and admin screens share the same
  spacing, typography, radii, surface, and interaction language.
- Owner Home uses a dashboard hierarchy for earnings, attention items,
  request activity, listing health, and management actions.

## Planned UI and backend-dependent improvements

- Persistent authentication, password management, profile preferences, and
  uploaded media require backend account storage.
- Notification deep links require notifications to store related request,
  listing, or review identifiers.
- Push notifications, payments, maps/GPS, messaging, moderation audit logs,
  exports, and real analytics require dedicated backend integrations.
- Future frontend passes can add dark mode, tablet navigation rails, charts,
  full-screen image zoom, listing calendars, and richer search result layouts.

## Current limitations

- Backend mode persists accounts, listings/photos, and pending requests; demo
  data and later workflows (status changes, reviews, alerts, moderation) remain local.
- Apply the documented Supabase migrations and configure `API_BASE_URL` to use
  backend mode. Online approval and later lifecycle steps are not implemented yet.
- No payment or checkout integration.
- No real-time chat, push notifications, maps, or GPS.
- Item stock photos require network access; failed images use the built-in
  fallback tile.

## UI modernization roadmap

The next frontend design pass is tracked in this order:

1. Shared responsive components, accessibility, dark mode, loading/error/
   success states, and motion.
2. Multi-step authentication and registration with clearer validation and an
   account summary.
3. Personalized renter discovery with active-rental, recommended, recently
   viewed, and saved-item sections.
4. Sticky search, active filter chips, result counts, and grid/list layouts.
5. Full-screen item galleries, rental rules, unavailable dates, similar items,
   and availability-aware actions.
6. A stepped rental request flow with pickup/return methods and terms.
7. Status-count rental tabs with contextual next actions and countdowns.
8. Grouped/filterable notifications with relative times and related-record
   navigation.
9. Collapsible profiles, verification steps, rating distributions, privacy,
   and dedicated settings screens.
10. Owner navigation, earnings periods/charts, utilization, request sorting,
    listing analytics, drafts, photo ordering, and availability calendars.
11. Admin search/filtering, detail screens, moderation reasons/history,
    confirmations, reports, responsive navigation rail, and exports.

Backend-dependent roadmap items include persistent authentication, notification
deep links, audit logs, exports, push delivery, payments, maps, and durable
privacy/preferences. These require API and database models before their UI can
be considered complete.

## Phase 11A — FastAPI and Supabase foundation

- The separate FastAPI backend now uses versioned API routers, typed environment
  settings, configurable CORS, and validated health responses.
- Supabase is exposed through a lazy server-only client. The service-role key is
  loaded only from backend environment variables and is never bundled in Flutter.
- `/`, `/health`, and `/api/v1/health` provide setup diagnostics; Swagger UI is
  available at `/docs` during development.
- Backend health and configuration behavior have automated tests.
- Missing-configuration tests are isolated from local `.env` credentials, so
  the backend suite continues to pass after Supabase is configured.
- No Supabase tables, authentication endpoints, or application-data endpoints
  are included in 11A. All Phase 1–10 Flutter workflows retain local/mock state.

### Phase 11B — Authentication and users

- FastAPI provides registration, login, refresh, and authenticated `/me`
  endpoints backed by Supabase Auth and the `profiles` table.
- Authenticated users can update safe profile fields through `PATCH /me`;
  role, suspension state, and identity remain server-controlled.
- Backend bearer-token validation resolves the current Supabase user and loads
  role and suspension state from the database instead of trusting client data.
- Public registration permits only Renter and Owner roles.
- Flutter uses the backend when launched with `API_BASE_URL`; seeded demo
  accounts and the no-flag development flow retain the local mock fallback.
- Android emulator example:
  `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`.
- A physical Android device must use the development computer's LAN address
  while both devices are on the same network, for example
  `flutter run --dart-define=API_BASE_URL=http://10.0.13.133:8000`.
- Android debug builds allow cleartext HTTP for the local FastAPI development
  server; release builds do not enable this exception.
- Authentication requests use bounded connection and response timeouts so a
  stalled local server or Supabase call returns a useful error instead of
  leaving the form loading indefinitely.
- Duplicate registration attempts return a clear existing-account message;
  unexpected Supabase registration failures are logged on the backend without
  exposing credentials or internal details to Flutter.
- Access and refresh tokens are currently held only in memory. Durable secure
  token storage and automatic session restoration remain future work.
- Refresh requests re-check the authoritative profile and reject suspended or
  missing accounts before returning a new session.
- Refresh-token validation accepts Supabase's short opaque token format while
  still rejecting empty or excessively large values.
- The Phase 11B profiles migration is idempotent and can be rerun safely after
  a partial Supabase SQL Editor execution.
- Splash navigation uses a cancellable timer so disposing the app during tests
  or rapid navigation does not leave delayed work running.

### Phase 11C — Items and owner listings

- Backend-authenticated owners load their own persistent Supabase listings.
- Add, edit, availability, and delete actions use owner-authorized FastAPI
  endpoints; ownership and community come from the authenticated profile.
- Up to five local listing photos are uploaded through FastAPI to the Supabase
  `item-images` bucket before the listing is saved.
- Visible backend items are included in renter Home and Search results.
- Listing screens provide loading, retry, network-error, and save-error states.
- Seeded demo accounts and runs without `API_BASE_URL` retain the Phase 1–10
  in-memory listing fallback.
- Apply `backend/supabase/migrations/202609050003_create_items.sql` before
  manually testing persistent listings.
- The Phase 11C verification pass removes stale imports, unused presentation
  data, redundant casts, and an unnecessary nullable assertion reported by
  Flutter analysis.
- Listing state is cleared and re-scoped when an account logs out or a
  different owner loads, preventing stale listings from crossing sessions.
- Remote listings retain server-issued Storage paths so removed photos and
  deleted listings can be cleaned up safely by FastAPI.
- Apply `backend/supabase/migrations/202609050004_track_item_image_paths.sql`
  after migration `003` to enable the hardened image lifecycle.
- Late API responses and errors from previous sessions are discarded after
  logout or owner switching, including listing loads and mutation results.
- Home and Search fetch every discovery page, including listings beyond the
  first 50, and deduplicate by listing ID.
- Photo deletion checks remaining listing references so shared photos stay
  available. Failed uploads/saves clean up new unreferenced uploads through the
  owner-authorized `/api/v1/owner/items/images/cleanup` endpoint; draft photo
  selections remain available for retry.
- These fixes require no additional migrations, packages, or environment
  variables. Restart FastAPI and the Flutter app to use the updated endpoint.
- Verification on 2026-09-05: backend 35 tests passed; Flutter 19 tests passed;
  analyzer zero errors/warnings and 63 existing informational notices. Regression
  tests cover delayed session responses, failed upload/save cleanup, shared
  images, and discovery beyond 50 items. Live Supabase/phone verification remains
  manual; see `backend/README.md` for commands, expected responses, and limits.
- Cleanup remains best-effort during network/Storage failures or app termination.
  Concurrent attachment of a path during deletion is not transactionally guarded;
  pagination reflects a live catalog rather than a fixed snapshot.
