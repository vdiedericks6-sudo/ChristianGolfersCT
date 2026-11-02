-- Milnerton 18-hole par-71 layout matches the existing holes exactly.
-- HNA also has par-72 tees; the app has one shared hole layout, so those are
-- deliberately omitted until layout-specific pars are supported.
do $$
declare t record;
  src constant text := 'https://www.handicaps.co.za/club-detail?clubid=464';
  pars integer[] := array[4,4,4,4,3,4,3,5,4,5,3,4,4,3,4,4,5,4];
  idx integer[] := array[7,15,5,3,13,11,17,9,1,12,14,4,8,16,6,10,18,2];
begin
  if (select count(*) from public.holes where course_id='milnerton-golf-club')<>18 or exists(select 1 from public.holes where course_id='milnerton-golf-club' and (par is distinct from pars[number] or stroke_index is distinct from idx[number])) then raise exception 'Milnerton hole data conflicts; review needed'; end if;
  for t in select * from (values
    ('yellow-men-par71-hna-20261102','Yellow · Men · Par 71','Yellow',71.5,120,5796,array[363,306,410,335,180,256,134,475,392,477,170,380,321,175,316,304,429,373]),
    ('white-men-par71-hna-20261102','White · Men · Par 71','White',69.4,115,5444,array[340,280,390,318,150,256,116,435,369,445,160,365,310,155,300,287,413,355]),
    ('red-men-par71-hna-20261102','Red · Men · Par 71','Red',67.1,111,5011,array[312,263,347,289,128,256,109,395,348,411,147,309,300,149,264,267,379,338])
  ) v(id,name,colour,rating,slope,total,distances)
  loop
    if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances) x)<>t.total then raise exception 'Invalid tee distances: %',t.id; end if;
    insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit)
    values('milnerton-golf-club',t.id,t.name,t.colour,t.rating,t.slope,71,t.total,'metres');
    insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url)
    select 'milnerton-golf-club',t.id,n,t.distances[n],src from generate_series(1,18) n;
  end loop;
  update public.tee_sets set selectable=false where course_id='milnerton-golf-club' and id='default';
  update public.courses set data_status='hna-scorecard' where id='milnerton-golf-club';
end $$;
