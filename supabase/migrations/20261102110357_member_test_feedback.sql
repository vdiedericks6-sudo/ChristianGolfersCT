create table public.member_test_feedback (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 category text not null check(category in ('scoring','course','gps','sign-in','performance','other')),
 description text not null check(length(trim(description)) between 10 and 2000),
 app_version text not null default '2.0.0+2',
 created_at timestamptz not null default now()
);
alter table public.member_test_feedback enable row level security;
revoke all on public.member_test_feedback from public, anon, authenticated;
grant insert(category,description) on public.member_test_feedback to authenticated;
grant select on public.member_test_feedback to authenticated;
create policy feedback_send on public.member_test_feedback for insert to authenticated
 with check (reporter_id=auth.uid() and exists(select 1 from public.profiles where id=auth.uid()));
create policy feedback_admin_read on public.member_test_feedback for select to authenticated
 using ((select public.is_admin()));
create index member_test_feedback_created_idx on public.member_test_feedback(created_at desc);
