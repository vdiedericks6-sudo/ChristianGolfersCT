-- Royal Cape 18-hole men's HNA card viewed 2026-11-02. No invented GPS points.
do $$
declare t record;
 src constant text := 'https://www.handicaps.co.za/club-detail?clubid=468';
 pars integer[] := array[4,4,4,3,5,4,5,3,4,4,5,4,3,4,3,5,4,4];
 idx integer[] := array[9,15,1,17,7,5,13,11,3,6,10,14,16,2,12,8,4,18];
begin
 if not exists(select 1 from public.courses where id='royal-cape-golf-club') or exists(select 1 from public.rounds where course_id='royal-cape-golf-club') or exists(select 1 from public.holes where course_id='royal-cape-golf-club') or exists(select 1 from public.tee_sets where course_id='royal-cape-golf-club') then raise exception 'Royal Cape requires manual review'; end if;
 if (select sum(x) from unnest(pars) x)<>72 or (select count(distinct x) from unnest(idx) x)<>18 then raise exception 'Invalid card'; end if;
 insert into public.holes(course_id,number,par,stroke_index) select 'royal-cape-golf-club',n,pars[n],idx[n] from generate_series(1,18) n;
 for t in select * from (values
 ('yellow-men-hna-20261102','Yellow · Men','Yellow',72.3,127,6065,array[363,335,450,127,480,345,458,163,380,318,435,314,165,384,148,459,393,348]),
 ('white-men-hna-20261102','White · Men','White',70.5,127,5709,array[349,320,410,114,472,317,437,148,367,309,418,290,152,365,132,434,351,324]),
 ('red-men-hna-20261102','Red · Men','Red',67.9,117,5236,array[314,303,367,105,449,304,413,134,337,274,386,255,126,321,118,420,321,289])
 ) v(id,name,colour,rating,slope,total,distances)
 loop
   if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances) x)<>t.total then raise exception 'Invalid tee %',t.id; end if;
   insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit) values('royal-cape-golf-club',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
   insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url) select 'royal-cape-golf-club',t.id,n,t.distances[n],src from generate_series(1,18) n;
 end loop;
 update public.courses set holes=18,par=72,playable=true,data_status='hna-scorecard' where id='royal-cape-golf-club';
end $$;
