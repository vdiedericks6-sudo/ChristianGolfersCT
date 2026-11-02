-- Prevent a new account from supplying administrative classifications at signup.
revoke insert on public.profiles from authenticated;
grant insert(id,display_name,email,photo_url,preferred_distance_unit) on public.profiles to authenticated;
create index admin_orders_member_idx on public.admin_orders(member_id);
create index admin_orders_product_idx on public.admin_orders(product_id);
create index admin_tasks_owner_idx on public.admin_tasks(owner_id);
create index admin_audit_actor_idx on public.admin_audit(actor);
