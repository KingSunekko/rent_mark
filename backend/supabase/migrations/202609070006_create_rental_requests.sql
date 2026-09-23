begin;

create table public.rental_requests (
  id uuid primary key default gen_random_uuid(),
  client_request_id uuid not null,
  item_id uuid not null references public.items(id) on delete restrict,
  renter_id uuid not null references public.profiles(id) on delete restrict,
  owner_id uuid not null references public.profiles(id) on delete restrict,
  renter_name text not null,
  item_snapshot jsonb not null,
  start_date date not null,
  end_date date not null check (end_date >= start_date),
  duration_days integer not null check (duration_days = end_date - start_date + 1),
  daily_price_centavos bigint not null check (daily_price_centavos > 0),
  total_centavos bigint not null check (total_centavos = daily_price_centavos * duration_days),
  message text not null default '' check (char_length(message) <= 2000),
  pickup_method text not null check (pickup_method in ('Community meetup', 'Pickup from owner', 'Local delivery')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'active', 'return_requested', 'completed')),
  requested_at timestamptz not null default now(),
  unique (renter_id, client_request_id),
  check (renter_id <> owner_id)
);
create index rental_requests_renter_idx on public.rental_requests(renter_id, requested_at desc);
create index rental_requests_owner_idx on public.rental_requests(owner_id, requested_at desc);
create index rental_requests_booking_idx on public.rental_requests(item_id, status, start_date, end_date);
alter table public.rental_requests enable row level security;
revoke all on public.rental_requests from anon, authenticated;
grant select on public.rental_requests to authenticated;
grant all on public.rental_requests to service_role;
create policy "participants read rental requests" on public.rental_requests
for select to authenticated using (
  (renter_id = (select auth.uid()) or owner_id = (select auth.uid()))
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and not p.is_suspended)
);

-- Server-only transactional creation: serialize retries per renter, then lock
-- the listing while reading its current price, owner, visibility and availability.
create function public.create_rental_request(
  p_renter_id uuid, p_client_request_id uuid, p_item_id uuid,
  p_start_date date, p_end_date date, p_message text, p_pickup_method text
) returns setof public.rental_requests
language plpgsql security definer set search_path = '' as $$
declare
  v_renter public.profiles%rowtype;
  v_owner public.profiles%rowtype;
  v_item public.items%rowtype;
  v_existing public.rental_requests%rowtype;
  v_days integer;
  v_daily bigint;
begin
  select * into v_renter from public.profiles where id = p_renter_id for update;
  if not found or v_renter.role <> 'renter' or v_renter.is_suspended then
    raise exception using errcode = 'P0001', message = 'renter_required';
  end if;
  select * into v_existing from public.rental_requests
    where renter_id = p_renter_id and client_request_id = p_client_request_id;
  if found then
    if v_existing.item_id <> p_item_id or v_existing.start_date <> p_start_date
      or v_existing.end_date <> p_end_date or v_existing.message <> btrim(p_message)
      or v_existing.pickup_method <> p_pickup_method then
      raise exception using errcode = 'P0001', message = 'retry_conflict';
    end if;
    return next v_existing;
    return;
  end if;
  if p_start_date < (now() at time zone 'Asia/Manila')::date
    or p_end_date < p_start_date or p_end_date - p_start_date + 1 > 365 then
    raise exception using errcode = 'P0001', message = 'invalid_dates';
  end if;
  select * into v_item from public.items where id = p_item_id for update;
  if not found or v_item.moderation_status <> 'active' then
    raise exception using errcode = 'P0001', message = 'item_not_found';
  end if;
  if v_item.owner_id = p_renter_id then
    raise exception using errcode = 'P0001', message = 'own_item';
  end if;
  select * into v_owner from public.profiles where id = v_item.owner_id;
  if not found or v_owner.is_suspended or v_owner.role <> 'owner'
    or v_item.availability = 'unavailable' then
    raise exception using errcode = 'P0001', message = 'item_unavailable';
  end if;
  if exists (select 1 from public.rental_requests r where r.item_id = p_item_id
    and r.status in ('approved', 'active', 'return_requested')
    and r.start_date <= p_end_date and r.end_date >= p_start_date) then
    raise exception using errcode = 'P0001', message = 'date_conflict';
  end if;
  v_days := p_end_date - p_start_date + 1;
  v_daily := v_item.price_per_day::bigint * (100 - v_item.discount_percent);
  return query insert into public.rental_requests (
    client_request_id, item_id, renter_id, owner_id, renter_name, item_snapshot,
    start_date, end_date, duration_days, daily_price_centavos, total_centavos,
    message, pickup_method
  ) values (
    p_client_request_id, p_item_id, p_renter_id, v_item.owner_id, v_renter.name,
    to_jsonb(v_item) || jsonb_build_object('owner_name', v_owner.name),
    p_start_date, p_end_date, v_days, v_daily, v_daily * v_days,
    btrim(p_message), p_pickup_method
  ) returning *;
end;
$$;
revoke all on function public.create_rental_request(uuid, uuid, uuid, date, date, text, text) from public, anon, authenticated;
grant execute on function public.create_rental_request(uuid, uuid, uuid, date, date, text, text) to service_role;
commit;
