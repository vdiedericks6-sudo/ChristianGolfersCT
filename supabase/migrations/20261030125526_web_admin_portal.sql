alter table public.profiles add column league_override text check(league_override in ('A','B','Social'));
alter table public.profiles add column membership_status text not null default 'active' check(membership_status in ('active','inactive'));
create table public.admin_products (
 id uuid primary key, name text not null check(length(trim(name)) between 1 and 150),
 sku text not null unique, price numeric(12,2) not null check(price>=0),
 stock integer not null check(stock>=0), active boolean not null default true,
 updated_at timestamptz not null default now()
);
create table public.admin_orders (
 id uuid primary key, member_id uuid not null references public.profiles(id),
 product_id uuid not null references public.admin_products(id), quantity integer not null check(quantity between 1 and 1000),
 unit_price numeric(12,2) not null check(unit_price>=0),
 status text not null check(status in ('pending','paid','fulfilled','cancelled')),
 note text not null default '', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.admin_tasks (
 id uuid primary key, title text not null check(length(trim(title)) between 1 and 200),
 owner_id uuid references public.profiles(id), due_date date,
 status text not null check(status in ('todo','doing','done')), note text not null default '', updated_at timestamptz not null default now()
);
create table public.admin_audit (
 id bigint generated always as identity primary key, actor uuid references public.profiles(id),
 entity text not null, record_id text not null, reason text not null,
 before_data jsonb, after_data jsonb, created_at timestamptz not null default now()
);
do $$ declare t text; begin
 foreach t in array array['admin_products','admin_orders','admin_tasks','admin_audit'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from public,anon,authenticated',t);
 execute format('grant select on public.%I to authenticated',t);
 execute format('create policy admin_read on public.%I for select to authenticated using ((select public.is_admin()))',t);
 end loop;
end $$;
create index admin_audit_created_idx on public.admin_audit(created_at desc);

create function public.admin_portal_save(p_kind text,p_record jsonb,p_reason text)
returns void language plpgsql security definer set search_path=public,pg_temp as $$
declare v_id uuid; v_before jsonb; v_after jsonb; v_product public.admin_products; v_previous public.admin_orders;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required' using errcode='42501'; end if;
 if length(trim(coalesce(p_reason,'')))<3 then raise exception 'Record a reason for this change'; end if;
 v_id := (p_record->>'id')::uuid;
 if v_id is null then raise exception 'Record ID required'; end if;
 case p_kind
 when 'member' then
  select to_jsonb(p) into v_before from public.profiles p where id=v_id for update;
  if not found then raise exception 'Member not found'; end if;
  if length(trim(coalesce(p_record->>'display_name','')))<2 then raise exception 'Name required'; end if;
  perform public.admin_update_golfer_handicap(v_id,nullif(p_record->>'handicap','')::numeric,p_record->>'source',coalesce((p_record->>'visiting')::boolean,false));
  update public.profiles set display_name=trim(p_record->>'display_name'),
   league_override=nullif(p_record->>'league',''),membership_status=p_record->>'membership_status' where id=v_id;
  select to_jsonb(p) into v_after from public.profiles p where id=v_id;
 when 'product' then
  select to_jsonb(p) into v_before from public.admin_products p where id=v_id for update;
  insert into public.admin_products(id,name,sku,price,stock,active)
  values(v_id,p_record->>'name',p_record->>'sku',(p_record->>'price')::numeric,(p_record->>'stock')::integer,(p_record->>'active')::boolean)
  on conflict(id) do update set name=excluded.name,sku=excluded.sku,price=excluded.price,stock=excluded.stock,active=excluded.active,updated_at=now();
  select to_jsonb(p) into v_after from public.admin_products p where id=v_id;
 when 'order' then
  perform pg_advisory_xact_lock(hashtextextended(v_id::text,0));
  select * into v_previous from public.admin_orders where id=v_id for update;
  v_before:=case when found then to_jsonb(v_previous) else null end;
  if v_before is null then
   select * into v_product from public.admin_products where id=(p_record->>'product_id')::uuid and active for update;
   if not found then raise exception 'Active product required'; end if;
   if (p_record->>'quantity')::integer<1 or (p_record->>'quantity')::integer>v_product.stock then raise exception 'Insufficient stock or invalid quantity'; end if;
   insert into public.admin_orders(id,member_id,product_id,quantity,unit_price,status,note)
   values(v_id,(p_record->>'member_id')::uuid,v_product.id,(p_record->>'quantity')::integer,v_product.price,'pending',coalesce(p_record->>'note',''));
   update public.admin_products set stock=stock-(p_record->>'quantity')::integer,updated_at=now() where id=v_product.id;
  else
   if v_previous.status='cancelled' and p_record->>'status'<>'cancelled' then raise exception 'Create a new order to reopen a cancellation'; end if;
   if v_previous.status<>'cancelled' and p_record->>'status'='cancelled' then
    update public.admin_products set stock=stock+v_previous.quantity,updated_at=now() where id=v_previous.product_id;
   end if;
   update public.admin_orders set status=p_record->>'status',note=coalesce(p_record->>'note',''),updated_at=now() where id=v_id;
  end if;
  select to_jsonb(p) into v_after from public.admin_orders p where id=v_id;
 when 'task' then
  select to_jsonb(p) into v_before from public.admin_tasks p where id=v_id for update;
  insert into public.admin_tasks(id,title,owner_id,due_date,status,note)
  values(v_id,p_record->>'title',nullif(p_record->>'owner_id','')::uuid,nullif(p_record->>'due_date','')::date,p_record->>'status',coalesce(p_record->>'note',''))
  on conflict(id) do update set title=excluded.title,owner_id=excluded.owner_id,due_date=excluded.due_date,status=excluded.status,note=excluded.note,updated_at=now();
  select to_jsonb(p) into v_after from public.admin_tasks p where id=v_id;
 else raise exception 'Unsupported operation'; end case;
 insert into public.admin_audit(actor,entity,record_id,reason,before_data,after_data)
 values(auth.uid(),p_kind,v_id::text,trim(p_reason),v_before,v_after);
end $$;
revoke all on function public.admin_portal_save(text,jsonb,text) from public,anon;
grant execute on function public.admin_portal_save(text,jsonb,text) to authenticated;

create function public.admin_portal_members() returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',id,'display_name',display_name,'email',email,
 'handicap',estimated_handicap_index,'source',handicap_source,'visiting',is_visiting_golfer,
 'league',league_override,'membership_status',membership_status,'created_at',created_at) order by display_name) from public.profiles),'[]'::jsonb);
end $$;
revoke all on function public.admin_portal_members() from public,anon;
grant execute on function public.admin_portal_members() to authenticated;
