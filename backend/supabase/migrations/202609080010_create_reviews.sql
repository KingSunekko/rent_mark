begin;

create table public.reviews (

  id uuid primary key default gen_random_uuid(),
  rental_request_id uuid not null unique references public.rental_requests(id) on delete restrict,
  item_id uuid not null references public.items(id) on delete restrict,
  renter_id uuid not null references public.profiles(id) on delete restrict,
  owner_id uuid not null references public.profiles(id) on delete restrict,
  renter_name text not null,
  owner_name text not null,
  item_name text not null,
  rating smallint not null check (rating between 1 and 5),
  comment text not null default '' check (char_length(comment) <= 300),
  created_at timestamptz not null default now(),
  check (renter_id <> owner_id)
);

create index reviews_owner_idx on public.reviews(owner_id, created_at desc);
create index reviews_renter_idx on public.reviews(renter_id, created_at desc);
create index reviews_item_idx on public.reviews(item_id, created_at desc);

alter table public.reviews enable row level security;
revoke all on public.reviews from anon, authenticated;
grant select on public.reviews to authenticated;
grant all on public.reviews to service_role;

create policy "authenticated users read reviews" on public.reviews
for select to authenticated using (
  exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and not p.is_suspended
  )
);

create function public.create_rental_review(
  p_renter_id uuid,
  p_rental_request_id uuid,
  p_rating integer,
  p_comment text default ''
) returns setof public.reviews
language plpgsql security definer set search_path = '' as $$
declare
  v_renter public.profiles%rowtype;
  v_owner public.profiles%rowtype;
  v_request public.rental_requests%rowtype;
begin
  select * into v_renter from public.profiles where id = p_renter_id;
  if not found or v_renter.role <> 'renter' or v_renter.is_suspended then
    raise exception using errcode = 'P0001', message = 'renter_required';
  end if;

  select * into v_request from public.rental_requests
    where id = p_rental_request_id for update;
  if not found or v_request.renter_id <> p_renter_id then
    raise exception using errcode = 'P0001', message = 'rental_not_found';
  end if;
  if v_request.status <> 'completed' then
    raise exception using errcode = 'P0001', message = 'rental_not_completed';
  end if;
  if exists (
    select 1 from public.reviews where rental_request_id = p_rental_request_id
  ) then
    raise exception using errcode = 'P0001', message = 'review_exists';
  end if;
  if p_rating < 1 or p_rating > 5 then
    raise exception using errcode = 'P0001', message = 'invalid_rating';
  end if;
  if char_length(btrim(coalesce(p_comment, ''))) > 300 then
    raise exception using errcode = 'P0001', message = 'invalid_comment';
  end if;

  select * into v_owner from public.profiles where id = v_request.owner_id;
  if not found then
    raise exception using errcode = 'P0001', message = 'rental_not_found';
  end if;

  return query insert into public.reviews (
    rental_request_id, item_id, renter_id, owner_id,
    renter_name, owner_name, item_name, rating, comment
  ) values (
    v_request.id, v_request.item_id, v_request.renter_id, v_request.owner_id,
    v_request.renter_name, v_owner.name,
    coalesce(v_request.item_snapshot->>'name', 'Rental item'),
    p_rating, btrim(coalesce(p_comment, ''))
  ) returning *;
end;
$$;

revoke all on function public.create_rental_review(uuid, uuid, integer, text)
  from public, anon, authenticated;
grant execute on function public.create_rental_review(uuid, uuid, integer, text)
  to service_role;

commit;
