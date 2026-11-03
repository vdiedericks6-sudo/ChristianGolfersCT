-- Erinvale HNA main layout, men's 18-hole card, 2026-11-02.
-- Existing mapped geometry is retained. Reject changes if rounds exist.
do $$
declare t record;
 src constant text := 'https://www.handicaps.co.za/club-detail?clubid=460';
 pars integer[] := array[4,3,5,4,4,4,5,3,4,4,4,3,5,3,4,5,4,4];
 idx integer[] := array[3,17,15,7,13,1,9,11,5,6,18,14,10,16,4,8,2,12];
begin
 if exists(select 1 from public.rounds where course_id='erinvale-estate') or (select count(*) from public.holes where course_id='erinvale-estate')<>18 or exists(select 1 from public.holes where course_id='erinvale-estate' and par is distinct from pars[number]) then raise exception 'Erinvale historical rounds or differing holes require review'; end if;
 update public.holes set stroke_index=idx[number] where course_id='erinvale-estate';
 for t in select * from (values
 ('yellow-men-hna-20261102','Yellow · Men','Yellow',74.6,137,6440,array[420,172,461,367,311,439,551,150,396,342,310,162,491,178,335,543,440,372]),
 ('white-men-hna-20261102','White · Men','White',72.2,135,6052,array[413,141,454,340,302,411,487,142,365,334,287,152,469,155,322,509,411,358]),
 ('blue-men-hna-20261102','Blue · Men','Blue',69.8,129,5643,array[365,134,418,315,282,394,455,130,350,328,269,146,464,125,280,505,355,328]),
 ('red-men-hna-20261102','Red · Men','Red',67.4,120,5110,array[333,120,396,285,235,350,410,123,298,284,219,139,423,113,259,463,336,324])
 ) v(id,name,colour,rating,slope,total,distances)
 loop
  if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances)x)<>t.total then raise exception 'Invalid distances for %',t.id; end if;
  insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit) values('erinvale-estate',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
  insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url) select 'erinvale-estate',t.id,n,t.distances[n],src from generate_series(1,18)n;
 end loop;
 update public.tee_sets set selectable=false where course_id='erinvale-estate' and id='default';
 update public.courses set data_status='hna-scorecard',par=72 where id='erinvale-estate';
end $$;
