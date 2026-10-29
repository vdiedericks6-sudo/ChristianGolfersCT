create table public.privacy_requests (
  id uuid primary key default gen_random_uuid(),
  request_type text not null check (request_type in ('privacy_question', 'account_deletion')),
  requester_email text not null,
  message text not null default '',
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'completed')),
  created_at timestamptz not null default now(),
  closed_at timestamptz,
  processed_by uuid references auth.users (id) on delete set null
);
create index privacy_requests_open_idx on public.privacy_requests (status, created_at);
alter table public.privacy_requests enable row level security;
revoke all on public.privacy_requests from public, anon, authenticated;

create or replace function public.admin_privacy_requests()
returns jsonb
language plpgsql
security definer
stable
set search_path = public, pg_temp
as $$
declare
  v_requests jsonb;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator access required.' using errcode = '42501';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', r.id,
    'request_type', r.request_type,
    'requester_email', r.requester_email,
    'message', r.message,
    'status', r.status,
    'created_at', r.created_at
  ) order by r.created_at), '[]'::jsonb)
  into v_requests
  from public.privacy_requests r
  where r.status <> 'completed';
  return v_requests;
end;
$$;
revoke all on function public.admin_privacy_requests() from public, anon;
grant execute on function public.admin_privacy_requests() to authenticated;

create or replace function public.admin_close_privacy_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator access required.' using errcode = '42501';
  end if;
  update public.privacy_requests
     set status = 'completed',
         requester_email = '[removed]',
         message = '',
         closed_at = now(),
         processed_by = auth.uid()
   where id = p_request_id and status <> 'completed';
  if not found then
    raise exception 'Open privacy request not found.';
  end if;
end;
$$;
revoke all on function public.admin_close_privacy_request(uuid) from public, anon;
grant execute on function public.admin_close_privacy_request(uuid) to authenticated;

comment on table public.privacy_requests is
  'Private inbox for user-initiated privacy and account deletion requests. Writes and reads are restricted to server functions and allowlisted admins; identifying details are removed when a request is closed.';
