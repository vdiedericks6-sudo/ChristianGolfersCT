-- Christian Golfers: admin-captured handicap provenance and league thresholds.
-- Run this migration after the base Christian Golfers Supabase migrations.
-- No automatic Handicap Index calculation is introduced by this migration.

alter table public.profiles
  alter column display_name set default 'Christian Golfer';

alter table public.profiles
  add column if not exists is_visiting_golfer boolean not null default false,
  add column if not exists handicap_source text,
  add column if not exists handicap_verified_at timestamptz,
  add column if not exists handicap_verified_by uuid references auth.users (id) on delete set null;

create table if not exists public.league_settings (
  id smallint primary key default 1 check (id = 1),
  league_a_max_handicap numeric(4,1) not null default 12.0
    check (league_a_max_handicap >= -10 and league_a_max_handicap <= 54),
  league_b_max_handicap numeric(4,1) not null default 24.0
    check (league_b_max_handicap >= -10 and league_b_max_handicap <= 54),
  updated_by uuid references auth.users (id) on delete set null,
  updated_at timestamptz not null default now(),
  constraint league_threshold_order check (league_a_max_handicap < league_b_max_handicap)
);

insert into public.league_settings (id, league_a_max_handicap, league_b_max_handicap)
values (1, 12.0, 24.0)
on conflict (id) do nothing;

alter table public.league_settings enable row level security;
grant select, update on public.league_settings to authenticated;

drop policy if exists "league settings readable by signed-in golfers"
  on public.league_settings;
create policy "league settings readable by signed-in golfers"
  on public.league_settings for select to authenticated using (true);

drop policy if exists "admins manage league settings" on public.league_settings;
create policy "admins manage league settings"
  on public.league_settings for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- The admin RLS policy below complements the protected RPC. Column privileges
-- and the RPC prevent ordinary golfers from changing their own handicap.
drop policy if exists "admins update member league data" on public.profiles;
create policy "admins update member league data"
  on public.profiles for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create index if not exists profiles_league_handicap_idx
  on public.profiles (is_visiting_golfer, estimated_handicap_index);

comment on column public.profiles.estimated_handicap_index is
  'Admin-captured existing Handicap Index for now. Do not calculate automatically until the GolfRSA/WHS workflow is approved and implemented.';
comment on column public.profiles.handicap_source is
  'Provenance for the admin-captured Handicap Index, e.g. club record or member-provided card.';
comment on table public.league_settings is
  'Admin-configured boundaries for League A and League B. Members without a recorded handicap are classified as Social unless marked as visiting golfers.';


-- Prevent members from editing their own handicap/visitor classification via a
-- handcrafted API request. Ordinary profile editing is limited to these fields;
-- the SECURITY DEFINER RPC below is the only client-facing handicap write path.
revoke update on public.profiles from public, anon, authenticated;
grant update (display_name, preferred_distance_unit)
  on public.profiles to authenticated;

create or replace function public.admin_update_golfer_handicap(
  p_member_id uuid,
  p_handicap numeric,
  p_source text,
  p_is_visiting_golfer boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'You must be signed in.';
  end if;

  if not public.is_admin() then
    raise exception 'Only an administrator can update member handicap data.';
  end if;

  if p_handicap is not null and (p_handicap < -10 or p_handicap > 54) then
    raise exception 'Handicap Index must be between -10 and 54.';
  end if;

  if p_handicap is not null and nullif(trim(coalesce(p_source, '')), '') is null then
    raise exception 'A source is required for a recorded Handicap Index.';
  end if;

  update public.profiles
     set estimated_handicap_index = p_handicap,
         handicap_source = case when p_handicap is null then null else trim(p_source) end,
         handicap_verified_at = case when p_handicap is null then null else now() end,
         handicap_verified_by = case when p_handicap is null then null else auth.uid() end,
         is_visiting_golfer = coalesce(p_is_visiting_golfer, false),
         updated_at = now()
   where id = p_member_id;

  if not found then
    raise exception 'Member profile not found.';
  end if;
end;
$$;

revoke all on function public.admin_update_golfer_handicap(uuid, numeric, text, boolean) from public;
grant execute on function public.admin_update_golfer_handicap(uuid, numeric, text, boolean) to authenticated;


-- Keep the auth bootstrap fallback aligned with the new product name.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, email, photo_url)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Christian Golfer'
    ),
    coalesce(new.email, ''),
    nullif(coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture'
    ), '')
  )
  on conflict (id) do update
    set email = excluded.email,
        photo_url = coalesce(public.profiles.photo_url, excluded.photo_url);

  return new;
end;
$$;
