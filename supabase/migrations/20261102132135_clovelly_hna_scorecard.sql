-- HNA Find & Play, Clovelly men's 18-hole course, inspected 2026-11-02.
do $$
declare t record; src constant text := 'https://www.handicaps.co.za/club-detail?clubid=456';
pars integer[] := array[4,4,4,4,5,3,4,3,5,5,3,4,4,4,5,3,4,4];
idx integer[] := array[5,11,13,3,9,15,7,17,1,10,16,6,8,18,4,14,2,12];
begin
if not exists(select 1 from public.courses where id='clovelly-country-club') or exists(select 1 from public.rounds where course_id='clovelly-country-club') or exists(select 1 from public.holes where course_id='clovelly-country-club') or exists(select 1 from public.tee_sets where course_id='clovelly-country-club') then raise exception 'Clovelly requires manual review'; end if;
if (select sum(x) from unnest(pars) x)<>72 or (select count(distinct x) from unnest(idx) x)<>18 then raise exception 'Invalid card'; end if;
insert into public.holes(course_id,number,par,stroke_index) select 'clovelly-country-club',n,pars[n],idx[n] from generate_series(1,18) n;
for t in select * from (values
('yellow-men-hna-20261102','Yellow · Men','Yellow',71.0,125,5794,array[357,317,293,341,472,160,349,177,478,451,116,348,327,293,473,172,390,280]),
('white-men-hna-20261102','White · Men','White',69.3,123,5469,array[337,301,274,319,441,144,335,156,461,430,109,333,308,276,461,148,379,257]),
('red-men-hna-20261102','Red · Men','Red',67.1,116,5087,array[308,282,241,305,405,127,305,137,415,420,93,302,293,268,450,133,360,243])
) v(id,name,colour,rating,slope,total,distances) loop
if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances) x)<>t.total then raise exception 'Invalid tee %',t.id; end if;
insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit) values('clovelly-country-club',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url) select 'clovelly-country-club',t.id,n,t.distances[n],src from generate_series(1,18) n;
end loop;
update public.courses set holes=18,par=72,playable=true,data_status='hna-scorecard' where id='clovelly-country-club';
end $$;
