-- Supabase grants EXECUTE to anon and authenticated by default for new
-- functions. SECURITY DEFINER endpoints must opt in to the roles that need
-- them rather than inheriting anonymous access.

-- App RPCs require a signed-in golfer. The allowlist and membership checks
-- inside each function continue to enforce the finer-grained authorization.
revoke all on function public.admin_update_golfer_handicap(uuid, numeric, text, boolean)
  from public, anon;
grant execute on function public.admin_update_golfer_handicap(uuid, numeric, text, boolean)
  to authenticated;

revoke all on function public.create_round(text, text, text, text)
  from public, anon;
grant execute on function public.create_round(text, text, text, text)
  to authenticated;

revoke all on function public.join_round_by_code(text)
  from public, anon;
grant execute on function public.join_round_by_code(text)
  to authenticated;

revoke all on function public.complete_round(uuid)
  from public, anon;
grant execute on function public.complete_round(uuid)
  to authenticated;

revoke all on function public.is_admin()
  from public, anon;
grant execute on function public.is_admin()
  to authenticated;

revoke all on function public.is_round_member(uuid)
  from public, anon;
grant execute on function public.is_round_member(uuid)
  to authenticated;

revoke all on function public.is_round_host(uuid)
  from public, anon;
grant execute on function public.is_round_host(uuid)
  to authenticated;

revoke all on function public.send_friend_request(text)
  from public, anon;
grant execute on function public.send_friend_request(text)
  to authenticated;

revoke all on function public.respond_to_friend_request(uuid, boolean)
  from public, anon;
grant execute on function public.respond_to_friend_request(uuid, boolean)
  to authenticated;

revoke all on function public.my_friendships()
  from public, anon;
grant execute on function public.my_friendships()
  to authenticated;

revoke all on function public.friend_activity(integer)
  from public, anon;
grant execute on function public.friend_activity(integer)
  to authenticated;

revoke all on function public.friends_leaderboard(timestamptz)
  from public, anon;
grant execute on function public.friends_leaderboard(timestamptz)
  to authenticated;

revoke all on function public.my_crew()
  from public, anon;
grant execute on function public.my_crew()
  to authenticated;

-- Internal helper functions are called by triggers, policies, or other
-- SECURITY DEFINER functions and are not direct client RPC endpoints.
revoke all on function public.are_friends(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.generate_join_code()
  from public, anon, authenticated;
revoke all on function public.handle_new_user()
  from public, anon, authenticated;

-- Trigger execution does not require the calling client to have EXECUTE.
alter function public.touch_updated_at() set search_path = public;
revoke all on function public.touch_updated_at()
  from public, anon, authenticated;
