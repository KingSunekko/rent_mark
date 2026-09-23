alter table public.items
add column if not exists image_paths text[] not null default '{}';

update public.items
set image_paths = coalesce(
  array(
    select regexp_replace(
      image_url,
      '^.*/storage/v1/object/public/item-images/',
      ''
    )
    from unnest(image_urls) as image_url
    where image_url like '%/storage/v1/object/public/item-images/%'
  ),
  '{}'
)
where cardinality(image_paths) = 0
  and cardinality(image_urls) > 0;

alter table public.items
drop constraint if exists items_image_paths_limit;

alter table public.items
add constraint items_image_paths_limit
check (cardinality(image_paths) <= 5);

