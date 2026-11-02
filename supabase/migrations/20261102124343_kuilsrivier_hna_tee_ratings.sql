-- HNA 18-hole categories, viewed 2026-11-02. Existing hole and tee records
-- are preserved; previous provisional tees are hidden only for new rounds.
do $$
declare t record;
  source constant text := 'https://www.handicaps.co.za/club-detail?clubid=209';
  pars integer[] := array[4,5,3,4,4,4,3,4,5,4,4,4,3,5,4,4,3,5];
  indexes integer[] := array[7,11,13,3,1,17,5,15,9,12,8,2,10,16,6,4,14,18];
  yellow integer[] := array[370,433,155,367,390,306,180,296,447,291,342,370,123,414,350,373,140,420];
  blue integer[] := array[358,413,145,351,378,295,160,272,410,280,327,297,94,408,297,353,130,395];
  red integer[] := array[306,338,138,335,299,255,137,266,340,267,260,290,83,391,290,337,112,340];
begin
  if (select count(*) from public.holes where course_id='kuilsrivier-golf-club') <> 18 or exists(select 1 from public.holes where course_id='kuilsrivier-golf-club' and (par is distinct from pars[number] or stroke_index is distinct from indexes[number])) then
    raise exception 'Existing Kuilsrivier holes conflict with HNA';
  end if;
  for t in select * from (values
    ('yellow-men-hna-20261102','Yellow · Men','Yellow',71.3,119,5767,yellow,'yellow-men-provisional'),
    ('blue-men-hna-20261102','Blue · Men','Blue',69.2,113,5363,blue,'blue-men-provisional'),
    ('red-men-hna-20261102','Red · Men','Red',65.2,113,4784,red,'red-men-provisional'),
    ('yellow-women-hna-20261102','Yellow · Women','Yellow',76.9,137,5767,yellow,'yellow-men-provisional'),
    ('blue-women-hna-20261102','Blue · Women','Blue',74.5,128,5363,blue,'blue-women-provisional'),
    ('red-women-hna-20261102','Red · Women','Red',70.7,123,4784,red,'red-men-provisional')
  ) v(id,name,colour,rating,slope,total,distances,old_id)
  loop
    if (select count(*) from public.tee_box_hole_distances d where d.course_id='kuilsrivier-golf-club' and d.tee_set_id=t.old_id) <> 18 or exists(select 1 from public.tee_box_hole_distances d where d.course_id='kuilsrivier-golf-club' and d.tee_set_id=t.old_id and d.distance_meters is distinct from t.distances[d.hole_number]) or (select sum(x) from unnest(t.distances) x) <> t.total then
      raise exception 'Existing tee distances conflict with HNA: %',t.id;
    end if;
    insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit)
    values ('kuilsrivier-golf-club',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
    insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url)
    select 'kuilsrivier-golf-club',t.id,n,t.distances[n],source from generate_series(1,18) n;
  end loop;
  update public.tee_sets set selectable=false where course_id='kuilsrivier-golf-club' and id in ('yellow-men-provisional','blue-men-provisional','blue-women-provisional','red-men-provisional');
  update public.courses set data_status='hna-scorecard' where id='kuilsrivier-golf-club';
end $$;
