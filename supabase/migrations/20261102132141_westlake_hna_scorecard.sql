-- Westlake men's HNA 18-hole scorecard, reviewed 2026-11-02.
do $$
declare t record;
 src constant text := 'https://www.handicaps.co.za/club-detail?clubid=473';
 pars integer[] := array[4,4,3,5,4,3,5,4,4,4,4,4,5,4,3,5,3,4];
 idx integer[] := array[5,7,17,1,11,15,3,13,9,10,4,12,2,14,18,6,16,8];
begin
 if not exists(select 1 from public.courses where id='westlake-golf-club') or exists(select 1 from public.rounds where course_id='westlake-golf-club') or exists(select 1 from public.holes where course_id='westlake-golf-club') or exists(select 1 from public.tee_sets where course_id='westlake-golf-club') then raise exception 'Westlake requires manual review'; end if;
 if (select sum(x) from unnest(pars) x)<>72 or (select count(distinct x) from unnest(idx) x)<>18 then raise exception 'Invalid Westlake card'; end if;
 insert into public.holes(course_id,number,par,stroke_index) select 'westlake-golf-club',n,pars[n],idx[n] from generate_series(1,18) n;
 for t in select * from (values
 ('yellow-men-hna-20261102','Yellow · Men','Yellow',71.2,123,5867,array[371,371,146,496,295,169,456,291,316,360,355,376,436,325,133,460,161,350]),
 ('white-men-hna-20261102','White · Men','White',69.5,120,5558,array[356,345,136,485,289,146,441,280,304,341,338,354,414,297,125,443,140,324]),
 ('red-men-hna-20261102','Red · Men','Red',66.9,114,5100,array[303,329,120,437,256,130,423,272,293,331,324,338,375,265,102,388,128,286])
 ) v(id,name,colour,rating,slope,total,distances)
 loop
  if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances) x)<>t.total then raise exception 'Invalid tee %',t.id; end if;
  insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit) values('westlake-golf-club',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
  insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url) select 'westlake-golf-club',t.id,n,t.distances[n],src from generate_series(1,18) n;
 end loop;
 update public.courses set holes=18,par=72,playable=true,data_status='hna-scorecard' where id='westlake-golf-club';
end $$;
