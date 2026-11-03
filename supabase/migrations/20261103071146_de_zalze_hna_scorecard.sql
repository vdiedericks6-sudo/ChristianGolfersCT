-- De Zalze men's 18-hole HNA card, observed 2026-11-03.
do $$
declare t record;
 src constant text := 'https://www.handicaps.co.za/club-detail?clubid=458';
 pars integer[] := array[4,4,3,4,4,5,4,5,3,4,4,3,4,5,4,3,5,4];
 idx integer[] := array[7,1,11,3,13,9,5,15,17,6,4,12,18,14,8,10,2,16];
begin
 if exists(select 1 from public.rounds where course_id='de-zalze-golf-course') or (select count(*) from public.holes where course_id='de-zalze-golf-course')<>18 or exists(select 1 from public.holes where course_id='de-zalze-golf-course' and par is distinct from pars[number]) then raise exception 'De Zalze historical rounds or holes require review'; end if;
 update public.holes set stroke_index=idx[number] where course_id='de-zalze-golf-course';
 for t in select * from (values
 ('yellow-men-hna-20261103','Yellow · Men','Yellow',73.7,138,6326,array[352,409,159,395,338,525,378,476,146,358,383,171,299,508,378,201,542,308]),
 ('white-men-hna-20261103','White · Men','White',71.4,137,5939,array[320,379,145,374,326,509,370,467,127,336,373,153,268,472,355,168,522,275]),
 ('blue-men-hna-20261103','Blue · Men','Blue',68.8,126,5431,array[298,352,112,345,316,484,321,420,107,326,322,118,240,447,329,142,477,275]),
 ('red-men-hna-20261103','Red · Men','Red',66.7,115,4991,array[297,305,100,326,278,448,320,398,84,281,317,98,215,415,293,127,432,257]),
 ('green-men-hna-20261103','Green · Men','Green',64.3,104,4479,array[245,258,93,300,242,409,279,391,78,235,287,93,209,371,233,121,404,231])
 ) v(id,name,colour,rating,slope,total,distances)
 loop
  if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances)x)<>t.total then raise exception 'Invalid distances %',t.id; end if;
  insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit) values('de-zalze-golf-course',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
  insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url) select 'de-zalze-golf-course',t.id,n,t.distances[n],src from generate_series(1,18)n;
 end loop;
 update public.tee_sets set selectable=false where course_id='de-zalze-golf-course' and id='default';
 update public.courses set data_status='hna-scorecard',par=72 where id='de-zalze-golf-course';
end $$;
