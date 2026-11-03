-- Pearl Valley Golf Club men's 18-hole HNA card, inspected 2026-11-03.
do $$
declare t record;
 src constant text := 'https://www.handicaps.co.za/club-detail?clubid=218';
 pars integer[] := array[4,4,3,5,4,3,4,4,5,4,4,5,3,5,4,4,3,4];
 idx integer[] := array[15,7,13,3,11,17,5,1,9,12,4,14,8,16,18,6,10,2];
begin
 if not exists(select 1 from public.courses where id='pearl-valley-on-val-de-vie-estate') or exists(select 1 from public.rounds where course_id='pearl-valley-on-val-de-vie-estate') or exists(select 1 from public.holes where course_id='pearl-valley-on-val-de-vie-estate') or exists(select 1 from public.tee_sets where course_id='pearl-valley-on-val-de-vie-estate') then raise exception 'Pearl Valley requires manual review'; end if;
 if (select sum(x) from unnest(pars) x)<>72 or (select count(distinct x) from unnest(idx) x)<>18 then raise exception 'Invalid card'; end if;
 insert into public.holes(course_id,number,par,stroke_index) select 'pearl-valley-on-val-de-vie-estate',n,pars[n],idx[n] from generate_series(1,18) n;
 for t in select * from (values
 ('black-men-hna-20261103','Black · Men','Black',75.0,133,6638,array[356,385,180,545,351,185,415,388,535,364,380,525,185,500,320,387,210,427]),
 ('yellow-men-hna-20261103','Yellow · Men','Yellow',72.8,133,6296,array[340,370,160,513,334,161,394,373,504,346,370,498,175,489,302,369,193,405]),
 ('white-men-hna-20261103','White · Men','White',70.3,125,5792,array[295,340,145,462,300,152,372,349,460,310,348,448,160,440,289,344,183,395]),
 ('green-men-hna-20261103','Green · Men','Green',68.6,119,5472,array[291,326,135,429,287,142,355,337,447,283,329,428,115,424,275,330,158,381]),
 ('red-men-hna-20261103','Red · Men','Red',64.2,104,4654,array[244,287,102,360,250,120,293,273,377,250,275,385,95,369,233,285,121,335])
 ) v(id,name,colour,rating,slope,total,distances)
 loop
  if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances) x)<>t.total then raise exception 'Invalid tee %',t.id; end if;
  insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit) values('pearl-valley-on-val-de-vie-estate',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
  insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url) select 'pearl-valley-on-val-de-vie-estate',t.id,n,t.distances[n],src from generate_series(1,18) n;
 end loop;
 update public.courses set holes=18,par=72,playable=true,data_status='hna-scorecard' where id='pearl-valley-on-val-de-vie-estate';
end $$;
