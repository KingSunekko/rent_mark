do $$
begin
  create type public.user_role as enum ('renter', 'owner', 'admin');
exception
  when duplicate_object then null;
end
$$;

alter type public.user_role add value if not exists 'renter';
alter type public.user_role add value if not exists 'owner';
alter type public.user_role add value if not exists 'admin';

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 100),
  community text not null check (char_length(community) between 2 and 120),
  role public.user_role not null check (role in ('renter', 'owner', 'admin')),
  avatar_url text,
  phone text not null default '',
  bio text not null default '',
  is_suspended boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
revoke all on table public.profiles from anon;
revoke insert, delete on table public.profiles from authenticated;
grant select, update on table public.profiles to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'profiles'
      and policyname = 'authenticated users read profiles'
  ) then
    create policy "authenticated users read profiles"
    on public.profiles for select to authenticated
    using ((select auth.uid()) is not null);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'profiles'
      and policyname = 'users update their own profile'
  ) then
    create policy "users update their own profile"
    on public.profiles for update to authenticated
    using ((select auth.uid()) = id)
    with check ((select auth.uid()) = id);
  end if;
end
$$;

revoke update (id, role, is_suspended, created_at) on public.profiles from authenticated;
