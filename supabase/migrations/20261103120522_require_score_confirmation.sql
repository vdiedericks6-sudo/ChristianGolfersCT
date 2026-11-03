-- This schema currently represents 18-hole rounds only; never rank a player
-- with missing or provisional scores as a zero-stroke prize winner.
-- The round lock shared with score writes makes this safe against concurrent saves.
create or replace function public.guard_round_score_confirmation()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if new.status = 'completed' and old.status is distinct from 'completed' and (
    not exists (select 1 from public.round_players p where p.round_id=new.id and p.active)
    or exists (
      select 1 from public.round_players p
      where p.round_id=new.id and p.active and
        (select count(*) from public.hole_scores s where s.round_id=p.round_id
          and s.player_id=p.user_id and s.confirmed) <> 18
    )
  ) then
    raise exception 'Every active player must have 18 confirmed hole scores before completing this round.';
  end if;
  return new;
end $$;
revoke all on function public.guard_round_score_confirmation() from public, anon, authenticated;
create trigger guard_round_score_confirmation before update of status on public.rounds
for each row execute function public.guard_round_score_confirmation();

-- Require the version the editor actually loaded, including when no score existed.
drop function public.save_group_hole_score(uuid,uuid,integer,integer,integer,integer,integer,text,boolean);
create or replace function public.save_group_hole_score(
  p_round_id uuid, p_player_id uuid, p_hole_number integer,
  p_strokes integer, p_putts integer, p_penalty_strokes integer,
  p_sand_shots integer, p_fairway text, p_green_in_regulation boolean,
  p_expected_updated_at timestamptz, p_expected_exists boolean
) returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_status text; v_before jsonb; v_after jsonb;
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode = '42501'; end if;
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
end $$;
revoke all on function public.save_group_hole_score(uuid,uuid,integer,integer,integer,integer,integer,text,boolean,timestamptz,boolean) from public, anon;
grant execute on function public.save_group_hole_score(uuid,uuid,integer,integer,integer,integer,integer,text,boolean,timestamptz,boolean) to authenticated;


drop function public.admin_save_hole_score(uuid,uuid,integer,integer,integer,integer,text);
create or replace function public.admin_save_hole_score(
  p_round_id uuid, p_player_id uuid, p_hole_number integer,
  p_strokes integer, p_putts integer, p_penalty_strokes integer, p_reason text,
  p_expected_updated_at timestamptz, p_expected_exists boolean
) returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_status text; v_before jsonb; v_after jsonb;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator access required.' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_reason,''))) < 3 then raise exception 'Provide a reason for the score change.'; end if;
  select status into v_status from public.rounds where id = p_round_id for update;
  if v_status is distinct from 'active' then
    raise exception 'Scores can only be changed during an active round; completed results require an audited recalculation.';
  end if;
  if not exists (select 1 from public.round_players where round_id=p_round_id and user_id=p_player_id and active) then
    raise exception 'Player is not active in this fourball.';
  end if;
  if p_hole_number is null or p_hole_number not between 1 and 18 or
     p_strokes is null or p_strokes not between 1 and 20 or
     p_putts is null or p_putts not between 0 and 10 or
     p_penalty_strokes is null or p_penalty_strokes not between 0 and 10 then
    raise exception 'Invalid hole score.' using errcode='22023';
  end if;
  select to_jsonb(s) into v_before from public.hole_scores s
   where s.round_id=p_round_id and s.player_id=p_player_id and s.hole_number=p_hole_number;
  if p_expected_exists is null or p_expected_exists <> (v_before is not null)
    or (p_expected_exists and (v_before->>'updated_at')::timestamptz is distinct from p_expected_updated_at) then
    raise exception 'This score changed on another device. Reload and review before saving.' using errcode = '40001';
  end if;
  insert into public.hole_scores(round_id,player_id,hole_number,strokes,putts,penalty_strokes,confirmed,updated_by)
  values(p_round_id,p_player_id,p_hole_number,p_strokes,p_putts,p_penalty_strokes,false,auth.uid())
  on conflict (round_id,player_id,hole_number) do update set
    strokes=excluded.strokes,putts=excluded.putts,penalty_strokes=excluded.penalty_strokes,
    confirmed=false,updated_by=excluded.updated_by;
  select to_jsonb(s) into v_after from public.hole_scores s
   where s.round_id=p_round_id and s.player_id=p_player_id and s.hole_number=p_hole_number;
  insert into public.admin_audit(actor,entity,record_id,reason,before_data,after_data)
  values(auth.uid(),'hole_score',p_round_id::text || '/' || p_player_id::text || '/' || p_hole_number::text,
    trim(p_reason),v_before,v_after);
end $$;
revoke all on function public.admin_save_hole_score(uuid,uuid,integer,integer,integer,integer,text,timestamptz,boolean) from public, anon;
grant execute on function public.admin_save_hole_score(uuid,uuid,integer,integer,integer,integer,text,timestamptz,boolean) to authenticated;
