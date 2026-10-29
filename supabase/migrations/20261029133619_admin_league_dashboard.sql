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
           coalesce(r.completed_at, r.started_at, r.created_at) as played_at
      from public.rounds r
     where (p_from_date is null or
            (coalesce(r.completed_at, r.started_at, r.created_at)
              at time zone 'Africa/Johannesburg')::date >= p_from_date)
       and (p_to_date is null or
            (coalesce(r.completed_at, r.started_at, r.created_at)
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
        'joined_at', rp.joined_at
      ) order by rp.round_id, lower(coalesce(rp.display_name, p.display_name, 'Golfer')))
        from public.round_players rp
        join filtered_rounds r on r.id = rp.round_id
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

revoke all on function public.admin_league_dashboard(date, date) from public, anon;
grant execute on function public.admin_league_dashboard(date, date) to authenticated;

comment on function public.admin_league_dashboard(date, date) is
  'Returns member, round, player, hole-score, and completed-result data for the allowlisted league owner/captain dashboard only.';
