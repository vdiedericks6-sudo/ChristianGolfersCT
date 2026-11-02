-- Arabella Golf Club, HNA 18-hole scorecard retrieved 2026-11-02.
-- HNA's displayed values are corroborated as metres by a second listing.
-- No OSM/imagery/green coordinates are fabricated by this migration.
do $$
declare
  t record;
  source constant text := 'https://www.handicaps.co.za/club-detail?clubid=192';
  pars integer[] := array[4,4,5,4,3,4,3,5,4,4,4,4,5,3,4,4,3,5];
  indexes integer[] := array[13,9,5,7,17,3,15,1,11,2,12,16,4,18,8,14,10,6];
  yellow integer[] := array[336,440,451,400,153,386,181,499,285,353,367,327,489,170,384,322,167,502];
  white integer[] := array[307,397,435,378,147,355,170,476,251,340,352,316,443,130,369,294,159,471];
  blue integer[] := array[280,376,414,369,138,330,151,441,208,324,340,302,421,119,343,267,140,432];
  red integer[] := array[234,354,388,319,129,311,117,435,203,284,307,280,360,99,339,251,136,412];
begin
  if not exists (select 1 from public.courses where id='arabella-country-estate') then raise exception 'Arabella course missing'; end if;
  if exists (select 1 from public.rounds where course_id='arabella-country-estate') or exists (select 1 from public.holes where course_id='arabella-country-estate') or exists (select 1 from public.tee_sets where course_id='arabella-country-estate') then
    raise exception 'Arabella already has rounds, holes or tees: review before applying';
  end if;
  if (select sum(x) from unnest(pars) x) <> 72 or (select count(distinct x) from unnest(indexes) x) <> 18 then raise exception 'Invalid hole data'; end if;
  insert into public.holes(course_id,number,par,stroke_index)
  select 'arabella-country-estate', n, pars[n], indexes[n] from generate_series(1,18) n;
  for t in select * from (values
    ('yellow-men-hna-20261102','Yellow · Men','Yellow',72.9,126,6212,yellow),
    ('white-men-hna-20261102','White · Men','White',70.7,120,5790,white),
    ('blue-men-hna-20261102','Blue · Men','Blue',69.2,114,5395,blue),
    ('red-men-hna-20261102','Red · Men','Red',66.6,108,4958,red),
    ('yellow-women-hna-20261102','Yellow · Women','Yellow',79.8,146,6212,yellow),
    ('white-women-hna-20261102','White · Women','White',77.0,139,5790,white),
    ('blue-women-hna-20261102','Blue · Women','Blue',74.6,132,5395,blue),
    ('red-women-hna-20261102','Red · Women','Red',72.2,124,4958,red)
  ) as v(id,name,colour,rating,slope,total,distances)
  loop
    if array_length(t.distances,1) <> 18 or (select sum(x) from unnest(t.distances) x) <> t.total then raise exception 'Invalid tee distances for %',t.id; end if;
    insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit)
    values ('arabella-country-estate',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
    insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url)
    select 'arabella-country-estate',t.id,n,t.distances[n],source from generate_series(1,18) n;
  end loop;
  update public.courses set holes=18,par=72,playable=true,data_status='hna-scorecard',city=coalesce(city,'Kleinmond'),phone=coalesce(nullif(phone,''),'+27 28 284 0105') where id='arabella-country-estate';
end $$;
