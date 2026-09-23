begin;

alter table public.rental_requests
  add column if not exists return_requested_at timestamptz,
  add column if not exists completed_at timestamptz;

create or replace function public.transition_rental_request(
  p_actor_id uuid,
  p_request_id uuid,
  p_status text,
  p_rejection_reason text default  need this money. Just shut up right now. I'm trying to pass. I'm trying to pass. Man, strap him in his safety belt, man.
) returns setof public.rental_requests
language plpgsql security definer set search_path = '' as $$
declare
  v_actor public.profiles%rowtype;
  v_request public.rental_requests%rowtype;
begin
  select * into v_actor from public.profiles where id = p_actor_id;
  if not found or v_actor.is_suspended
    or v_actor.role not in ('renter', 'owner') then
    raise exception using errcode = 'P0001', message = 'participant_required';
  end if;

  select * into v_request from public.rental_requests
    where id = p_request_id for update;
  if not found then
    raise exception using errcode = 'P0001', message = 'request_not_found';
  end if;

  if p_status in ('approved', 'rejected', 'active', 'completed') then
    if v_actor.role <> 'owner' then
      raise exception using errcode = 'P0001', message = 'owner_required';
    end if;
    if v_request.owner_id <> p_actor_id then
      raise exception using errcode = 'P0001', message = 'request_not_found';
    end if;
  elsif p_status = 'return_requested' then
    if v_actor.role <> 'renter' then
      raise exception using errcode = 'P0001', message = 'renter_required';
    end if;
    if v_request.renter_id <> p_actor_id then
      raise exception using errcode = 'P0001', message = 'request_not_found';
    end if;
  else
    raise exception using errcode = 'P0001', message = 'unsupported_status';
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
  elsif p_status = 'return_requested' then
    if v_request.status <> 'active' then
      raise exception using errcode = 'P0001', message = 'invalid_transition';
    end if;
    return query update public.rental_requests
      set status = 'return_requested', return_requested_at = now()
      where id = p_request_id returning *;
  elsif p_status = 'completed' then
    if v_request.status <> 'return_requested' then
      raise exception using errcode = 'P0001', message = 'invalid_transition';
    end if;
    return query update public.rental_requests
      set status = 'completed', completed_at = now()
      where id = p_request_id returning *;
  end if;
end;
$$;

revoke all on function public.transition_rental_request(uuid, uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.transition_rental_request(uuid, uuid, text, text)
  to service_role;

commit;