# Profile Persistence and Avatar Upload Design

## Purpose

Persist account profile fields and profile pictures through the existing
Flutter → FastAPI → Supabase architecture. Registration and Edit Profile both
support an optional picture. Flutter never receives privileged Supabase
credentials and cannot choose another user's storage path.

## Scope

- Persist name, community, phone, and bio in `public.profiles`.
- Upload, replace, and remove the authenticated user's profile picture.
- Support an optional picture selected before registration.
- Restore the saved avatar from `avatar_url` after future authentication.
- Preserve existing role, suspension, authentication, and profile ownership
  behavior.
- Do not add image cropping, multiple profile photos, identity verification, or
  social-media image imports.

## Storage design

A new idempotent Supabase migration creates a public `profile-images` bucket
with a 2 MiB object limit and JPEG, PNG, and WebP MIME types. Public read access
allows profile avatars to render from stable URLs. Upload, update, and delete
are not granted to anonymous or authenticated database roles; FastAPI performs
those operations with the server-only service role.

Each object uses the authenticated profile ID as its namespace:

```text
USER_ID/avatar.EXTENSION
```

The backend derives `USER_ID` and the extension. Neither is trusted from the
client. A user can affect only their own avatar. Reusing the stable path avoids
unbounded orphan accumulation; uploads use upsert semantics.

## API design

The existing `PATCH /api/v1/auth/me` remains responsible for textual fields.
`avatar_url` is removed from client-editable profile input so arbitrary URLs
cannot be stored through the generic profile endpoint.

Two authenticated endpoints are added:

- `PUT /api/v1/auth/me/avatar` accepts one multipart image and returns the
  updated authoritative `UserProfile`.
- `DELETE /api/v1/auth/me/avatar` clears the database value, removes the owned
  object, and returns the updated authoritative `UserProfile`.

The upload endpoint validates declared type, file signature, non-empty content,
and the 2 MiB limit before Storage is modified. Unsupported or spoofed content
returns `422`; oversized content returns `413`; authentication and suspension
continue through the shared dependency.

For replacement, the backend validates bytes, uploads the new object, obtains
its public URL, and then updates `profiles.avatar_url`. If the database update
fails, it reports `502`; the stable path remains safe to retry. For removal,
the backend clears `avatar_url` before best-effort object deletion so clients
do not continue displaying a removed image. Storage failures are logged without
exposing provider details.

## Registration flow

Flutter keeps selected image bytes only as a pre-registration preview. It then:

1. Registers the account through the existing endpoint.
2. Stores the returned access and refresh tokens and authoritative profile.
3. If a picture was selected, calls the authenticated avatar upload endpoint.
4. Replaces local profile state with the upload response.
5. Continues to the role destination.

If registration succeeds but upload fails, the account remains created and
authenticated. Flutter clearly reports that the account was created but the
photo could not be uploaded, and offers continuation plus retry from the
profile screen. It must not retry account creation or silently substitute a
local-only avatar.

## Edit Profile flow

Edit Profile owns draft text and optional draft image bytes. Selecting a photo
changes only the preview. Saving disables repeated submission and performs:

1. `PATCH /auth/me` for validated textual fields.
2. Avatar upload or removal only when the avatar draft changed.
3. Replacement of `AuthState.currentUser` with each authoritative response.
4. Navigation back only after all requested operations finish.

If text saving fails, no avatar operation begins. If text succeeds and avatar
upload fails, the saved text remains authoritative, the screen stays open, and
the user can retry only the avatar operation without resubmitting registration.
Errors distinguish validation, oversized/unsupported images, timeout, and
unreachable server conditions.

## Flutter model and display

The authenticated user model gains `avatarUrl` while retaining temporary image
bytes for immediate previews. Display priority is:

1. newly selected local preview bytes;
2. persisted network `avatarUrl`;
3. name initial placeholder.

Registration, profile, renter header, owner header, and admin user cards reuse
one avatar presentation widget so broken URLs consistently fall back to the
initial. Logout clears preview bytes with the rest of session state.

## Compatibility and migration

The existing nullable `profiles.avatar_url` column requires no change. The new
migration only creates/configures the bucket and its public-read policy. It is
safe for existing profiles and clients because null remains valid.

Rollback requires first deploying a client that no longer uploads avatars,
then removing the Storage policy and bucket. Bucket deletion is destructive
and must never be performed automatically while objects remain.

## Security

- Service-role credentials remain backend-only.
- All writes require a valid, non-suspended authenticated profile.
- Object paths always come from the authenticated profile ID.
- File signatures are checked before upload.
- Profile text input remains length validated.
- Role, ID, suspension, creation time, and avatar URL are not client-controlled.
- Public avatar URLs contain no phone number, email address, or private path.

## Testing

Backend tests cover authentication, suspension, supported signatures, spoofed
types, empty/oversized files, owner-derived paths, profile URL updates,
replacement, removal, retry-safe errors, and generic `avatar_url` rejection.

Flutter tests cover registration with and without a photo, successful avatar
upload, partial registration success, edit preview, text persistence, avatar
replacement/removal, duplicate-tap prevention, network-image restoration, and
broken-image fallback.

All backend tests, Flutter tests, and `flutter analyze` must pass. Manual phone
testing verifies gallery permissions, JPEG/PNG/WebP selection, restart/login
restoration, slow/offline upload handling, and viewing avatars from another
account.

