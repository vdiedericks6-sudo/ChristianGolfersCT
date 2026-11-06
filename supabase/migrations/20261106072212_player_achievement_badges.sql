-- Record prospective, administrator-sourced index changes. Older profile
-- values cannot be reconstructed and are intentionally not backfilled.
create table public.handicap_index_updates (
 id bigint generated always as identity primary key,
 player_id uuid not null references public.profiles(id) on delete cascade,
 old_index numeric(4,1), new_index numeric(4,1) not null,
 recorded_by uuid not null references public.profiles(id),
 source text not null, recorded_at timestamptz not null default now()
);
alter table public.handicap_index_updates enable row level security;
revoke all on public.handicap_index_updates from public,anon,authenticated;
create index handicap_index_updates_player_idx on public.handicap_index_updates(player_id,recorded_at);

create function public.record_admin_handicap_update()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.estimated_handicap_index is distinct from old.estimated_handicap_index
   and new.estimated_handicap_index is not null and auth.uid() is not null
   and new.handicap_verified_by=auth.uid() and new.handicap_verified_at is distinct from old.handicap_verified_at
   and nullif(trim(coalesce(new.handicap_source,'')),'') is not null and public.is_admin() then
   insert into public.handicap_index_updates(player_id,old_index,new_index,recorded_by,source)
   values(new.id,old.estimated_handicap_index,new.estimated_handicap_index,auth.uid(),new.handicap_source);
 end if;
 return new;
end $$;
revoke all on function public.record_admin_handicap_update() from public,anon,authenticated;
create trigger record_admin_handicap_update after update of estimated_handicap_index on public.profiles
for each row execute function public.record_admin_handicap_update();

-- Derive achievements from the signed-in player's confirmed completed cards;
-- no client can insert awards or ask this function for somebody else's data.
create function public.my_achievement_badges()
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_rounds integer; v_birdies integer; v_under integer; v_updates integer; v_improved integer;
begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 with cards as (
  select r.id,r.course_id from public.rounds r
  join public.round_players p on p.round_id=r.id and p.user_id=auth.uid() and p.active
  join public.hole_scores s on s.round_id=r.id and s.player_id=p.user_id and s.confirmed
  where r.status='completed' group by r.id,r.course_id having count(distinct s.hole_number)=18
 )
 select count(*),
  (select count(*) from cards c join public.hole_scores s on s.round_id=c.id and s.player_id=auth.uid() and s.confirmed join public.holes h on h.course_id=c.course_id and h.number=s.hole_number where s.strokes+s.penalty_strokes < h.par),
  (select count(*) from cards c join public.round_results rr on rr.round_id=c.id and rr.player_id=auth.uid() join public.courses course on course.id=c.course_id where course.par is not null and rr.handicap_index is not null and rr.net_strokes < course.par)
 into v_rounds,v_birdies,v_under from cards;
 select count(*),count(*) filter(where old_index is not null and new_index<old_index)
 into v_updates,v_improved from public.handicap_index_updates where player_id=auth.uid();
 return jsonb_build_array(
  jsonb_build_object('id','first_round','title','First Round','description','Complete and confirm your first 18-hole card.','progress',least(v_rounds,1),'target',1,'earned',v_rounds>=1),
  jsonb_build_object('id','five_rounds','title','Faithful Fairways','description','Complete and confirm five 18-hole cards.','progress',least(v_rounds,5),'target',5,'earned',v_rounds>=5),
  jsonb_build_object('id','birdie','title','Birdie Moment','description','Record a birdie or better on a confirmed, completed card.','progress',least(v_birdies,1),'target',1,'earned',v_birdies>=1),
  jsonb_build_object('id','under_handicap','title','Playing Below Handicap','description','Finish a confirmed round with a recorded net score below course par.','progress',least(v_under,1),'target',1,'earned',v_under>=1),
  jsonb_build_object('id','index_updated','title','Handicap Updated','description','Have an administrator record an index update after badges launch.','progress',least(v_updates,1),'target',1,'earned',v_updates>=1),
  jsonb_build_object('id','index_improved','title','Moving Forward','description','Lower your index in a recorded administrator update after badges launch.','progress',least(v_improved,1),'target',1,'earned',v_improved>=1)
 );
end $$;
revoke all on function public.my_achievement_badges() from public,anon;
grant execute on function public.my_achievement_badges() to authenticated;
