-- Worcester men's HNA 18-hole card, checked 2026-11-03.
-- Existing hole indices, geometry and rounds are unchanged.
do $$
declare t record;
 src constant text := 'https://www.handicaps.co.za/club-detail?clubid=232';
 pars integer[] := array[4,4,4,4,5,4,3,5,3,4,4,4,4,3,4,5,3,5];
 idx integer[] := array[13,5,7,1,17,9,11,3,15,8,4,16,2,18,10,6,12,14];
begin
 if (select count(*) from public.holes where course_id='worcester-golf-course')<>18 or exists(select 1 from public.holes where course_id='worcester-golf-course' and (par is distinct from pars[number] or stroke_index is distinct from idx[number])) then raise exception 'Worcester hole data conflicts; review needed'; end if;
 for t in select * from (values
  ('yellow-men-hna-20261103','Yellow · Men','Yellow',72.5,126,6015,array[340,354,331,430,465,320,158,480,135,373,407,283,352,152,376,454,169,436]),
  ('white-men-hna-20261103','White · Men','White',70.0,120,5578,array[326,310,302,381,455,305,125,453,114,345,380,253,340,127,363,439,150,410]),
  ('red-men-hna-20261103','Red · Men','Red',66.8,111,4964,array[267,273,275,374,388,240,102,427,97,320,350,227,314,113,306,387,142,362])
 ) v(id,name,colour,rating,slope,total,distances)
 loop
  if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances) x)<>t.total then raise exception 'Invalid Worcester tee %',t.id; end if;
  insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit) values('worcester-golf-course',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
  insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url) select 'worcester-golf-course',t.id,n,t.distances[n],src from generate_series(1,18) n;
 end loop;
 update public.tee_sets set selectable=false where course_id='worcester-golf-course' and id='default';
 update public.courses set data_status='hna-scorecard' where id='worcester-golf-course';
end $$;
