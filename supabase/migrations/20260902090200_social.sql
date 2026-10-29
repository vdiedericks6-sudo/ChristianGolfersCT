-- Christian Golfers: friendships, friend activity, and season standings.

create table if not exists public.friendships (
  requester_id uuid        not null references public.profiles (id) on delete cascade,
  addressee_id uuid        not null references public.profiles (id) on delete cascade,
  status       text        not null default 'pending'
                 check (status in ('pending', 'accepted', 'declined')),
  created_at   timestamptz not null default now(),
  responded_at timestamptz,
  primary key (requester_id, addressee_id),
  constraint friendships_no_self check (requester_id <> addressee_id)
);

create index if not exists friendships_addressee_idx
  on public.friendships (addressee_id, status);

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.are_friends(p_left uuid, p_right uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.friendships f
    where f.status = 'accepted'
      and (
        (f.requester_id = p_left  and f.addressee_id = p_right) or
        (f.requester_id = p_right and f.addressee_id = p_left)
      )
  );
$$;

-- Everyone the caller counts as a golfing crew: their friends plus themselves.
create or replace function public.my_crew()
returns table (golfer_id uuid)
language sql
security definer
stable
set search_path = public
as $$
  select auth.uid()
  union
  select case
           when f.requester_id = auth.uid() then f.addressee_id
           else f.requester_id
         end
  from public.friendships f
  where f.status = 'accepted'
    and (f.requester_id = auth.uid() or f.addressee_id = auth.uid());
$$;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.friendships enable row level security;

drop policy if exists "see own friendships" on public.friendships;
create policy "see own friendships"
  on public.friendships for select to authenticated
  using (requester_id = auth.uid() or addressee_id = auth.uid());

drop policy if exists "send own friend requests" on public.friendships;
create policy "send own friend requests"
  on public.friendships for insert to authenticated
  with check (requester_id = auth.uid());

-- Only the person who received the request can accept or decline it.
drop policy if exists "answer incoming requests" on public.friendships;
create policy "answer incoming requests"
  on public.friendships for update to authenticated
  using (addressee_id = auth.uid())
  with check (addressee_id = auth.uid());

drop policy if exists "either side can unfriend" on public.friendships;
create policy "either side can unfriend"
  on public.friendships for delete to authenticated
  using (requester_id = auth.uid() or addressee_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Friend requests
-- ---------------------------------------------------------------------------

create or replace function public.send_friend_request(p_email text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me     uuid := auth.uid();
  v_target uuid;
  v_email  text := lower(trim(p_email));
  v_existing public.friendships;
begin
  if v_me is null then
    raise exception 'You must be signed in.';
  end if;

  if v_email = '' then
    raise exception 'Enter an email address.';
  end if;

  select id into v_target from public.profiles where lower(email) = v_email;

  if v_target is null then
    raise exception 'No Christian Golfer is using that email address yet.';
  end if;

  if v_target = v_me then
    raise exception 'That is your own account.';
  end if;

  -- They already asked us: treat this as accepting, so two people who both
  -- tap "add" end up friends rather than stuck facing each other.
  select * into v_existing
  from public.friendships
  where requester_id = v_target and addressee_id = v_me;

  if v_existing.requester_id is not null then
    update public.friendships
       set status = 'accepted', responded_at = now()
     where requester_id = v_target and addressee_id = v_me;
    return v_target;
  end if;

  insert into public.friendships (requester_id, addressee_id, status)
  values (v_me, v_target, 'pending')
  on conflict (requester_id, addressee_id) do update
    set status = case
                   when public.friendships.status = 'declined' then 'pending'
                   else public.friendships.status
                 end,
        responded_at = null;

  return v_target;
end;
$$;

create or replace function public.respond_to_friend_request(
  p_requester uuid,
  p_accept    boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then
    raise exception 'You must be signed in.';
  end if;

  update public.friendships
     set status = case when p_accept then 'accepted' else 'declined' end,
         responded_at = now()
   where requester_id = p_requester
     and addressee_id = v_me
     and status = 'pending';

  if not found then
    raise exception 'That friend request is no longer open.';
  end if;
end;
$$;

-- Both sides of the pair, with the caller's perspective already worked out.
create or replace function public.my_friendships()
returns table (
  golfer_id      uuid,
  display_name   text,
  email          text,
  photo_url      text,
  handicap_index numeric,
  status         text,
  direction      text,
  created_at     timestamptz
)
language sql
security definer
stable
set search_path = public
as $$
  select
    p.id,
    p.display_name,
    p.email,
    p.photo_url,
    p.estimated_handicap_index,
    f.status,
    case when f.requester_id = auth.uid() then 'outgoing' else 'incoming' end,
    f.created_at
  from public.friendships f
  join public.profiles p
    on p.id = case
                when f.requester_id = auth.uid() then f.addressee_id
                else f.requester_id
              end
  where (f.requester_id = auth.uid() or f.addressee_id = auth.uid())
    and f.status <> 'declined'
  order by f.status, p.display_name;
$$;

-- ---------------------------------------------------------------------------
-- Friend activity feed
-- ---------------------------------------------------------------------------
--
-- SECURITY DEFINER on purpose: a golfer cannot read their friends' rounds
-- through the rounds table, and should not be able to. This exposes only a
-- summary line per completed round, never the hole-by-hole card.
create or replace function public.friend_activity(p_limit integer default 25)
returns table (
  round_id     uuid,
  golfer_id    uuid,
  display_name text,
  course_name  text,
  played_at    timestamptz,
  holes        integer,
  gross        integer
)
language sql
security definer
stable
set search_path = public
as $$
  select
    r.id,
    p.id,
    p.display_name,
    r.course_name,
    coalesce(r.completed_at, r.started_at, r.created_at),
    count(hs.hole_number)::integer,
    coalesce(sum(hs.strokes + hs.penalty_strokes), 0)::integer
  from public.rounds r
  join public.round_players rp on rp.round_id = r.id
  join public.profiles p       on p.id = rp.user_id
  left join public.hole_scores hs
         on hs.round_id = r.id and hs.player_id = rp.user_id
  where r.status = 'completed'
    and rp.user_id <> auth.uid()
    and public.are_friends(auth.uid(), rp.user_id)
  group by r.id, p.id, p.display_name, r.course_name,
           r.completed_at, r.started_at, r.created_at
  having count(hs.hole_number) > 0
  order by coalesce(r.completed_at, r.started_at, r.created_at) desc
  limit greatest(1, least(coalesce(p_limit, 25), 100));
$$;

-- ---------------------------------------------------------------------------
-- Season standings among the crew
-- ---------------------------------------------------------------------------

create or replace function public.friends_leaderboard(
  p_since timestamptz default (now() - interval '365 days')
)
returns table (
  golfer_id     uuid,
  display_name  text,
  photo_url     text,
  rounds_played integer,
  best_gross    integer,
  average_gross numeric
)
language sql
security definer
stable
set search_path = public
as $$
  with cards as (
    select
      rp.user_id,
      r.id as round_id,
      count(hs.hole_number) as holes,
      sum(hs.strokes + hs.penalty_strokes) as gross
    from public.round_players rp
    join public.my_crew() crew on crew.golfer_id = rp.user_id
    join public.rounds r
      on r.id = rp.round_id
     and r.status = 'completed'
     and coalesce(r.completed_at, r.created_at) >= p_since
    join public.hole_scores hs
      on hs.round_id = r.id and hs.player_id = rp.user_id
    group by rp.user_id, r.id
  )
  select
    c.user_id,
    p.display_name,
    p.photo_url,
    count(*)::integer,
    min(c.gross)::integer,
    round(avg(c.gross), 1)
  from cards c
  join public.profiles p on p.id = c.user_id
  where c.holes >= 18
  group by c.user_id, p.display_name, p.photo_url
  order by avg(c.gross) asc, count(*) desc;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

revoke all on function public.send_friend_request(text) from public;
revoke all on function public.respond_to_friend_request(uuid, boolean) from public;
revoke all on function public.my_friendships() from public;
revoke all on function public.friend_activity(integer) from public;
revoke all on function public.friends_leaderboard(timestamptz) from public;
revoke all on function public.my_crew() from public;

grant execute on function public.send_friend_request(text) to authenticated;
grant execute on function public.respond_to_friend_request(uuid, boolean) to authenticated;
grant execute on function public.my_friendships() to authenticated;
grant execute on function public.friend_activity(integer) to authenticated;
grant execute on function public.friends_leaderboard(timestamptz) to authenticated;
grant execute on function public.my_crew() to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'friendships'
  ) then
    alter publication supabase_realtime add table public.friendships;
  end if;
end;
$$;
