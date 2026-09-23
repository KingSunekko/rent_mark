create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 120),
  description text not null check (char_length(description) between 10 and 2000),
  category text not null check (
    category in ('electronics', 'tools', 'sports', 'school', 'camping', 'events', 'appliances', 'other')
  ),
  condition text not null check (condition in ('Excellent', 'Good', 'Fair')),
  price_per_day integer not null check (price_per_day between 1 and 1000000),
  availability text not null default 'available' check (
    availability in ('available', 'availableToday', 'unavailable')
  ),
  community text not null check (char_length(community) between 2 and 120),
  image_urls text[] not null default '{}',
  moderation_status text not null default 'active' check (
    moderation_status in ('active', 'hidden', 'underReview')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (cardinality(image_urls) <= 5)
);

create index if not exists items_owner_id_idx on public.items(owner_id);
create index if not exists items_discovery_idx
  on public.items(moderation_status, availability, created_at desc);
create index if not exists items_category_idx on public.items(category);

alter table public.items enable row level security;
revoke all on table public.items from anon, authenticated;
grant select on table public.items to authenticated;

drop policy if exists "authenticated users read visible items" on public.items;
create policy "authenticated users read visible items"
on public.items for select to authenticated
using (
  moderation_status = 'active'
  or owner_id = (select auth.uid())
  or exists (
    select 1 from public.profiles
    where profiles.id = (select auth.uid())
      and profiles.role = 'admin'
      and not profiles.is_suspended
  )
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'item-images',
  'item-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "public reads item images" on storage.objects;
create policy "public reads item images"
on storage.objects for select to public
using (bucket_id = 'item-images');

