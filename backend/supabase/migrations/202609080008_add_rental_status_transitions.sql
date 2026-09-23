begin;

alter table public.rental_requests
  add column if not exists rejection_reason text not null default '',
  add column if not exists approved_at timestamptz,
  add column if not exists rejected_at timestamptz,
  add column if not exists started_at timestamptz;

alter table public.rental_requests
  drop constraint if exists rental_requests_rejection_reason_length;
alter table public.rental_requests
  add constraint rental_requests_rejection_reason_length
  check (char_length(rejection_reason) <= 500);

create or replace function public.transition_rental_request(
  p_actor_id uuid,
  p_request_id uuid,
  p_status text,
  p_rejection_reason text default ''
) returns setof public.rental_requests
language plpgsql security definer set search_path = '' as $$
declare
  v_actor public.profiles%rowtype;
  v_request public.rental_requests%rowtype;
begin
  select * into v_actor from public.profiles where id = p_actor_id;
  if not found or v_actor.role <> 'owner' or v_actor.is_suspended then
    raise exception using errcode = 'P0001', message = 'owner_required';
  end if;

  select * into v_request from public.rental_requests
    where id = p_request_id for update;
  if not found then
    raise exception using errcode = 'P0001', message = 'request_not_found';
  end if;
  if v_request.owner_id <> p_actor_id then
    raise exception using errcode = 'P0001', message = 'request_not_found';
  end if;

  if p_status = 'approved' then
    if v_request.status <> 'pending' then
      raise exception using errcode = 'P0001', message = 'invalid_transition';
    end if;
    perform 1 from public.items where id = v_request.item_id for update;
    if exists (
      select 1 from public.rental_requests r
      where r.item_id = v_request.item_id and r.id <> v_request.id
        and r.status in ('approved', 'active', 'return_requested')
        and r.start_date <= v_request.end_date
        and r.end_date >= v_request.start_date
    ) then
      raise exception using errcode = 'P0001', message = 'date_conflict';
    end if;
    return query update public.rental_requests
      set status = 'approved', approved_at = now(), rejection_reason = ''
      where id = p_request_id returning *;
  elsif p_status = 'rejected' then
    if v_request.status <> 'pending' then
      raise exception using errcode = 'P0001', message = 'invalid_transition';
    end if;
    if char_length(btrim(coalesce(p_rejection_reason, ''))) > 500 then
      raise exception using errcode = 'P0001', message = 'invalid_rejection_reason';
    end if;
    return query update public.rental_requests
      set status = 'rejected', rejected_at = now(),
          rejection_reason = btrim(coalesce(p_rejection_reason, ''))
      where id = p_request_id returning *;
  elsif p_status = 'active' then
    if v_request.status <> 'approved' then
      raise exception using errcode = 'P0001', message = 'invalid_transition';
    end if;
    return query update public.rental_requests
      set status = 'active', started_at = now()
      where id = p_request_id returning *;
  else
    raise exception using errcode = 'P0001', message = 'unsupported_status';
  end if;
end;
$$;

revoke all on function public.transition_rental_request(uuid, uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.transition_rental_request(uuid, uuid, text, text)
  to service_role;

commit;
