begin;

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('request', 'status', 'return_update', 'review', 'system')),
  title text not null check (char_length(title) between 1 and 120),
  message text not null check (char_length(message) between 1 and 500),
  related_request_id uuid references public.rental_requests(id) on delete cascade,
  related_review_id uuid references public.reviews(id) on delete cascade,
  dedupe_key text not null unique,
  is_read boolean not null default false,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now()
);

create index notifications_user_idx
  on public.notifications(user_id, is_deleted, created_at desc);
alter table public.notifications enable row level security;
revoke all on public.notifications from anon, authenticated;
grant select, update on public.notifications to authenticated;
grant all on public.notifications to service_role;
create policy "users read their notifications" on public.notifications
  for select to authenticated using (user_id = (select auth.uid()));
create policy "users update their notifications" on public.notifications
  for update to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke update (id, user_id, kind, title, message, related_request_id,
  related_review_id, dedupe_key, created_at) on public.notifications from authenticated;

create function public.notify_rental_request_event()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_user_id uuid;
  v_kind text;
  v_title text;
  v_message text;
  v_event text;
begin
  if tg_op = 'INSERT' then
    v_user_id := new.owner_id;
    v_kind := 'request';
    v_title := 'New rental request';
    v_message := new.renter_name || ' requested ' || coalesce(new.item_snapshot->>'name', 'an item') || '.';
    v_event := 'created';
  elsif old.status is distinct from new.status then
    v_event := new.status;
    if new.status = 'return_requested' then
      v_user_id := new.owner_id;
      v_kind := 'return_update';
      v_title := 'Return requested';
      v_message := new.renter_name || ' is ready to return ' || coalesce(new.item_snapshot->>'name', 'the item') || '.';
    else
      v_user_id := new.renter_id;
      v_kind := case when new.status = 'completed' then 'return_update' else 'status' end;
      v_title := case new.status
        when 'approved' then 'Request approved'
        when 'rejected' then 'Request rejected'
        when 'active' then 'Rental started'
        when 'completed' then 'Return confirmed'
        else 'Rental updated' end;
      v_message := coalesce(new.item_snapshot->>'name', 'Your rental') || case new.status
        when 'approved' then ' was approved.'
        when 'rejected' then ' was not approved.'
        when 'active' then ' is now active.'
        when 'completed' then ' was returned successfully.'
        else ' was updated.' end;
    end if;
  else
    return new;
  end if;
  insert into public.notifications (
    user_id, kind, title, message, related_request_id, dedupe_key
  ) values (
    v_user_id, v_kind, v_title, v_message, new.id,
    'rental:' || new.id::text || ':' || v_event
  ) on conflict (dedupe_key) do nothing;
  return new;
end;
$$;

create trigger rental_request_notifications
after insert or update of status on public.rental_requests
for each row execute function public.notify_rental_request_event();

create function public.notify_review_event()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (
    user_id, kind, title, message, related_request_id, related_review_id, dedupe_key
  ) values (
    new.owner_id, 'review', 'New review received',
    new.renter_name || ' reviewed ' || new.item_name || '.',
    new.rental_request_id, new.id, 'review:' || new.id::text
  ) on conflict (dedupe_key) do nothing;
  return new;
end;
$$;

create trigger review_notifications after insert on public.reviews
for each row execute function public.notify_review_event();

commit;
