-- Owner-authorised emails are pending until the account authenticates and
-- Supabase Auth records that its email is confirmed. No client metadata or
-- unverified JWT email is used to grant the role.
create table public.pending_admin_emails (
  email text primary key,
  authorized_by uuid not null references public.profiles(id),
  authorized_at timestamptz not null default now(),
  reason text not null
);
alter table public.pending_admin_emails enable row level security;
revoke all on public.pending_admin_emails from public, anon, authenticated;

create function public.portal_authorize_admin_email(p_email text, p_reason text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_email text := lower(trim(coalesce(p_email,'')));
begin
 if auth.uid() is null or not exists(select 1 from public.admin_allowlist where user_id=auth.uid() and manages_access) then
  raise exception 'Only the owner can manage administrators' using errcode='42501';
 end if;
 if length(v_email)>254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' or length(trim(coalesce(p_reason,''))) not between 3 and 500 then
  raise exception 'Enter a valid email and a reason (3–500 characters)' using errcode='22023';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_email,2));
 if exists(select 1 from auth.users u join public.admin_allowlist a on a.user_id=u.id where lower(u.email)=v_email) then
  raise exception 'This account is already an administrator';
 end if;
 insert into public.pending_admin_emails(email,authorized_by,reason) values(v_email,auth.uid(),trim(p_reason))
 on conflict(email) do update set authorized_by=excluded.authorized_by,authorized_at=now(),reason=excluded.reason;
 insert into public.admin_audit(actor,entity,record_id,reason,after_data)
 values(auth.uid(),'admin_email',v_email,trim(p_reason),jsonb_build_object('status','pending'));
end $$;

create function public.portal_pending_admin_emails()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
 if auth.uid() is null or not exists(select 1 from public.admin_allowlist where user_id=auth.uid() and manages_access) then
  raise exception 'Only the owner can manage administrators' using errcode='42501';
 end if;
 return coalesce((select jsonb_agg(jsonb_build_object('email',email,'authorized_at',authorized_at) order by email) from public.pending_admin_emails),'[]'::jsonb);
end $$;

create function public.portal_cancel_admin_email(p_email text,p_reason text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_email text := lower(trim(coalesce(p_email,'')));
begin
 if auth.uid() is null or not exists(select 1 from public.admin_allowlist where user_id=auth.uid() and manages_access) then
  raise exception 'Only the owner can manage administrators' using errcode='42501';
 end if;
 if length(trim(coalesce(p_reason,''))) not between 3 and 500 then raise exception 'Provide a reason (3–500 characters)'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_email,2));
 delete from public.pending_admin_emails where email=v_email;
 if found then insert into public.admin_audit(actor,entity,record_id,reason,before_data,after_data)
  values(auth.uid(),'admin_email',v_email,trim(p_reason),jsonb_build_object('status','pending'),jsonb_build_object('status','cancelled')); end if;
end $$;

create function public.portal_claim_admin_email()
returns boolean language plpgsql security definer set search_path = '' as $$
declare v_email text; v_pending public.pending_admin_emails;
begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 select lower(trim(u.email)) into v_email from auth.users u join public.profiles p on p.id=u.id
  where u.id=auth.uid() and u.email_confirmed_at is not null and u.deleted_at is null and not coalesce(u.is_anonymous,false);
 if v_email is null then return false; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_email,2));
 delete from public.pending_admin_emails where email=v_email returning * into v_pending;
 if not found then return exists(select 1 from public.admin_allowlist where user_id=auth.uid()); end if;
 insert into public.admin_allowlist(user_id,username) values(auth.uid(),v_email) on conflict(user_id) do nothing;
 insert into public.admin_audit(actor,entity,record_id,reason,after_data)
 values(auth.uid(),'admin_access',auth.uid()::text,'Verified account claimed owner-authorised access',jsonb_build_object('email',v_email,'authorized_by',v_pending.authorized_by,'admin',true));
 return true;
end $$;

revoke all on function public.portal_authorize_admin_email(text,text), public.portal_pending_admin_emails(), public.portal_cancel_admin_email(text,text), public.portal_claim_admin_email() from public,anon;
grant execute on function public.portal_authorize_admin_email(text,text), public.portal_pending_admin_emails(), public.portal_cancel_admin_email(text,text), public.portal_claim_admin_email() to authenticated;
