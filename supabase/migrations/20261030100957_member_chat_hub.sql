create table public.member_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);
alter table public.member_messages enable row level security;
revoke all on public.member_messages from public, anon, authenticated;
grant select, delete on public.member_messages to authenticated;
grant insert (body) on public.member_messages to authenticated;
create policy "members read chat" on public.member_messages for select to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid()));
create policy "members send own messages" on public.member_messages for insert to authenticated
  with check (sender_id = auth.uid() and exists (select 1 from public.profiles where id = auth.uid()));
create policy "authors and admins remove messages" on public.member_messages for delete to authenticated
  using (sender_id = auth.uid() or public.is_admin());
create index member_messages_created_at_idx on public.member_messages(created_at desc);
comment on table public.member_messages is 'CGCT shared member chat. Only authenticated profiles may read/send. Authors and allowlisted admins may delete.';
