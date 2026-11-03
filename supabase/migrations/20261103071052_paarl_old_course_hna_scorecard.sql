-- HNA PAARL OLD COURSE 1-18 (not Winelands or Boschenmeer), 2026-11-03.
do $$
declare t record;
 src constant text := 'https://www.handicaps.co.za/club-detail?clubid=217';
 pars integer[] := array[4,4,4,3,4,5,3,4,5,5,4,4,4,3,4,4,3,5];
 idx integer[] := array[5,3,7,9,1,17,15,11,13,8,10,2,6,18,4,16,14,12];
begin
 if not exists(select 1 from public.courses where id='paarl-golf-club') or exists(select 1 from public.rounds where course_id='paarl-golf-club') or exists(select 1 from public.holes where course_id='paarl-golf-club') or exists(select 1 from public.tee_sets where course_id='paarl-golf-club') then raise exception 'Paarl requires manual review'; end if;
 if (select sum(x) from unnest(pars) x)<>72 or (select count(distinct x) from unnest(idx) x)<>18 then raise exception 'Invalid Paarl card'; end if;
 insert into public.holes(course_id,number,par,stroke_index) select 'paarl-golf-club',n,pars[n],idx[n] from generate_series(1,18) n;
 for t in select * from (values
  ('yellow-men-old-hna-20261103','Yellow · Men · Old Course 1–18','Yellow',72.4,133,6214,array[369,350,355,190,405,462,163,331,518,474,336,421,350,118,391,349,155,477]),
  ('white-men-old-hna-20261103','White · Men · Old Course 1–18','White',71.3,131,5978,array[356,336,351,170,395,454,155,317,488,458,327,400,350,118,378,316,152,457]),
  ('blue-men-old-hna-20261103','Blue · Men · Old Course 1–18','Blue',69.3,125,5598,array[343,324,328,143,379,394,135,312,456,441,318,378,309,110,356,301,130,441]),
  ('red-men-old-hna-20261103','Red · Men · Old Course 1–18','Red',67.2,114,5131,array[318,295,275,133,317,394,125,293,424,412,275,324,285,92,341,301,125,402])
 ) v(id,name,colour,rating,slope,total,distances)
 loop
  if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances) x)<>t.total then raise exception 'Invalid Paarl tee %',t.id; end if;
  insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit) values('paarl-golf-club',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
  insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url) select 'paarl-golf-club',t.id,n,t.distances[n],src from generate_series(1,18) n;
 end loop;
 update public.courses set name='Paarl Golf Club · Old Course (1–18)',holes=18,par=72,playable=true,data_status='hna-scorecard' where id='paarl-golf-club';
end $$;
