begin;
alter table public.profiles add column if not exists email text;
update public.profiles p set email = u.email from auth.users u
where p.id = u.id and p.email is null;
alter table public.profiles alter column email set not null;
create unique index if not exists profiles_email_lower_idx
  on public.profiles(lower(email));
revoke select on public.profiles from authenticated;
grant select (id, name, community, role, avatar_url, phone, bio,
  is_suspended, created_at, updated_at) on public.profiles to authenticated;
alter table public.profiles
  add column if not exists suspension_reason text not null default '',
  add column if not exists suspended_at timestamptz;
alter table public.items
  add column if not exists moderation_reason text not null default '',
  add column if not exists moderated_at timestamptz;
alter table public.profiles add constraint profiles_suspension_reason_length
  check (char_length(suspension_reason) <= 500);
alter table public.items add constraint items_moderation_reason_length
  check (char_length(moderation_reason) <= 500);
commit;
