create or replace function public.record_admin_handicap_update()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.estimated_handicap_index is distinct from old.estimated_handicap_index
   and new.estimated_handicap_index is not null and auth.uid() is not null
   and new.handicap_verified_by=auth.uid() and new.handicap_verified_at = now()
   and nullif(trim(coalesce(new.handicap_source,'')),'') is not null and public.is_admin() then
   insert into public.handicap_index_updates(player_id,old_index,new_index,recorded_by,source)
   values(new.id,old.estimated_handicap_index,new.estimated_handicap_index,auth.uid(),new.handicap_source);
 end if;
 return new;
end $$;
