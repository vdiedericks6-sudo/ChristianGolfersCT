-- The organiser supplied the 18-hole yardages, pars, indexes and tee ratings.
-- Yardages are converted per hole to the nearest metre. The supplied ratings
-- differ from later published competition data and require club verification.
do $$
declare
  hole integer;
  tee record;
  pars integer[] := array[4,5,3,4,4,4,3,4,5,4,4,4,3,5,4,4,3,5];
  indexes integer[] := array[7,11,13,3,1,17,5,15,9,12,8,2,10,16,6,4,14,18];
begin
  if exists(select 1 from public.rounds where course_id='kuilsrivier-golf-club') then
    raise exception 'Existing Kuilsrivier rounds require an impact review before changing hole indexes';
  end if;
  for hole in 1..18 loop
    insert into public.holes(course_id,number,par,stroke_index)
    values('kuilsrivier-golf-club',hole,pars[hole],indexes[hole])
    on conflict(course_id,number) do update set par=excluded.par,stroke_index=excluded.stroke_index;
  end loop;
  for tee in select * from (values
    ('yellow-men-provisional','Yellow · Men (rating to verify)','Yellow',70.5,118,5767,array[405,474,170,401,427,335,197,324,489,318,374,405,135,453,383,408,153,459]),
    ('blue-men-provisional','Blue · Men (rating to verify)','Blue',68.4,114,5363,array[392,452,159,384,413,323,175,297,448,306,358,325,103,446,325,386,142,432]),
    ('blue-women-provisional','Blue · Women (rating to verify)','Blue',74.6,123,5363,array[392,452,159,384,413,323,175,297,448,306,358,325,103,446,325,386,142,432]),
    ('red-men-provisional','Red · Men (rating to verify)','Red',64.7,112,4784,array[335,370,151,366,327,279,150,291,372,292,284,317,91,428,317,369,122,372])
  ) as t(id,name,colour,rating,slope,total,yards)
  loop
    if (select sum(round(y * 0.9144)) from unnest(tee.yards) y) <> tee.total then
      raise exception 'Distance sum mismatch for %', tee.id;
    end if;
    insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit)
    values('kuilsrivier-golf-club',tee.id,tee.name,tee.colour,tee.rating,tee.slope,72,tee.total,'metres')
    on conflict(course_id,id) do update set name=excluded.name,colour=excluded.colour,course_rating=excluded.course_rating,
      slope_rating=excluded.slope_rating,par=excluded.par,total_distance=excluded.total_distance,distance_unit=excluded.distance_unit;
    insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url)
    select 'kuilsrivier-golf-club',tee.id,ordinality::integer,round(yard * 0.9144)::integer,null
    from unnest(tee.yards) with ordinality as d(yard,ordinality)
    on conflict(course_id,tee_set_id,hole_number) do update set distance_meters=excluded.distance_meters,source_url=excluded.source_url;
  end loop;
  update public.courses set holes=18,par=72,playable=true,city=coalesce(city,'Kuils River'),
    data_status='scorecard-rating-unverified' where id='kuilsrivier-golf-club';
end $$;
