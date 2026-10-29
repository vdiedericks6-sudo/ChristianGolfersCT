-- Christian Golfers: security helpers, row level security, and round RPCs.

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- SECURITY DEFINER so that policies on rounds/round_players can reference each
-- other without recursing through RLS.
create or replace function public.is_round_member(p_round_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.round_players rp
    where rp.round_id = p_round_id
      and rp.user_id = auth.uid()
  );
$$;

create or replace function public.is_round_host(p_round_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.rounds r
    where r.id = p_round_id
      and r.host_user_id = auth.uid()
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(
    (select p.is_admin from public.profiles p where p.id = auth.uid()),
    false
  );
$$;

-- ---------------------------------------------------------------------------
-- Profile bootstrap: every auth.users row gets a profile.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, email, photo_url)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Christian Golfer'
    ),
    coalesce(new.email, ''),
    nullif(coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture'
    ), '')
  )
  on conflict (id) do update
    set email     = excluded.email,
        photo_url = coalesce(public.profiles.photo_url, excluded.photo_url);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Round RPCs (SECURITY DEFINER: they need to see rounds the caller
-- is not yet a member of, and to guarantee join-code uniqueness).
-- ---------------------------------------------------------------------------
create or replace function public.generate_join_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  candidate text;
  attempt   integer := 0;
begin
  loop
    attempt := attempt + 1;
    candidate := '';

    for i in 1..6 loop
      candidate := candidate || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;

    exit when not exists (select 1 from public.rounds r where r.join_code = candidate);

    if attempt >= 20 then
      raise exception 'Unable to generate a unique join code.';
    end if;
  end loop;

  return candidate;
end;
$$;

create or replace function public.create_round(
  p_course_id    text,
  p_course_name  text,
  p_tee_set_id   text,
  p_tee_set_name text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id  uuid := auth.uid();
  v_round_id uuid;
  v_profile  public.profiles;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;

  select * into v_profile from public.profiles where id = v_user_id;

  insert into public.rounds (
    host_user_id, course_id, course_name, tee_set_id, tee_set_name,
    join_code, format, status, current_hole
  )
  values (
    v_user_id, p_course_id, p_course_name, p_tee_set_id, p_tee_set_name,
    public.generate_join_code(), 'strokePlay', 'waiting', 1
  )
  returning id into v_round_id;

  insert into public.round_players (
    round_id, user_id, display_name, role, active, handicap_index
  )
  values (
    v_round_id,
    v_user_id,
    coalesce(v_profile.display_name, 'Christian Golfer'),
    'host',
    true,
    v_profile.estimated_handicap_index
  );

  return v_round_id;
end;
$$;

create or replace function public.join_round_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id     uuid := auth.uid();
  v_round       public.rounds;
  v_profile     public.profiles;
  v_code        text := upper(trim(p_code));
  v_player_count integer;
begin
  if v_user_id is null then
    raise exception 'You must be signed in.';
  end if;

  if char_length(v_code) <> 6 then
    raise exception 'Enter the six-character round code.';
  end if;

  select * into v_round from public.rounds where join_code = v_code;

  if v_round.id is null then
    raise exception 'No round was found for that code.';
  end if;

  if exists (
    select 1 from public.round_players
    where round_id = v_round.id and user_id = v_user_id
  ) then
    return v_round.id;
  end if;

  if v_round.status <> 'waiting' then
    raise exception 'This round has already started or ended.';
  end if;

  select count(*) into v_player_count
  from public.round_players where round_id = v_round.id;

  if v_player_count >= 8 then
    raise exception 'This round already has eight players.';
  end if;

  select * into v_profile from public.profiles where id = v_user_id;

  insert into public.round_players (
    round_id, user_id, display_name, role, active, handicap_index
  )
  values (
    v_round.id,
    v_user_id,
    coalesce(v_profile.display_name, 'Christian Golfer'),
    'player',
    true,
    v_profile.estimated_handicap_index
  );

  return v_round.id;
end;
$$;

revoke all on function public.create_round(text, text, text, text) from public;
revoke all on function public.join_round_by_code(text) from public;
grant execute on function public.create_round(text, text, text, text) to authenticated;
grant execute on function public.join_round_by_code(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
alter table public.profiles      enable row level security;
alter table public.courses       enable row level security;
alter table public.tee_sets      enable row level security;
alter table public.holes         enable row level security;
alter table public.rounds        enable row level security;
alter table public.round_players enable row level security;
alter table public.hole_scores   enable row level security;

-- profiles: every signed-in golfer can see other golfers (social app),
-- but can only write their own row.
drop policy if exists "profiles readable by signed-in golfers" on public.profiles;
create policy "profiles readable by signed-in golfers"
  on public.profiles for select to authenticated using (true);

drop policy if exists "golfers insert own profile" on public.profiles;
create policy "golfers insert own profile"
  on public.profiles for insert to authenticated with check (auth.uid() = id);

drop policy if exists "golfers update own profile" on public.profiles;
create policy "golfers update own profile"
  on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

-- course catalogue: readable by everyone signed in, writable by admins only.
drop policy if exists "courses readable" on public.courses;
create policy "courses readable"
  on public.courses for select to authenticated using (true);

drop policy if exists "courses admin write" on public.courses;
create policy "courses admin write"
  on public.courses for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "tee sets readable" on public.tee_sets;
create policy "tee sets readable"
  on public.tee_sets for select to authenticated using (true);

drop policy if exists "tee sets admin write" on public.tee_sets;
create policy "tee sets admin write"
  on public.tee_sets for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "holes readable" on public.holes;
create policy "holes readable"
  on public.holes for select to authenticated using (true);

drop policy if exists "holes admin write" on public.holes;
create policy "holes admin write"
  on public.holes for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- rounds: visible to players of that round. Creation goes through create_round.
drop policy if exists "rounds visible to players" on public.rounds;
create policy "rounds visible to players"
  on public.rounds for select to authenticated
  using (host_user_id = auth.uid() or public.is_round_member(id));

drop policy if exists "host updates round" on public.rounds;
create policy "host updates round"
  on public.rounds for update to authenticated
  using (host_user_id = auth.uid()) with check (host_user_id = auth.uid());

drop policy if exists "host deletes round" on public.rounds;
create policy "host deletes round"
  on public.rounds for delete to authenticated
  using (host_user_id = auth.uid());

-- round players: visible to the group; you manage your own row, host manages all.
drop policy if exists "players visible to group" on public.round_players;
create policy "players visible to group"
  on public.round_players for select to authenticated
  using (user_id = auth.uid() or public.is_round_member(round_id));

drop policy if exists "players update own row" on public.round_players;
create policy "players update own row"
  on public.round_players for update to authenticated
  using (user_id = auth.uid() or public.is_round_host(round_id))
  with check (user_id = auth.uid() or public.is_round_host(round_id));

drop policy if exists "players leave round" on public.round_players;
create policy "players leave round"
  on public.round_players for delete to authenticated
  using (user_id = auth.uid() or public.is_round_host(round_id));

-- scores: the whole group sees the card, each golfer writes only their own.
drop policy if exists "scores visible to group" on public.hole_scores;
create policy "scores visible to group"
  on public.hole_scores for select to authenticated
  using (public.is_round_member(round_id));

drop policy if exists "golfers insert own scores" on public.hole_scores;
create policy "golfers insert own scores"
  on public.hole_scores for insert to authenticated
  with check (player_id = auth.uid() and public.is_round_member(round_id));

drop policy if exists "golfers update own scores" on public.hole_scores;
create policy "golfers update own scores"
  on public.hole_scores for update to authenticated
  using (player_id = auth.uid() and public.is_round_member(round_id))
  with check (player_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------
do $$
declare
  target text;
begin
  foreach target in array array[
    'profiles', 'courses', 'tee_sets', 'holes',
    'rounds', 'round_players', 'hole_scores'
  ]
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = target
    ) then
      execute format('alter publication supabase_realtime add table public.%I', target);
    end if;
  end loop;
end;
$$;

-- Realtime needs the full row (not just the primary key) on updates/deletes.
alter table public.rounds        replica identity full;
alter table public.round_players replica identity full;
alter table public.hole_scores   replica identity full;
