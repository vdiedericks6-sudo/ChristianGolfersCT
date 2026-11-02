-- Stellenbosch Golf Club's 2024 printed card supplied by the organiser.
-- Separate rating categories share the same physical tee distances.
do $$
declare
  tee record;
  source constant text := 'https://stellenboschgolfclub.com/wp-content/uploads/2025/02/SGC-SCORE-CARD-2024-Print.pdf';
begin
  if (select count(*) from public.holes where course_id='stellenbosch-golf-club') <> 18 then
    raise exception 'Stellenbosch must have 18 hole records before loading tees';
  end if;
  for tee in select * from (values
    ('yellow-men','Yellow · Men','Yellow',73.4,129,6388,array[412,398,368,371,519,433,139,444,148,385,370,478,151,460,185,399,350,378]),
    ('yellow-women','Yellow · Women','Yellow',80.1,141,6388,array[412,398,368,371,519,433,139,444,148,385,370,478,151,460,185,399,350,378]),
    ('white-men','White · Men','White',71.8,124,6036,array[388,340,351,355,503,408,128,443,134,354,352,442,143,453,172,381,327,362]),
    ('white-women','White · Women','White',78.3,136,6036,array[388,340,351,355,503,408,128,443,134,354,352,442,143,453,172,381,327,362]),
    ('blue-men','Blue · Men','Blue',68.8,116,5486,array[378,280,343,294,471,387,111,378,119,332,336,433,133,384,151,324,293,339]),
    ('blue-women','Blue · Women','Blue',74.5,126,5486,array[378,280,343,294,471,387,111,378,119,332,336,433,133,384,151,324,293,339]),
    ('red-men','Red · Men','Red',66.5,112,5082,array[333,277,296,292,430,313,110,377,102,284,301,400,112,379,142,322,292,320]),
    ('red-women','Red · Women','Red',72.6,117,5082,array[333,277,296,292,430,313,110,377,102,284,301,400,112,379,142,322,292,320])
  ) as t(id,name,colour,rating,slope,total,distances)
  loop
    if (select sum(d) from unnest(tee.distances) d) <> tee.total then
      raise exception 'Tee distances do not match scorecard total for %', tee.id;
    end if;
    insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit)
    values('stellenbosch-golf-club',tee.id,tee.name,tee.colour,tee.rating,tee.slope,72,tee.total,'metres')
    on conflict(course_id,id) do update set name=excluded.name,colour=excluded.colour,
      course_rating=excluded.course_rating,slope_rating=excluded.slope_rating,par=excluded.par,
      total_distance=excluded.total_distance,distance_unit=excluded.distance_unit;
    insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url)
    select 'stellenbosch-golf-club',tee.id,ordinality::integer,distance,source
    from unnest(tee.distances) with ordinality as d(distance,ordinality)
    on conflict(course_id,tee_set_id,hole_number) do update set distance_meters=excluded.distance_meters,source_url=excluded.source_url;
  end loop;
end $$;
