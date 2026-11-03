-- Somerset West 18-hole HNA card, observed 2026-11-03.
-- Keep mapped geometry; do not change hole scoring if rounds have begun.
do $$
declare t record;
 src constant text := 'https://www.handicaps.co.za/club-detail?clubid=470';
 pars integer[] := array[4,4,5,5,4,4,3,4,3,4,3,5,4,5,3,4,4,4];
 idx integer[] := array[6,12,14,16,8,2,18,10,4,9,15,1,7,3,17,11,13,5];
begin
 if exists(select 1 from public.rounds where course_id='somerset-west-golf-club') or (select count(*) from public.holes where course_id='somerset-west-golf-club')<>18 or exists(select 1 from public.holes where course_id='somerset-west-golf-club' and par is distinct from pars[number]) then raise exception 'Somerset West historical rounds or holes require review'; end if;
 update public.holes set stroke_index=idx[number] where course_id='somerset-west-golf-club';
 for t in select * from (values
 ('white-men-hna-20261103','White · Men','White',70.6,128,5665,array[336,313,413,419,369,385,143,330,154,307,139,485,327,450,130,302,276,387]),
 ('blue-men-hna-20261103','Blue · Men','Blue',68.3,123,5242,array[324,256,384,404,356,332,135,312,140,285,128,462,296,428,110,295,249,346]),
 ('red-men-hna-20261103','Red · Men','Red',66.0,111,4787,array[305,224,349,372,300,332,108,285,133,277,112,423,252,405,94,253,222,341])
 ) v(id,name,colour,rating,slope,total,distances)
 loop
  if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances)x)<>t.total then raise exception 'Invalid distances %',t.id; end if;
  insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit) values('somerset-west-golf-club',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
  insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url) select 'somerset-west-golf-club',t.id,n,t.distances[n],src from generate_series(1,18)n;
 end loop;
 update public.tee_sets set selectable=false where course_id='somerset-west-golf-club' and id='default';
 update public.courses set data_status='hna-scorecard',par=72 where id='somerset-west-golf-club';
end $$;
