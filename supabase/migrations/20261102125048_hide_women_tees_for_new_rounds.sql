-- Retain women's ratings and distances for existing rounds and later use.
update public.tee_sets
set selectable = false
where id ~* '(^|[-_])(women|female|ladies)([-_]|$)'
   or name ~* '(^|[^[:alpha:]])(women|female|ladies)([^[:alpha:]]|$)';

-- New imports of clearly labelled women's tees remain hidden by default.
-- When women's tee support is introduced, review and retire this trigger,
-- then deliberately re-enable the desired ratings.
create or replace function public.hide_new_womens_tees()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.id ~* '(^|[-_])(women|female|ladies)([-_]|$)'
     or new.name ~* '(^|[^[:alpha:]])(women|female|ladies)([^[:alpha:]]|$)' then
    new.selectable := false;
  end if;
  return new;
end $$;
revoke all on function public.hide_new_womens_tees() from public, anon, authenticated;
create trigger hide_new_womens_tees before insert or update of id, name
on public.tee_sets for each row execute function public.hide_new_womens_tees();
