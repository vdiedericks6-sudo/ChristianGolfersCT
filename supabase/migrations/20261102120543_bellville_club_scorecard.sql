-- Club-published scorecard, accessed 2026-11-02. The published GolfRSA 2023
-- list differs for several ratings, so these are explicitly provisional.
-- Existing pars, stroke indexes, historical tees and rounds are untouched.
do $$
declare
  t record;
  expected_par integer[] := array[4,4,5,3,4,4,3,5,4,4,4,3,4,4,5,3,5,4];
  expected_index integer[] := array[12,10,6,16,14,2,18,4,8,9,1,15,5,17,7,11,3,13];
  src constant text := 'https://bellvillegolf.co.za/course/';
begin
  if (select count(*) from public.holes where course_id = 'bellville-golf-club') <> 18 or exists (
      select 1 from public.holes where course_id = 'bellville-golf-club'
      and (par is distinct from expected_par[number] or stroke_index is distinct from expected_index[number])) then
    raise exception 'Bellville hole data disagrees with club scorecard; manual review required';
  end if;
  for t in select * from (values
    ('white-men-club-provisional','White · Men (rating to verify)','White',71.6,132,5814,array[324,328,431,157,333,380,163,472,304,347,327,155,378,317,423,164,490,321]),
    ('blue-men-club-provisional','Blue · Men (rating to verify)','Blue',68.8,123,5304,array[309,320,428,133,259,343,155,413,236,341,297,151,362,311,353,151,438,304]),
    ('red-men-club-provisional','Red · Men (rating to verify)','Red',66.8,116,4953,array[280,282,388,95,254,337,155,406,234,287,288,142,329,304,336,135,434,267]),
    ('white-women-club-provisional','White · Women (rating to verify)','White',78.3,133,5814,array[324,328,431,157,333,380,163,472,304,347,327,155,378,317,423,164,490,321]),
    ('blue-women-club-provisional','Blue · Women (rating to verify)','Blue',74.8,126,5304,array[309,320,428,133,259,343,155,413,236,341,297,151,362,311,353,151,438,304]),
    ('red-women-club-provisional','Red · Women (rating to verify)','Red',72.0,120,4953,array[280,282,388,95,254,337,155,406,234,287,288,142,329,304,336,135,434,267])
  ) as v(id,name,colour,rating,slope,total,distances)
  loop
    if array_length(t.distances,1) <> 18 or (select sum(n) from unnest(t.distances) as n) <> t.total then
      raise exception 'Distance total mismatch for %', t.id;
    end if;
    insert into public.tee_sets(course_id,id,name,colour,course_rating,slope_rating,par,total_distance,distance_unit)
    values ('bellville-golf-club',t.id,t.name,t.colour,t.rating,t.slope,72,t.total,'metres')
    on conflict (course_id,id) do nothing;
    insert into public.tee_box_hole_distances(course_id,tee_set_id,hole_number,distance_meters,source_url)
    select 'bellville-golf-club',t.id,ord::int,dist,src from unnest(t.distances) with ordinality as d(dist,ord)
    on conflict (course_id,tee_set_id,hole_number) do nothing;
  end loop;
  update public.courses set data_status='scorecard-rating-unverified', source_url=coalesce(source_url,src) where id='bellville-golf-club';
end $$;
