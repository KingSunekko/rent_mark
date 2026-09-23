# Davao Map Location and Distance Design

## Purpose

Replace free-text location entry with structured Davao Region area selection,
an approximate Google Maps pickup pin for listings, and optional straight-line
distance for renters. RentMark must not expose an owner's home address or store
a renter's live device location.

## Scope

- Registration and profile editing require a Davao Region city/municipality and
  barangay selection.
- Users may choose `Use my current area` to help select an area after granting
  foreground location permission.
- Owner listing creation and editing includes a Google Map for choosing an
  approximate public pickup area.
- Item cards and details may display `Approximately X km away` when the renter
  grants location permission and the listing has coordinates.
- Existing public meeting-point and pickup-instruction text remains available.
- Driving routes, navigation, background tracking, location history, exact home
  addresses, and PayMongo are outside scope.

## Area catalogue

RentMark will bundle a searchable Davao Region city/municipality and barangay
catalogue derived from an authoritative Philippine geographic-code source. The
data includes canonical labels, stable identifiers, source, retrieval date, and
catalogue version.

Flutter and FastAPI consume generated representations of the same catalogue.
Tests compare their version and record counts to prevent drift. Area selection
works without network access; Google Maps tiles still require connectivity.

## Registration and profile experience

A reusable public-area picker opens as a bottom sheet:

1. Select or search for a city/municipality.
2. Select or search among that area's barangays.
3. Confirm the public label `Barangay, City/Municipality`.

`Use my current area` requests foreground permission only. If granted, the app
uses the current point to suggest a matching area; the user must confirm it.
Only the canonical area label is sent in the existing `community` field. The
device coordinate is discarded and never sent or persisted for profiles.

Permission denial, permanent denial, disabled location services, and lookup
failure leave manual structured selection available. Location permission is
never required to register, edit a profile, browse, or rent.

## Listing map picker

New listings initially inherit the owner's selected public area. The owner may
open an embedded Google Map and move a marker to an approximate public pickup
area. The screen prominently states: `Choose a public landmark, not your home.`

Before submission, Flutter rounds the marker coordinate to three decimal
places. This represents roughly a neighborhood-scale point rather than an exact
doorstep. The owner sees the rounded public preview before saving. A listing
may be saved without a marker and will then display area text only.

The existing `city`, `barangay`, `meeting_point`, and `pickup_instructions`
fields remain. The city and barangay must be a valid catalogue pair. A changed
city clears the previous barangay and marker.

## Distance display

RentMark requests the renter's foreground location only when the user enables
nearby distance or taps a distance action. The current point remains in memory
for the active app session and is never sent to FastAPI or Supabase.

Flutter calculates straight-line distance with the Haversine formula between
the current renter point and the listing's rounded public point. The interface
labels it `Approximately X km away`; it never describes this as driving
distance. Sensible formatting is used for near and far results, and invalid
coordinates produce the area-only fallback.

If permission is denied, services are disabled, the map cannot load, or the
listing lacks coordinates, discovery continues normally with city/barangay
text. Distance is supplemental and never affects authorization or rental
eligibility.

## Backend and database

A new reversible Supabase migration adds nullable listing columns:

- `latitude double precision`
- `longitude double precision`

Database constraints enforce valid geographic ranges and require both values
to be null or both present. Existing rows remain valid with null coordinates.
Rollback consists of removing the constraints and the two columns after any
dependent application version is retired.

FastAPI item create/update schemas accept the optional coordinate pair. The
backend checks pairing, ranges, finite values, and no more than three decimal
places. It validates the city/barangay catalogue pair and rejects malformed,
out-of-region, mismatched, or over-precise input with `422`.

The backend continues deriving owner ID, owner community, visibility, pricing,
discount, and moderation authority from authenticated/server data. It never
accepts or stores renter coordinates. Existing clients and rows remain
compatible because listing coordinates are nullable response fields.

## Google Maps configuration

Android uses the Google Maps SDK for Android. The API key is supplied through
local Android/Gradle configuration and referenced by manifest placeholder; it
is never written into Dart source or committed as a real credential. The key
must be restricted to the Android application ID and signing-certificate
fingerprint, with only required Google Maps APIs enabled.

The implementation adds `google_maps_flutter` and `geolocator`. Reverse
geocoding is optional and must not become required for the structured picker.
Android declares foreground fine/coarse location permissions and provides a
plain-language permission rationale. No background-location permission is
declared.

## State and error handling

- Location/map logic lives in dedicated services rather than screens.
- Public-area selection is represented by one immutable value object.
- The current renter coordinate is session-only and cleared on logout/app exit.
- A failed map or permission request has a visible retry and area-only fallback.
- Failed profile/listing requests retain the user's confirmed selection.
- API failures never create local marketplace substitutes.
- Legacy unmatched community values remain readable but must be replaced with
  a valid structured selection when edited.

## Testing

Flutter unit/widget tests cover catalogue search, dependent barangay selection,
city-change clearing, legacy values, serialization, Haversine calculations,
coordinate rounding, no-coordinate fallback, and registration/profile/listing
form integration.

Location-service tests use an injected adapter to cover granted, denied,
permanently denied, services-disabled, and error states without real GPS.
Widget tests cover unavailable map presentation and small-screen behavior.

Backend tests cover accepted Davao pairs, invalid/mismatched areas, coordinate
pairing, finite/range/precision validation, and listing create/update responses.
Migration review verifies existing rows remain valid and constraints reject
invalid coordinates. All existing backend, Flutter, and analyzer suites must
continue passing.

Manual Android testing covers map rendering with a restricted key, permission
flows, current-area suggestion, marker movement, offline tiles, app restart,
long Davao names, back navigation, and distance comparison against a known
coordinate pair.

