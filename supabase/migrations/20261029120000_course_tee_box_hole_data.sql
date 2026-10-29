-- Verified, tee-specific per-hole distances and optional hole photography.
-- The bundled OpenStreetMap hole coordinates are only straight-line estimates;
-- they are never copied into this official distance table.
alter table public.holes add column if not exists image_url text;

create table if not exists public.tee_box_hole_distances (
  course_id text not null,
  tee_set_id text not null,
  hole_number integer not null check (hole_number between 1 and 18),
  distance_meters integer not null check (distance_meters between 1 and 800),
  source_url text,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now(),
  primary key (course_id, tee_set_id, hole_number),
  foreign key (course_id, tee_set_id)
    references public.tee_sets(course_id, id) on delete cascade,
  foreign key (course_id, hole_number)
    references public.holes(course_id, number) on delete cascade
);

alter table public.tee_box_hole_distances enable row level security;
grant select, insert, update, delete on public.tee_box_hole_distances to authenticated;

drop policy if exists "verified tee distances readable by golfers"
  on public.tee_box_hole_distances;
create policy "verified tee distances readable by golfers"
  on public.tee_box_hole_distances for select to authenticated using (true);

drop policy if exists "admins manage verified tee distances"
  on public.tee_box_hole_distances;
create policy "admins manage verified tee distances"
  on public.tee_box_hole_distances for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

comment on column public.holes.image_url is
  'Optional club-provided or licensed photo for this hole.';
comment on table public.tee_box_hole_distances is
  'Verified tee-to-hole distances by tee box. Do not fill from straight-line map estimates.';
