-- ============================================================
-- DEMO 01: PREP USERS FOR DEMO
-- ============================================================
-- Goal:
-- - Ensure admin@gmail.com exists as admin
-- - Mark first two non-admin auth users as site_manager profiles
--
-- If you currently have only admin user, first create 1-2 users in:
-- Supabase Dashboard -> Authentication -> Users
-- then run this script.
-- ============================================================

DO $$
DECLARE
  v_admin_id UUID;
  v_sm1_id UUID;
  v_sm2_id UUID;
  v_sm1_email TEXT;
  v_sm2_email TEXT;
BEGIN
  SELECT id
  INTO v_admin_id
  FROM auth.users
  WHERE lower(email) = lower('admin@gmail.com')
  LIMIT 1;

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'admin@gmail.com not found in auth.users. Create admin first.';
  END IF;

  -- Pick first two non-admin auth users as demo site managers
  SELECT id, email
  INTO v_sm1_id, v_sm1_email
  FROM auth.users
  WHERE id <> v_admin_id
  ORDER BY created_at
  LIMIT 1;

  SELECT id, email
  INTO v_sm2_id, v_sm2_email
  FROM auth.users
  WHERE id <> v_admin_id
    AND id <> COALESCE(v_sm1_id, '00000000-0000-0000-0000-000000000000'::uuid)
  ORDER BY created_at
  LIMIT 1;

  IF v_sm1_id IS NULL THEN
    RAISE EXCEPTION 'No non-admin auth user found. Create at least one site manager auth user first.';
  END IF;

  -- Ensure admin profile
  INSERT INTO public.user_profiles (id, email, role, full_name, phone, created_at, updated_at)
  VALUES (v_admin_id, 'admin@gmail.com', 'admin', 'Demo Admin', '9000000000', NOW(), NOW())
  ON CONFLICT (id)
  DO UPDATE SET
    email = EXCLUDED.email,
    role = 'admin',
    full_name = 'Demo Admin',
    phone = '9000000000',
    updated_at = NOW();

  -- Site manager 1 profile
  INSERT INTO public.user_profiles (id, email, role, full_name, phone, created_at, updated_at)
  VALUES (v_sm1_id, COALESCE(v_sm1_email, 'sm1@example.com'), 'site_manager', 'Ramesh Kumar', '9000000001', NOW(), NOW())
  ON CONFLICT (id)
  DO UPDATE SET
    email = COALESCE(v_sm1_email, public.user_profiles.email),
    role = 'site_manager',
    full_name = 'Ramesh Kumar',
    phone = '9000000001',
    updated_at = NOW();

  -- Site manager 2 profile (optional; if missing, we continue with one manager)
  IF v_sm2_id IS NOT NULL THEN
    INSERT INTO public.user_profiles (id, email, role, full_name, phone, created_at, updated_at)
    VALUES (v_sm2_id, COALESCE(v_sm2_email, 'sm2@example.com'), 'site_manager', 'Suresh Patil', '9000000002', NOW(), NOW())
    ON CONFLICT (id)
    DO UPDATE SET
      email = COALESCE(v_sm2_email, public.user_profiles.email),
      role = 'site_manager',
      full_name = 'Suresh Patil',
      phone = '9000000002',
      updated_at = NOW();
  END IF;

  RAISE NOTICE 'User prep complete. admin=% sm1=% sm2=%', v_admin_id, v_sm1_id, v_sm2_id;
END $$;

-- Verification
SELECT id, email, role, full_name
FROM public.user_profiles
ORDER BY
  CASE role WHEN 'admin' THEN 1 WHEN 'super_admin' THEN 2 ELSE 3 END,
  created_at;
