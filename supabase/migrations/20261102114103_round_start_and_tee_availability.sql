alter table public.tee_sets add column if not exists selectable boolean not null default true;
update public.tee_sets set selectable = false where course_id = 'stellenbosch-golf-club' and id in ('white-women','yellow-women');

create or replace function public.prevent_unavailable_round_tee() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and new.course_id is not distinct from old.course_id and new.tee_set_id is not distinct from old.tee_set_id then return new; end if;
  if exists (select 1 from public.tee_sets t where t.course_id = new.course_id and t.id = new.tee_set_id and not t.selectable) then
    raise exception 'This tee is no longer available for new rounds.';
  end if;
  return new;
end $$;
drop trigger if exists prevent_unavailable_round_tee on public.rounds;
create trigger prevent_unavailable_round_tee before insert or update of course_id, tee_set_id on public.rounds for each row execute function public.prevent_unavailable_round_tee();

create or replace function public.create_round_with_start(p_course_id text, p_course_name text, p_tee_set_id text, p_tee_set_name text, p_starting_hole integer) returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'You must be signed in.'; end if;
  if p_starting_hole is null or p_starting_hole < 1 or p_starting_hole > 18 or not exists (select 1 from public.holes where course_id = p_course_id and number = p_starting_hole) then
    raise exception 'Choose a valid starting hole for this course.';
  end if;
  v_id := public.create_round(p_course_id, p_course_name, p_tee_set_id, p_tee_set_name);
  update public.rounds set current_hole = p_starting_hole where id = v_id and host_user_id = auth.uid();
  return v_id;
end $$;
revoke all on function public.create_round_with_start(text,text,text,text,integer) from public, anon;
grant execute on function public.create_round_with_start(text,text,text,text,integer) to authenticated;
