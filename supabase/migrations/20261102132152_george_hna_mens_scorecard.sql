-- George Golf Club HNA men's 18-hole card accessed 2026-11-02.
-- The previously mapped hole rows contain placeholder indexes and pars;
-- preserve their coordinates. Refuse changes if a round has been created.
do $$
declare t record;
  src constant text := 'https://www.handicaps.co.za/club-detail?clubid=434';
  pars integer[] := array[4,5,4,4,4,3,4,4,4,4,5,4,3,5,3,5,3,4];
  idx integer[] := array[13,9,5,11,3,15,1,17,7,6,10,14,12,16,2,18,8,4];
begin
  perform pg_advisory_xact_lock(hashtextextended('george-golf-club', 0));
  if exists(select 1 from public.rounds where course_id='george-golf-club') or (select count(*) from public.holes where course_id='george-golf-club')<>18 or exists(select 1 from public.holes where course_id='george-golf-club' and (par<>4 or stroke_index<>number)) then raise exception 'George existing course data changed or has rounds; manual review required'; end if;
  if (select sum(x) from unnest(pars) x)<>72 or (select count(distinct x) from unnest(idx) x)<>18 then raise exception 'Invalid pars or indexes'; end if;
  update public.holes set par=pars[number],stroke_index=idx[number] where course_id='george-golf-club';
  for t in select * from (values
   ('yellow-men-hna-20261102','Yellow · Men','Yellow',73.0,130,6166,array[321,530,376,326,338,158,420,308,365,350,497,330,152,455,172,492,185,391]),
   ('white-men-hna-20261102','White · Men','White',71.2,127,5865,array[310,508,365,310,324,140,404,287,344,337,474,312,137,444,155,469,173,372]),
   ('blue-men-hna-20261102','Blue · Men','Blue',69.8,123,5566,array[285,463,339,310,311,133,390,287,317,337,447,299,123,423,140,457,165,340]),
   ('red-men-hna-20261102','Red · Men','Red',67.5,118,5157,array[285,420,318,277,293,126,335,256,317,319,418,299,104,374,140,413,142,321]),
   ('green-men-hna-20261102','Green · Men','Green',63.9,104,4477,array[240,385,273,248,259,112,286,218,237,279,382,242,104,355,120,357,103,277])
  ) v(id,name,colour,rating,slope,total,distances)
  loop
    if array_length(t.distances,1)<>18 or (select sum(x) from unnest(t.distances) x)<>t.total then raise exception 'Invalid distances: %',t.id; end if;
    insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit) values ('george-golf-club',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres');
    insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url) select 'george-golf-club',t.id,n,t.distances[n],src from generate_series(1,18) n;
  end loop;
  update public.tee_sets set selectable=false where course_id='george-golf-club' and id='default';
  update public.courses set holes=18,par=72,playable=true,data_status='hna-scorecard' where id='george-golf-club';
end $$;
