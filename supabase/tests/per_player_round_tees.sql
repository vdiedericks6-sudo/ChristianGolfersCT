-- Run only after the matching migration has been applied to an isolated test
-- project or with explicit authorization to run rollback-only live checks.
-- Uses existing users and a rated two-tee, 18-hole course only as references;
-- all fixture rows, audits and receipts are rolled back.
begin;
do $$
declare
  a uuid; b uuid; outsider uuid; rid uuid := gen_random_uuid(); req uuid := gen_random_uuid();
  course text; tee_a text; tee_b text; previous timestamptz;
  expected_a integer; expected_b integer; rejected boolean; n integer;
begin
  select id into a from public.profiles order by id limit 1;
  select id into b from public.profiles where id<>a order by id limit 1;
  select id into outsider from public.profiles where id not in (a,b) order by id limit 1;
  select t.course_id into course from public.tee_sets t
   where t.selectable and t.course_rating>0 and t.slope_rating between 55 and 155
   and (select count(*) from public.holes h where h.course_id=t.course_id)=18
   and (select count(distinct h.stroke_index) from public.holes h where h.course_id=t.course_id)=18
   group by t.course_id having count(*) >= 2 limit 1;
  if a is null or b is null or outsider is null or course is null then
    raise exception 'Insufficient existing users or verified tees for rollback-only test';
  end if;
  select id into tee_a from public.tee_sets where course_id=course and selectable and course_rating>0 and slope_rating between 55 and 155 order by id limit 1;
  select id into tee_b from public.tee_sets where course_id=course and selectable and course_rating>0 and slope_rating between 55 and 155 and id<>tee_a order by id limit 1;
  insert into public.rounds(id,host_user_id,course_id,tee_set_id,join_code,status)
  values(rid,a,course,tee_a,public.generate_join_code(),'waiting');
  insert into public.round_players(round_id,user_id,role,handicap_index)
  values(rid,a,'host',12),(rid,b,'player',24),(rid,outsider,'player',null);
  perform set_config('request.jwt.claim.sub',a::text,true);
  perform public.set_my_round_tee(rid,tee_a);
  rejected:=false;
  begin update public.round_players set tee_set_id=tee_b where round_id=rid and user_id=b;
    exception when insufficient_privilege then rejected:=true; end;
  if not rejected then raise exception 'Host could change another player tee'; end if;
  perform set_config('request.jwt.claim.sub',b::text,true);
  perform public.set_my_round_tee(rid,tee_b);
  perform set_config('request.jwt.claim.sub',a::text,true);
  update public.rounds set status='active' where id=rid;
  perform public.save_group_hole_score(rid,a,1,4,2,0,0,null,null,null,false,a,req);
  perform public.save_group_hole_score(rid,a,1,4,2,0,0,null,null,null,false,a,req);
  if (select count(*) from public.admin_audit where actor=a and record_id=rid::text||'/'||a::text||'/1') <> 1 then
    raise exception 'Retry did not behave idempotently';
  end if;
  rejected:=false;
  begin perform public.save_group_hole_score(rid,a,1,5,2,0,0,null,null,null,false,a,req);
    exception when invalid_parameter_value then rejected:=true; end;
  if not rejected then raise exception 'Modified idempotency payload was accepted'; end if;
  perform set_config('request.jwt.claim.sub',b::text,true);
  rejected:=false;
  begin perform public.save_group_hole_score(rid,a,1,4,2,0,0,null,null,null,false,a,req);
    exception when insufficient_privilege then rejected:=true; end;
  if not rejected then raise exception 'Wrong-account replay was accepted'; end if;
  perform set_config('request.jwt.claim.sub',a::text,true);
  rejected:=false;
  begin perform public.set_my_round_tee(rid,tee_b); exception when raise_exception then rejected:=true; end;
  if not rejected then raise exception 'Tee changed after score entry'; end if;
  for n in 2..18 loop
    perform public.save_group_hole_score(rid,a,n,4,2,0,0,null,null,null,false,a,gen_random_uuid());
  end loop;
  perform set_config('request.jwt.claim.sub',b::text,true);
  for n in 1..18 loop
    perform public.save_group_hole_score(rid,b,n,4,2,0,0,null,null,null,false,b,gen_random_uuid());
  end loop;
  perform set_config('request.jwt.claim.sub',outsider::text,true);
  for n in 1..18 loop
    perform public.save_group_hole_score(rid,outsider,n,4,2,0,0,null,null,null,false,outsider,gen_random_uuid());
  end loop;
  perform set_config('request.jwt.claim.sub',a::text,true);
  perform public.complete_round(rid);
  select round(12*(slope_rating/113.0)+(course_rating-par))::integer into expected_a from public.tee_sets where course_id=course and id=tee_a;
  select round(24*(slope_rating/113.0)+(course_rating-par))::integer into expected_b from public.tee_sets where course_id=course and id=tee_b;
  if not exists(select 1 from public.round_results where round_id=rid and player_id=a and course_handicap=expected_a and gross_strokes=72 and net_strokes=72-expected_a)
     or not exists(select 1 from public.round_results where round_id=rid and player_id=b and course_handicap=expected_b and gross_strokes=72 and net_strokes=72-expected_b) then
    raise exception 'Per-player tee result calculation mismatch';
  end if;
  if exists(select 1 from public.round_results where round_id=rid and player_id=outsider) then
    raise exception 'Player with missing handicap index was treated as scratch';
  end if;
end $$;
rollback;
