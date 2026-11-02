-- Durbanville main 18-hole layout; HNA values viewed 2026-11-02.
-- Existing hole geometry and all historical round data are left intact.
do $$
declare t record;
  src constant text := 'https://www.handicaps.co.za/club-detail?clubid=459';
  pars integer[] := array[4,4,4,3,5,5,3,4,4,4,5,3,4,4,5,4,3,4];
  idx integer[] := array[8,16,6,18,10,2,14,12,4,11,1,15,17,3,7,5,13,9];
  white integer[] := array[365,293,385,154,445,455,160,327,350,326,453,172,300,355,470,405,192,350];
  blue integer[] := array[350,277,375,143,433,410,148,311,321,306,414,162,255,330,461,346,164,335];
  red integer[] := array[289,227,339,138,373,401,139,303,307,298,372,111,255,290,431,326,158,285];
begin
  if (select count(*) from public.holes where course_id='durbanville-golf-club') <> 18 or exists(select 1 from public.holes where course_id='durbanville-golf-club' and (par is distinct from pars[number] or stroke_index is distinct from idx[number])) then raise exception 'Durbanville hole data conflicts; review needed'; end if;
  for t in select * from (values
   ('white-men-hna-20261102','White · Men','White',71.7,128,5957,white),
   ('blue-men-hna-20261102','Blue · Men','Blue',69.4,124,5541,blue),
   ('red-men-hna-20261102','Red · Men','Red',66.7,112,5042,red),
   ('white-women-hna-20261102','White · Women','White',78.2,136,5957,white),
   ('blue-women-hna-20261102','Blue · Women','Blue',75.6,129,5541,blue),
   ('red-women-hna-20261102','Red · Women','Red',72.0,123,5042,red)
  ) v(id,name,colour,rating,slope,total,distances)
  loop
    if array_length(t.distances,1) <> 18 or (select sum(x) from unnest(t.distances) x) <> t.total then raise exception 'Invalid distances: %',t.id; end if;
    insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit)
    values ('durbanville-golf-club',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
    insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url)
    select 'durbanville-golf-club',t.id,n,t.distances[n],src from generate_series(1,18) n;
  end loop;
  update public.tee_sets set selectable=false where course_id='durbanville-golf-club' and id='default';
  update public.courses set data_status='hna-scorecard' where id='durbanville-golf-club';
end $$;
