-- Existing players keep a null tee and therefore retain the historical
-- shared round tee; no historical cards or results are rewritten.
alter table public.round_players add column if not exists tee_set_id text;
comment on column public.round_players.tee_set_id is
  'The golfer-selected tee for this round; null means the shared round tee.';

-- Players do not directly modify handicap snapshots, identity or other
-- golfers' seats. The tee trigger below also limits this column to their own.
revoke update on public.round_players from anon, authenticated;
grant update (tee_set_id) on public.round_players to authenticated;

-- Validate even direct updates allowed by existing RLS policies, and lock the
-- same round row used by score writes so a tee cannot race the first score.
create or replace function public.guard_player_tee_change()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare v_round public.rounds; v_tee public.tee_sets;
begin
  if new.tee_set_id is not distinct from old.tee_set_id then return new; end if;
  if auth.uid() is null or auth.uid() <> old.user_id or new.user_id <> old.user_id
     or new.round_id <> old.round_id or not old.active or not new.active then
    raise exception 'Only an active player can choose their own tee.' using errcode='42501';
  end if;
  select * into v_round from public.rounds where id=old.round_id for update;
  if not found or v_round.status not in ('waiting','active') then
    raise exception 'A tee can only be selected before the round is completed.';
  end if;
  if exists(select 1 from public.hole_scores s where s.round_id=old.round_id and s.player_id=old.user_id) then
    raise exception 'The tee cannot be changed after this golfer has a saved score.';
  end if;
  if new.tee_set_id is null then raise exception 'Choose an available tee.'; end if;
  select * into v_tee from public.tee_sets t where t.course_id=v_round.course_id
    and t.id=new.tee_set_id and t.selectable;
  if not found then raise exception 'Choose an available tee for this course.'; end if;
  if v_tee.course_rating <= 0 or v_tee.slope_rating not between 55 and 155 then
    raise exception 'This tee needs a valid course rating and slope before it can be selected.';
  end if;
  if new.handicap_index is distinct from old.handicap_index then
    raise exception 'Handicap index cannot be changed while choosing a tee.';
  end if;
  new.course_handicap := case when old.handicap_index is null then null else
    round(old.handicap_index * (v_tee.slope_rating / 113.0) + (v_tee.course_rating - v_tee.par))::integer end;
  new.playing_handicap := new.course_handicap;
  return new;
end $$;
revoke all on function public.guard_player_tee_change() from public, anon, authenticated;
create trigger guard_player_tee_change before update of tee_set_id on public.round_players
for each row execute function public.guard_player_tee_change();

create or replace function public.set_my_round_tee(p_round_id uuid, p_tee_set_id text)
returns void language plpgsql security invoker set search_path = public, pg_temp as $$
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
  if p_tee_set_id is null then raise exception 'Choose an available tee.'; end if;
  update public.round_players set tee_set_id=p_tee_set_id
    where round_id=p_round_id and user_id=auth.uid() and active;
  if not found then raise exception 'You are not an active player in this round.' using errcode='42501'; end if;
end $$;
revoke all on function public.set_my_round_tee(uuid,text) from public, anon;
grant execute on function public.set_my_round_tee(uuid,text) to authenticated;

-- Recalculate future completed rounds using each player's tee. Missing
-- handicap indices are omitted from net results, never treated as scratch;
-- their gross scores remain visible on the scorecard and admin dashboard.
create or replace function public.complete_round(p_round_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_round public.rounds;
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
  select * into v_round from public.rounds where id=p_round_id for update;
  if not found then raise exception 'Round not found.'; end if;
  if v_round.host_user_id <> auth.uid() then raise exception 'Only the host can complete the round.' using errcode='42501'; end if;
  if v_round.status='completed' then return; end if;
  if v_round.status <> 'active' then raise exception 'The round is not active.'; end if;
  if not exists(select 1 from public.round_players p where p.round_id=p_round_id and p.active)
    or exists(select 1 from public.round_players p where p.round_id=p_round_id and p.active and
      (select count(*) from public.hole_scores s where s.round_id=p.round_id and s.player_id=p.user_id and s.confirmed) <> 18) then
    raise exception 'Every active player must have 18 confirmed hole scores before completing this round.';
  end if;
  if (select count(*) from public.holes h where h.course_id=v_round.course_id) <> 18 then
    raise exception 'The course needs 18 holes to calculate round results.';
  end if;
  if exists(select 1 from public.round_players p
    left join public.tee_sets t on t.course_id=v_round.course_id and t.id=coalesce(p.tee_set_id,v_round.tee_set_id)
    where p.round_id=p_round_id and p.active and p.handicap_index is not null
      and (t.id is null or t.course_rating <= 0 or t.slope_rating not between 55 and 155)) then
    raise exception 'A player tee is missing a valid rating or slope; net results cannot be calculated.';
  end if;
  with players as (
    select p.round_id,p.user_id,p.handicap_index,
      round(p.handicap_index * (t.slope_rating / 113.0) + (t.course_rating-t.par))::integer as course_handicap
    from public.round_players p
    join public.tee_sets t on t.course_id=v_round.course_id and t.id=coalesce(p.tee_set_id,v_round.tee_set_id)
    where p.round_id=p_round_id and p.active and p.handicap_index is not null
  ), scores as (
    select p.user_id,p.handicap_index,p.course_handicap,count(s.hole_number)::integer as holes_played,
      sum(s.strokes+s.penalty_strokes)::integer as gross,
      sum(s.strokes+s.penalty_strokes - case when p.course_handicap>=0 then
        (p.course_handicap/18) + case when h.stroke_index <= (p.course_handicap%18) then 1 else 0 end
        else -(abs(p.course_handicap)/18) - case when abs(p.course_handicap)%18>0
          and h.stroke_index>18-(abs(p.course_handicap)%18) then 1 else 0 end end)::integer as net
    from players p join public.hole_scores s on s.round_id=p.round_id and s.player_id=p.user_id and s.confirmed
    join public.holes h on h.course_id=v_round.course_id and h.number=s.hole_number
    group by p.user_id,p.handicap_index,p.course_handicap
  ), ranked as (
    select scores.*,dense_rank() over(order by net asc,gross asc)::integer as position from scores
  )
  insert into public.round_results(round_id,player_id,handicap_index,course_handicap,holes_played,gross_strokes,net_strokes,position)
  select p_round_id,user_id,handicap_index,course_handicap,holes_played,gross,net,position from ranked
  on conflict (round_id,player_id) do update set handicap_index=excluded.handicap_index,
    course_handicap=excluded.course_handicap,holes_played=excluded.holes_played,
    gross_strokes=excluded.gross_strokes,net_strokes=excluded.net_strokes,position=excluded.position,completed_at=now();
  update public.rounds set status='completed',completed_at=now() where id=p_round_id;
end $$;
revoke all on function public.complete_round(uuid) from public, anon;
grant execute on function public.complete_round(uuid) to authenticated;

-- Successful offline requests can be retried after a lost response without
-- repeating a write. Only the validated server function can access receipts.
create table public.score_sync_receipts (
  request_id uuid primary key,
  actor_id uuid not null references public.profiles(id) on delete cascade,
  request_payload jsonb not null,
  created_at timestamptz not null default now()
);
alter table public.score_sync_receipts enable row level security;
revoke all on public.score_sync_receipts from public, anon, authenticated;

-- Bind queued operations to the original account; old clients may omit it.
drop function public.save_group_hole_score(uuid,uuid,integer,integer,integer,integer,integer,text,boolean,timestamptz,boolean);
create or replace function public.save_group_hole_score(
  p_round_id uuid, p_player_id uuid, p_hole_number integer,
  p_strokes integer, p_putts integer, p_penalty_strokes integer,
  p_sand_shots integer, p_fairway text, p_green_in_regulation boolean,
  p_expected_updated_at timestamptz, p_expected_exists boolean, p_actor_id uuid default null, p_request_id uuid default null
) returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_status text; v_before jsonb; v_after jsonb; v_request jsonb; v_receipt public.score_sync_receipts;
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode = '42501'; end if;
  if p_actor_id is not null and p_actor_id <> auth.uid() then
    raise exception 'The queued score belongs to a different signed-in account.' using errcode = '42501';
  end if;
  if p_request_id is not null then
    if p_actor_id is null then raise exception 'Queued score actor required.' using errcode='42501'; end if;
    v_request := jsonb_build_object('round',p_round_id,'player',p_player_id,'hole',p_hole_number,
      'strokes',p_strokes,'putts',p_putts,'penalties',p_penalty_strokes,'sand',p_sand_shots,
      'fairway',p_fairway,'gir',p_green_in_regulation,'expected_at',p_expected_updated_at,
      'expected_exists',p_expected_exists);
    perform pg_advisory_xact_lock(hashtextextended('score_request:' || p_request_id::text, 0));
    select * into v_receipt from public.score_sync_receipts where request_id=p_request_id;
    if found then
      if v_receipt.actor_id <> auth.uid() or v_receipt.request_payload <> v_request then
        raise exception 'Score request ID is already associated with another request.' using errcode='22023';
      end if;
      return;
    end if;
  end if;
  select status into v_status from public.rounds where id = p_round_id for update;
  if v_status is distinct from 'active' then raise exception 'Round is not active.'; end if;
  if not exists (select 1 from public.round_players where round_id = p_round_id and user_id = auth.uid() and active)
     or not exists (select 1 from public.round_players where round_id = p_round_id and user_id = p_player_id and active) then
    raise exception 'Both golfers must be active members of this fourball.' using errcode = '42501';
  end if;
  if p_hole_number is null or p_hole_number not between 1 and 18 or
     p_strokes is null or p_strokes not between 1 and 20 or
     p_putts is null or p_putts not between 0 and 10 or
     p_penalty_strokes is null or p_penalty_strokes not between 0 and 10 or
     p_sand_shots is null or p_sand_shots not between 0 and 10 or
     (p_fairway is not null and p_fairway not in ('left','hit','right','missed')) then
    raise exception 'Invalid hole score.' using errcode = '22023';
  end if;
  select to_jsonb(s) into v_before from public.hole_scores s
   where s.round_id = p_round_id and s.player_id = p_player_id and s.hole_number = p_hole_number;
  if p_expected_exists is null or p_expected_exists <> (v_before is not null)
    or (p_expected_exists and (v_before->>'updated_at')::timestamptz is distinct from p_expected_updated_at) then
    raise exception 'This score changed on another device. Reload and review before saving.' using errcode = '40001';
  end if;
  if p_player_id <> auth.uid() and coalesce((v_before->>'confirmed')::boolean, false) then
    raise exception 'This golfer has already confirmed this score; ask them or an administrator to change it.';
  end if;
  insert into public.hole_scores(round_id,player_id,hole_number,strokes,putts,penalty_strokes,sand_shots,fairway,green_in_regulation,confirmed,updated_by)
  values(p_round_id,p_player_id,p_hole_number,p_strokes,p_putts,p_penalty_strokes,p_sand_shots,p_fairway,p_green_in_regulation,p_player_id = auth.uid(),auth.uid())
  on conflict (round_id,player_id,hole_number) do update set
    strokes=excluded.strokes,putts=excluded.putts,penalty_strokes=excluded.penalty_strokes,
    sand_shots=excluded.sand_shots,fairway=excluded.fairway,green_in_regulation=excluded.green_in_regulation,
    confirmed=excluded.confirmed,updated_by=excluded.updated_by;
  select to_jsonb(s) into v_after from public.hole_scores s
   where s.round_id = p_round_id and s.player_id = p_player_id and s.hole_number = p_hole_number;
  insert into public.admin_audit(actor,entity,record_id,reason,before_data,after_data)
  values(auth.uid(),'hole_score',p_round_id::text || '/' || p_player_id::text || '/' || p_hole_number::text,
    'Fourball score entry',v_before,v_after);
  if p_request_id is not null then
    insert into public.score_sync_receipts(request_id,actor_id,request_payload)
      values(p_request_id,auth.uid(),v_request);
  end if;
end $$;
revoke all on function public.save_group_hole_score(uuid,uuid,integer,integer,integer,integer,integer,text,boolean,timestamptz,boolean,uuid,uuid) from public, anon;
grant execute on function public.save_group_hole_score(uuid,uuid,integer,integer,integer,integer,integer,text,boolean,timestamptz,boolean,uuid,uuid) to authenticated;



-- Add player-specific tee labels to the existing allowlisted dashboard.
-- The league owner/captain dashboard needs cross-member reads, but ordinary
-- golfers must continue to see only their own rounds and round groups.
-- Keep the privileged read behind the same server-side allowlist as is_admin.
create or replace function public.admin_league_dashboard(
  p_from_date date default null,
  p_to_date date default null
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public, pg_temp
as $$
declare
  v_dashboard jsonb;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator access required.' using errcode = '42501';
  end if;

  if p_from_date is not null and p_to_date is not null and p_from_date > p_to_date then
    raise exception 'Start date must be on or before end date.' using errcode = '22007';
  end if;

  with filtered_rounds as materialized (
    select r.*,
           coalesce(r.completed_at, r.started_at, r.scheduled_at, r.created_at) as played_at
      from public.rounds r
     where (p_from_date is null or
            (coalesce(r.completed_at, r.started_at, r.scheduled_at, r.created_at)
              at time zone 'Africa/Johannesburg')::date >= p_from_date)
       and (p_to_date is null or
            (coalesce(r.completed_at, r.started_at, r.scheduled_at, r.created_at)
              at time zone 'Africa/Johannesburg')::date <= p_to_date)
  )
  select jsonb_build_object(
    'members', coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id', p.id,
        'display_name', p.display_name,
        'email', p.email,
        'handicap_index', p.estimated_handicap_index,
        'is_visiting_golfer', p.is_visiting_golfer,
        'created_at', p.created_at
      ) order by lower(p.display_name))
        from public.profiles p
    ), '[]'::jsonb),
    'rounds', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', r.id,
        'course_name', r.course_name,
        'tee_set_name', r.tee_set_name,
        'status', r.status,
        'format', r.format,
        'current_hole', r.current_hole,
        'host_user_id', r.host_user_id,
        'host_name', coalesce(p.display_name, 'Golfer'),
        'created_at', r.created_at,
        'scheduled_at', r.scheduled_at,
        'started_at', r.started_at,
        'completed_at', r.completed_at,
        'played_at', r.played_at
      ) order by r.played_at desc)
        from filtered_rounds r
        left join public.profiles p on p.id = r.host_user_id
    ), '[]'::jsonb),
    'players', coalesce((
      select jsonb_agg(jsonb_build_object(
        'round_id', rp.round_id,
        'user_id', rp.user_id,
        'display_name', coalesce(rp.display_name, p.display_name, 'Golfer'),
        'email', p.email,
        'role', rp.role,
        'active', rp.active,
        'handicap_index', rp.handicap_index,
        'course_handicap', rp.course_handicap,
        'playing_handicap', rp.playing_handicap,
        'tee_set_id', rp.tee_set_id,
        'tee_set_name', coalesce(t.name, r.tee_set_name),
        'joined_at', rp.joined_at
      ) order by rp.round_id, lower(coalesce(rp.display_name, p.display_name, 'Golfer')))
        from public.round_players rp
        join filtered_rounds r on r.id = rp.round_id
        left join public.tee_sets t on t.course_id=r.course_id and t.id=rp.tee_set_id
        left join public.profiles p on p.id = rp.user_id
    ), '[]'::jsonb),
    'scores', coalesce((
      select jsonb_agg(jsonb_build_object(
        'round_id', hs.round_id,
        'player_id', hs.player_id,
        'hole_number', hs.hole_number,
        'par', h.par,
        'stroke_index', h.stroke_index,
        'strokes', hs.strokes,
        'putts', hs.putts,
        'penalty_strokes', hs.penalty_strokes,
        'confirmed', hs.confirmed,
        'updated_at', hs.updated_at
      ) order by hs.round_id, hs.player_id, hs.hole_number)
        from public.hole_scores hs
        join filtered_rounds r on r.id = hs.round_id
        left join public.holes h
          on h.course_id = r.course_id and h.number = hs.hole_number
    ), '[]'::jsonb),
    'results', coalesce((
      select jsonb_agg(jsonb_build_object(
        'round_id', rr.round_id,
        'player_id', rr.player_id,
        'display_name', coalesce(p.display_name, 'Golfer'),
        'handicap_index', rr.handicap_index,
        'course_handicap', rr.course_handicap,
        'holes_played', rr.holes_played,
        'gross_strokes', rr.gross_strokes,
        'net_strokes', rr.net_strokes,
        'position', rr.position,
        'completed_at', rr.completed_at
      ) order by rr.round_id, rr.position, lower(coalesce(p.display_name, 'Golfer')))
        from public.round_results rr
        join filtered_rounds r on r.id = rr.round_id
        left join public.profiles p on p.id = rr.player_id
    ), '[]'::jsonb),
    'league_a_max_handicap', (select s.league_a_max_handicap from public.league_settings s where s.id = 1),
    'league_b_max_handicap', (select s.league_b_max_handicap from public.league_settings s where s.id = 1)
  ) into v_dashboard;

  return v_dashboard;
end;
$$;
