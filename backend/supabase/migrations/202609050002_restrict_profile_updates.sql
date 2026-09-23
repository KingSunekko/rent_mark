revoke update on table public.profiles from authenticated;

grant update (
  name,
  community,
  avatar_url,
  phone,
  bio,
  updated_at
) on public.profiles to authenticated;