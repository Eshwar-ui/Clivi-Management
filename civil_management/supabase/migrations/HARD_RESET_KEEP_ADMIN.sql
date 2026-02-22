-- ============================================================
-- HARD RESET: KEEP ONLY admin@gmail.com
-- ============================================================
-- WARNING: DESTRUCTIVE AND IRREVERSIBLE
-- - Deletes all app data from public schema tables (except user_profiles row for admin)
-- - Deletes all files from all storage buckets
-- - Deletes all auth users except admin@gmail.com
--
-- Run in Supabase SQL Editor with privileged role.
-- ============================================================

-- ------------------------------------------------------------
-- 1) PREFLIGHT CHECK (must return exactly one row)
-- ------------------------------------------------------------
select id, email
from auth.users
where lower(email) = lower('admin@gmail.com');

-- ------------------------------------------------------------
-- 2) DESTRUCTIVE RESET
-- ------------------------------------------------------------
do $$
declare
  v_admin_id uuid;
  v_admin_count int;
  r record;
begin
  -- Ensure exactly one admin target exists
  select count(*)
  into v_admin_count
  from auth.users
  where lower(email) = lower('admin@gmail.com');

  if v_admin_count = 0 then
    raise exception 'admin@gmail.com not found in auth.users. Aborting wipe.';
  end if;

  if v_admin_count > 1 then
    raise exception 'Multiple users found for admin@gmail.com (%). Resolve duplicates first. Aborting wipe.', v_admin_count;
  end if;

  -- Fetch admin ID after count validation
  select id
  into v_admin_id
  from auth.users
  where lower(email) = lower('admin@gmail.com')
  limit 1;

  -- Storage cleanup is intentionally skipped.
  -- You will delete storage objects manually from Supabase Storage UI/API.
  raise notice 'Skipping storage deletion by request.';

  -- Truncate every non-extension table in public schema except user_profiles
  -- Dynamic list keeps script resilient to future table additions.
  for r in
    select t.tablename
    from pg_tables t
    join pg_class c
      on c.relname = t.tablename
    join pg_namespace n
      on n.oid = c.relnamespace
     and n.nspname = t.schemaname
    left join pg_depend dep
      on dep.objid = c.oid
     and dep.deptype = 'e' -- extension-owned objects
    where t.schemaname = 'public'
      and t.tablename <> 'user_profiles'
      and dep.objid is null
  loop
    execute format('truncate table public.%I restart identity cascade', r.tablename);
  end loop;

  -- Keep only admin in auth.users
  -- user_profiles rows cascade-delete automatically via FK ON DELETE CASCADE
  delete from auth.users
  where id <> v_admin_id;

  -- Safety cleanup for any orphan/non-admin profiles
  delete from public.user_profiles
  where id <> v_admin_id;

  -- Normalize retained admin profile
  update public.user_profiles
  set role = 'admin'
  where id = v_admin_id;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_profiles'
      and column_name = 'email'
  ) then
    update public.user_profiles
    set email = 'admin@gmail.com'
    where id = v_admin_id;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_profiles'
      and column_name = 'updated_at'
  ) then
    update public.user_profiles
    set updated_at = now()
    where id = v_admin_id;
  end if;
end $$;

-- ------------------------------------------------------------
-- 3) POST-WIPE VERIFICATION
-- ------------------------------------------------------------

-- Expect: 1 row, email = admin@gmail.com
select count(*) as auth_users_count from auth.users;
select id, email from auth.users;

-- Expect: 1 row, role = admin
select id, email, role from public.user_profiles;

-- Expect: user_profiles ~= 1 row, all others ~= 0 rows
select schemaname, relname as table_name, n_live_tup::bigint as approx_rows
from pg_stat_user_tables
where schemaname = 'public'
order by relname;

-- Storage verification (manual cleanup): run after deleting storage files yourself
select bucket_id, count(*) as object_count
from storage.objects
group by bucket_id
order by bucket_id;
