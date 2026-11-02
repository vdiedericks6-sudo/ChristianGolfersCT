-- Bind access management to the existing owner's verified Auth identity once.
alter table public.admin_allowlist
  add column manages_access boolean not null default false;

update public.admin_allowlist a
set manages_access = true
from auth.users u
where u.id = a.user_id and lower(u.email) = 'vdiedericks6@gmail.com'
  and u.email_confirmed_at is not null;

create function public.portal_admin_access_directory() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.admin_allowlist where user_id = auth.uid() and manages_access) then
    return null;
  end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
    'id', u.id, 'email', u.email, 'name', p.display_name,
    'admin', a.user_id is not null, 'owner', coalesce(a.manages_access,false)
  ) order by lower(u.email))
  from auth.users u
  left join public.profiles p on p.id = u.id
  left join public.admin_allowlist a on a.user_id = u.id
  where a.user_id is not null or (p.id is not null and u.email_confirmed_at is not null
    and u.deleted_at is null and not coalesce(u.is_anonymous,false))), '[]'::jsonb);
end;
$$;

create function public.portal_set_admin_access(p_member_id uuid,p_grant boolean,p_reason text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  account_email text;
  protected_owner boolean;
begin
  if not exists (select 1 from public.admin_allowlist where user_id=auth.uid() and manages_access) then
    raise exception 'Only the league owner can manage administrators' using errcode='42501';
  end if;
  if p_member_id is null or p_grant is null or length(trim(coalesce(p_reason,''))) not between 3 and 500 then
    raise exception 'Select a member and give a reason (3–500 characters)';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_member_id::text,1));
  select manages_access into protected_owner from public.admin_allowlist where user_id=p_member_id;
  if protected_owner then raise exception 'The owner account is protected'; end if;
  if found = p_grant then return; end if;
  if p_grant then
    select u.email into account_email from auth.users u join public.profiles p on p.id=u.id
    where u.id=p_member_id and u.email_confirmed_at is not null and u.deleted_at is null
      and not coalesce(u.is_anonymous,false);
    if account_email is null then raise exception 'A registered member with a verified email is required'; end if;
    insert into public.admin_allowlist(user_id,username) values(p_member_id, lower(account_email));
  else
    delete from public.admin_allowlist where user_id=p_member_id and not manages_access;
  end if;
  insert into public.admin_audit(actor,entity,record_id,reason,before_data,after_data)
  values(auth.uid(),'admin_access',p_member_id::text,trim(p_reason),
    jsonb_build_object('admin',not p_grant),jsonb_build_object('admin',p_grant));
end;
$$;
revoke all on function public.portal_admin_access_directory(), public.portal_set_admin_access(uuid,boolean,text) from public,anon;
grant execute on function public.portal_admin_access_directory(), public.portal_set_admin_access(uuid,boolean,text) to authenticated;
