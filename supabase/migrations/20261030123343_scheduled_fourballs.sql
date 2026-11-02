alter table public.rounds add column scheduled_at timestamptz;
alter table public.rounds add column scheduled_by uuid references public.profiles(id);
alter table public.rounds add column scheduling_request text;
create unique index rounds_scheduling_request_idx on public.rounds(scheduled_by, scheduling_request)
  where scheduling_request is not null;

create function public.admin_schedule_fourball(
  p_course_id text, p_tee_set_id text, p_scheduled_at timestamptz,
  p_player_ids uuid[], p_request_key text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_round uuid;
  v_course public.courses;
  v_tee public.tee_sets;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Only league administrators may schedule games.';
  end if;
  if p_request_key is null or length(p_request_key) not between 16 and 128 then
    raise exception 'A valid scheduling request is required.';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text || p_request_key, 0));
  select id into v_round from public.rounds
    where scheduled_by = auth.uid() and scheduling_request = p_request_key;
  if found then return v_round; end if;
  if p_scheduled_at is null or p_scheduled_at <= now() then
    raise exception 'Choose a future tee time.';
  end if;
  if coalesce(cardinality(p_player_ids), 0) not between 1 and 4
    or (select count(distinct id) from unnest(p_player_ids) id) <> cardinality(p_player_ids) then
    raise exception 'Select one to four different registered members.';
  end if;
  if (select count(*) from public.profiles where id = any(p_player_ids)) <> cardinality(p_player_ids) then
    raise exception 'Every player must be a registered member.';
  end if;
  select * into v_course from public.courses where id=p_course_id and active and playable;
  if not found then raise exception 'Choose a round-ready course.'; end if;
  select * into v_tee from public.tee_sets where course_id=p_course_id and id=p_tee_set_id;
  if not found then raise exception 'Choose a tee belonging to this course.'; end if;
  insert into public.rounds(host_user_id,course_id,course_name,tee_set_id,tee_set_name,
    join_code,scheduled_at,scheduled_by,scheduling_request)
  values(p_player_ids[1],v_course.id,v_course.name,v_tee.id,v_tee.name,
    public.generate_join_code(),p_scheduled_at,auth.uid(),p_request_key) returning id into v_round;
  insert into public.round_players(round_id,user_id,display_name,role,handicap_index)
    select v_round,id,display_name,case when id=p_player_ids[1] then 'host' else 'player' end,
      estimated_handicap_index from public.profiles where id=any(p_player_ids);
  return v_round;
end;
$$;
revoke all on function public.admin_schedule_fourball(text,text,timestamptz,uuid[],text) from public, anon;
grant execute on function public.admin_schedule_fourball(text,text,timestamptz,uuid[],text) to authenticated;
