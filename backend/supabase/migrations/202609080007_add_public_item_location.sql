begin;
alter table public.items
  add column if not exists city text not null default '',
  add column if not exists barangay text not null default '',
  add column if not exists meeting_point text not null default '',
  add column if not exists pickup_instructions text not null default '';
alter table public.items add constraint items_public_location_lengths check (
  char_length(city) <= 120 and char_length(barangay) <= 120
  and char_length(meeting_point) <= 200 and char_length(pickup_instructions) <= 1000
);
comment on column public.items.meeting_point is 'Public meeting point only. Do not store private home addresses.';
comment on column public.items.pickup_instructions is 'Public pickup instructions visible in the item catalog.';
commit;
