-- Christian Golfers: driving ranges.
--
-- A separate table rather than a facility_type flag on courses, because a
-- range has its own vocabulary - bays, floodlights, ball tracking - and none
-- of the golf-round machinery (tee sets, holes, scorecards) applies to it.

create table if not exists public.driving_ranges (
  id          text primary key,

  -- Set when the range belongs to a club that is also in the courses table.
  course_id   text references public.courses (id) on delete set null,

  name        text        not null,
  country     text        not null default 'South Africa',
  province    text        not null default '',
  city        text,
  address     text,
  description text,
  website     text,
  phone       text,
  image_url   text,
  latitude    double precision,
  longitude   double precision,
  active      boolean     not null default true,

  -- Range-specific detail. Not in OpenStreetMap, so these start null and get
  -- filled in by admins or, later, by the clubs themselves.
  bays        integer     check (bays is null or bays between 1 and 200),
  floodlit    boolean,
  covered     boolean,
  ball_tracking text      check (
                  ball_tracking is null or
                  ball_tracking in ('none', 'toptracer', 'trackman', 'other')
                ),

  data_status text,
  source_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists driving_ranges_province_name_idx
  on public.driving_ranges (province, name);

create index if not exists driving_ranges_course_idx
  on public.driving_ranges (course_id);

drop trigger if exists touch_driving_ranges_updated_at on public.driving_ranges;
create trigger touch_driving_ranges_updated_at
  before update on public.driving_ranges
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Row level security: same shape as the course catalogue.
-- ---------------------------------------------------------------------------
alter table public.driving_ranges enable row level security;

drop policy if exists "driving ranges readable" on public.driving_ranges;
create policy "driving ranges readable"
  on public.driving_ranges for select to authenticated using (true);

drop policy if exists "driving ranges admin write" on public.driving_ranges;
create policy "driving ranges admin write"
  on public.driving_ranges for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'driving_ranges'
  ) then
    alter publication supabase_realtime add table public.driving_ranges;
  end if;
end;
$$;
