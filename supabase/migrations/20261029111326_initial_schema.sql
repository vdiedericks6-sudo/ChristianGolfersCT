-- Christian Golfers: initial Supabase schema.
-- Run once against a fresh Supabase project.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Profiles
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id                       uuid primary key references auth.users (id) on delete cascade,
  display_name             text        not null default 'Christian Golfer',
  email                    text        not null default '',
  photo_url                text,
  estimated_handicap_index numeric(4,1),
  preferred_distance_unit  text        not null default 'metres'
                             check (preferred_distance_unit in ('metres', 'yards')),
  is_admin                 boolean     not null default false,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Courses / tee sets / holes
-- ---------------------------------------------------------------------------
create table if not exists public.courses (
  id          text primary key,
  name        text        not null,
  country     text        not null default '',
  province    text        not null default '',
  city        text,
  address     text,
  description text,
  website     text,
  phone       text,
  image_url   text,
  latitude    double precision,
  longitude   double precision,
  par         integer,
  holes       integer,
  active      boolean     not null default false,
  playable    boolean     not null default true,
  data_status text,
  source_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists courses_active_name_idx on public.courses (active, name);

create table if not exists public.tee_sets (
  course_id      text        not null references public.courses (id) on delete cascade,
  id             text        not null,
  name           text        not null default '',
  colour         text        not null default '',
  course_rating  numeric(4,1) not null default 0,
  slope_rating   integer     not null default 113,
  par            integer     not null default 72,
  total_distance integer     not null default 0,
  distance_unit  text        not null default 'metres',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  primary key (course_id, id)
);

create table if not exists public.holes (
  course_id             text        not null references public.courses (id) on delete cascade,
  number                integer     not null check (number between 1 and 18),
  par                   integer     not null default 4,
  stroke_index          integer     not null default 18
                          check (stroke_index between 1 and 18),
  tee_latitude          double precision not null default 0,
  tee_longitude         double precision not null default 0,
  green_front_latitude  double precision not null default 0,
  green_front_longitude double precision not null default 0,
  green_centre_latitude double precision not null default 0,
  green_centre_longitude double precision not null default 0,
  green_back_latitude   double precision not null default 0,
  green_back_longitude  double precision not null default 0,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  primary key (course_id, number)
);

-- ---------------------------------------------------------------------------
-- Rounds
-- ---------------------------------------------------------------------------
create table if not exists public.rounds (
  id           uuid primary key default gen_random_uuid(),
  host_user_id uuid        not null references public.profiles (id) on delete cascade,
  course_id    text        not null references public.courses (id),
  course_name  text        not null default '',
  tee_set_id   text        not null default '',
  tee_set_name text        not null default '',
  join_code    text        not null unique check (char_length(join_code) = 6),
  format       text        not null default 'strokePlay',
  status       text        not null default 'waiting'
                 check (status in ('waiting', 'active', 'completed')),
  current_hole integer     not null default 1 check (current_hole between 1 and 18),
  created_at   timestamptz not null default now(),
  started_at   timestamptz,
  completed_at timestamptz
);

create index if not exists rounds_host_idx on public.rounds (host_user_id, created_at desc);

create table if not exists public.round_players (
  round_id         uuid        not null references public.rounds (id) on delete cascade,
  user_id          uuid        not null references public.profiles (id) on delete cascade,
  display_name     text        not null default 'Christian Golfer',
  role             text        not null default 'player' check (role in ('host', 'player')),
  active           boolean     not null default true,
  handicap_index   numeric(4,1),
  course_handicap  integer,
  playing_handicap integer,
  joined_at        timestamptz not null default now(),
  primary key (round_id, user_id)
);

create index if not exists round_players_user_idx on public.round_players (user_id);

create table if not exists public.hole_scores (
  round_id        uuid        not null references public.rounds (id) on delete cascade,
  player_id       uuid        not null references public.profiles (id) on delete cascade,
  hole_number     integer     not null check (hole_number between 1 and 18),
  strokes         integer     not null check (strokes between 1 and 20),
  putts           integer     not null default 0 check (putts between 0 and 10),
  penalty_strokes integer     not null default 0 check (penalty_strokes between 0 and 10),
  confirmed       boolean     not null default true,
  updated_at      timestamptz not null default now(),
  updated_by      uuid,
  primary key (round_id, player_id, hole_number)
);

-- ---------------------------------------------------------------------------
-- updated_at maintenance
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$
declare
  target text;
begin
  foreach target in array array['profiles', 'courses', 'tee_sets', 'holes', 'hole_scores']
  loop
    execute format(
      'drop trigger if exists touch_%1$s_updated_at on public.%1$I', target
    );
    execute format(
      'create trigger touch_%1$s_updated_at before update on public.%1$I
         for each row execute function public.touch_updated_at()', target
    );
  end loop;
end;
$$;
