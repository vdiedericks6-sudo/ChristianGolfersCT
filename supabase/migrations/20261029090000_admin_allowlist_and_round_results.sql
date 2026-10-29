-- Admins are provisioned as Supabase Auth users before release and explicitly
-- allowlisted here. Never store the password in the app or in this table.
create table if not exists public.admin_allowlist (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  added_at timestamptz not null default now()
);

alter table public.admin_allowlist enable row level security;
revoke all on public.admin_allowlist from public, anon, authenticated;

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.admin_allowlist a where a.user_id = auth.uid()
  );
$$;

revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- A created round is one four-ball. Serialize joins on the round row so two
-- simultaneous invitations cannot seat a fifth golfer.
create or replace function public.join_round_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_round public.rounds;
  v_profile public.profiles;
  v_player_count integer;
  v_code text := upper(trim(p_code));
begin
  if v_user_id is null then raise exception 'You must be signed in.'; end if;
  if char_length(v_code) <> 6 then raise exception 'Enter the six-character round code.'; end if;

  select * into v_round from public.rounds where join_code = v_code for update;
  if v_round.id is null then raise exception 'No round was found for that code.'; end if;
  if exists (select 1 from public.round_players where round_id = v_round.id and user_id = v_user_id) then
    return v_round.id;
  end if;
  if v_round.status <> 'waiting' then raise exception 'This round has already started or ended.'; end if;

  select count(*) into v_player_count from public.round_players where round_id = v_round.id;
  if v_player_count >= 4 then raise exception 'This 4-ball already has four players.'; end if;

  select * into v_profile from public.profiles where id = v_user_id;
  insert into public.round_players (round_id, user_id, display_name, role, active, handicap_index)
  values (v_round.id, v_user_id, coalesce(v_profile.display_name, 'Christian Golfer'),
          'player', true, v_profile.estimated_handicap_index);
  return v_round.id;
end;
$$;

revoke all on function public.join_round_by_code(text) from public, anon;
grant execute on function public.join_round_by_code(text) to authenticated;

create table if not exists public.round_results (
  round_id uuid not null references public.rounds(id) on delete cascade,
  player_id uuid not null references public.profiles(id) on delete cascade,
  handicap_index numeric(4,1),
  course_handicap integer not null,
  holes_played integer not null,
  gross_strokes integer not null,
  net_strokes integer not null,
  position integer not null,
  completed_at timestamptz not null default now(),
  primary key (round_id, player_id)
);

alter table public.round_results enable row level security;
grant select on public.round_results to authenticated;
drop policy if exists "round results visible to players" on public.round_results;
create policy "round results visible to players"
  on public.round_results for select to authenticated
  using (public.is_round_member(round_id));

create or replace function public.complete_round(p_round_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_round public.rounds;
begin
  select * into v_round from public.rounds where id = p_round_id for update;
  if not found then raise exception 'Round not found.'; end if;
  if v_round.host_user_id <> auth.uid() then
    raise exception 'Only the host can complete the round.';
  end if;
  if v_round.status = 'completed' then return; end if;

  with tee as (
    select t.slope_rating, t.course_rating, t.par
      from public.tee_sets t
     where t.course_id = v_round.course_id and t.id = v_round.tee_set_id
  ), players as (
    select rp.round_id, rp.user_id, rp.handicap_index, rp.active,
           coalesce(round(rp.handicap_index * (tee.slope_rating / 113.0)
             + (tee.course_rating - tee.par))::integer, 0) as course_handicap
      from public.round_players rp
      cross join tee
     where rp.round_id = p_round_id and rp.active
  ), scores as (
    select players.user_id, players.handicap_index, players.course_handicap,
           count(hs.hole_number)::integer as holes_played,
           coalesce(sum(hs.strokes + hs.penalty_strokes), 0)::integer as gross,
           coalesce(sum(hs.strokes + hs.penalty_strokes
             - case when players.handicap_index is null then 0
                 when players.course_handicap >= 0 then
                   (players.course_handicap / 18)
                   + case when h.stroke_index <= (players.course_handicap % 18)
                     then 1 else 0 end
                 else -(abs(players.course_handicap) / 18)
                   - case when abs(players.course_handicap) % 18 > 0
                        and h.stroke_index > 18 - (abs(players.course_handicap) % 18)
                     then 1 else 0 end
               end), 0)::integer as net
      from players
      left join public.hole_scores hs
        on hs.round_id = players.round_id and hs.player_id = players.user_id
      left join public.holes h
        on h.course_id = v_round.course_id and h.number = hs.hole_number
     group by players.user_id, players.handicap_index, players.course_handicap
  ), ranked as (
    select scores.*, dense_rank() over (order by net asc, gross asc)::integer as position
      from scores
  )
  insert into public.round_results
    (round_id, player_id, handicap_index, course_handicap, holes_played,
     gross_strokes, net_strokes, position)
  select p_round_id, user_id, handicap_index, course_handicap, holes_played,
         gross, net, position
    from ranked
  on conflict (round_id, player_id) do update set
    handicap_index = excluded.handicap_index,
    course_handicap = excluded.course_handicap,
    holes_played = excluded.holes_played,
    gross_strokes = excluded.gross_strokes,
    net_strokes = excluded.net_strokes,
    position = excluded.position,
    completed_at = now();

  update public.rounds
     set status = 'completed', completed_at = now()
   where id = p_round_id;
end;
$$;

revoke all on function public.complete_round(uuid) from public, anon;
grant execute on function public.complete_round(uuid) to authenticated;

comment on table public.admin_allowlist is
  'Only explicitly provisioned Supabase Auth users can administer this app. Credentials are managed by Supabase Auth, never stored here.';
comment on table public.round_results is
  'Per-player completed-round gross and handicap-adjusted net totals and round placing.';
