-- Discounts are optional and controlled by the listing owner through FastAPI.
-- Existing listings retain their full daily rate.
alter table public.items
add column if not exists discount_percent integer not null default 0;

alter table public.items
drop constraint if exists items_discount_percent_range;

alter table public.items
add constraint items_discount_percent_range
check (discount_percent between 0 and 20);
