-- ============================================================
-- DEMO 02: RESET APP DATA (KEEP AUTH + USER_PROFILES)
-- ============================================================
-- Purpose:
-- - Remove existing app data so demo seed starts clean.
-- - Keep auth users and public.user_profiles as-is.
-- - Keep storage untouched (manual cleanup if needed).
--
-- Run after DEMO_01_PREP_USERS.sql (or after confirming user profiles).
-- ============================================================

DO $$
DECLARE
  v_admin_id UUID;
  r RECORD;
BEGIN
  -- Safety check: ensure admin profile exists before destructive reset
  SELECT up.id
  INTO v_admin_id
  FROM public.user_profiles up
  WHERE lower(coalesce(up.email, '')) = lower('admin@gmail.com')
  LIMIT 1;

  IF v_admin_id IS NULL THEN
    SELECT up.id
    INTO v_admin_id
    FROM public.user_profiles up
    WHERE up.role IN ('admin', 'super_admin')
    ORDER BY up.created_at
    LIMIT 1;
  END IF;

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Admin profile not found in public.user_profiles. Aborting reset.';
  END IF;

  -- Truncate all public app tables except user_profiles.
  -- Excludes extension-owned objects to avoid managed table issues.
  FOR r IN
    SELECT t.tablename
    FROM pg_tables t
    JOIN pg_class c
      ON c.relname = t.tablename
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
     AND n.nspname = t.schemaname
    LEFT JOIN pg_depend dep
      ON dep.objid = c.oid
     AND dep.deptype = 'e'
    WHERE t.schemaname = 'public'
      AND t.tablename <> 'user_profiles'
      AND dep.objid IS NULL
  LOOP
    EXECUTE format('TRUNCATE TABLE public.%I RESTART IDENTITY CASCADE', r.tablename);
  END LOOP;

  -- Normalize admin role defensively
  UPDATE public.user_profiles
  SET role = 'admin',
      updated_at = NOW()
  WHERE id = v_admin_id;

  RAISE NOTICE 'Reset complete. Kept all users in auth + user_profiles.';
END $$;

-- Quick verification
SELECT 'auth_users' AS section, COUNT(*)::bigint AS total FROM auth.users
UNION ALL
SELECT 'user_profiles', COUNT(*)::bigint FROM public.user_profiles
UNION ALL
SELECT 'projects', COUNT(*)::bigint FROM public.projects
UNION ALL
SELECT 'suppliers', COUNT(*)::bigint FROM public.suppliers
UNION ALL
SELECT 'stock_items', COUNT(*)::bigint FROM public.stock_items
UNION ALL
SELECT 'material_logs', COUNT(*)::bigint FROM public.material_logs
UNION ALL
SELECT 'machinery', COUNT(*)::bigint FROM public.machinery
UNION ALL
SELECT 'machinery_logs', COUNT(*)::bigint FROM public.machinery_logs
UNION ALL
SELECT 'labour', COUNT(*)::bigint FROM public.labour
UNION ALL
SELECT 'labour_attendance', COUNT(*)::bigint FROM public.labour_attendance
UNION ALL
SELECT 'daily_labour_logs', COUNT(*)::bigint FROM public.daily_labour_logs
UNION ALL
SELECT 'bills', COUNT(*)::bigint FROM public.bills
UNION ALL
SELECT 'operation_logs', COUNT(*)::bigint FROM public.operation_logs;
