-- ============================================================
-- FIX: RLS INFINITE RECURSION ON USER_PROFILES
-- ============================================================
-- Run this AFTER 001_initial_schema.sql
-- This fixes the infinite recursion issue in RLS policies
-- ============================================================

-- Step 1: Drop the problematic policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Super admins can update any profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Super admins can insert profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Super admins can delete profiles" ON public.user_profiles;

-- Step 2: Create a SECURITY DEFINER function to get user role
-- This function bypasses RLS to check the user's role
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role FROM public.user_profiles WHERE id = auth.uid();
$$;

-- Step 3: Create a function to check if user is admin or super_admin
CREATE OR REPLACE FUNCTION public.is_admin_or_super()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles 
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  );
$$;

-- Step 4: Create a function to check if user is super_admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles 
    WHERE id = auth.uid() AND role = 'super_admin'
  );
$$;

-- ============================================================
-- NEW RLS POLICIES FOR USER_PROFILES (No recursion)
-- ============================================================

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

-- Policy: Admins can view all profiles (uses function to avoid recursion)
CREATE POLICY "Admins can view all profiles"
    ON public.user_profiles FOR SELECT
    USING (public.is_admin_or_super());

-- Policy: Users can insert their own profile (during signup)
CREATE POLICY "Users can insert own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Policy: Super admins can update any profile
CREATE POLICY "Super admins can update any profile"
    ON public.user_profiles FOR UPDATE
    USING (public.is_super_admin());

-- Policy: Super admins can delete profiles
CREATE POLICY "Super admins can delete profiles"
    ON public.user_profiles FOR DELETE
    USING (public.is_super_admin());

-- ============================================================
-- FIX: Update other tables to use the helper functions
-- ============================================================

-- Drop and recreate project policies
DROP POLICY IF EXISTS "Admins can view all projects" ON public.projects;
DROP POLICY IF EXISTS "Admins can create projects" ON public.projects;
DROP POLICY IF EXISTS "Admins can update projects" ON public.projects;
DROP POLICY IF EXISTS "Super admins can delete projects" ON public.projects;

CREATE POLICY "Admins can view all projects"
    ON public.projects FOR SELECT
    USING (public.is_admin_or_super());

CREATE POLICY "Admins can create projects"
    ON public.projects FOR INSERT
    WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Admins can update projects"
    ON public.projects FOR UPDATE
    USING (public.is_admin_or_super());

CREATE POLICY "Super admins can delete projects"
    ON public.projects FOR DELETE
    USING (public.is_super_admin());

-- Drop and recreate project_assignments policies
DROP POLICY IF EXISTS "Admins can view all assignments" ON public.project_assignments;
DROP POLICY IF EXISTS "Admins can manage assignments" ON public.project_assignments;

CREATE POLICY "Admins can view all assignments"
    ON public.project_assignments FOR SELECT
    USING (public.is_admin_or_super());

CREATE POLICY "Admins can manage assignments"
    ON public.project_assignments FOR ALL
    USING (public.is_admin_or_super());

-- Drop and recreate stock policies
DROP POLICY IF EXISTS "Admins can manage stock" ON public.stock_items;

CREATE POLICY "Admins can manage stock"
    ON public.stock_items FOR ALL
    USING (public.is_admin_or_super());

-- Drop and recreate labour policies
DROP POLICY IF EXISTS "Admins can manage labour" ON public.labour;

CREATE POLICY "Admins can manage labour"
    ON public.labour FOR ALL
    USING (public.is_admin_or_super());

-- Drop and recreate machinery policies
DROP POLICY IF EXISTS "Admins can manage machinery" ON public.machinery;

CREATE POLICY "Admins can manage machinery"
    ON public.machinery FOR ALL
    USING (public.is_admin_or_super());

-- Drop and recreate bills policies
DROP POLICY IF EXISTS "Admins can manage bills" ON public.bills;

CREATE POLICY "Admins can manage bills"
    ON public.bills FOR ALL
    USING (public.is_admin_or_super());

-- Drop and recreate blueprints policies
DROP POLICY IF EXISTS "Admins can manage blueprints" ON public.blueprints;

CREATE POLICY "Admins can manage blueprints"
    ON public.blueprints FOR ALL
    USING (public.is_admin_or_super());

-- ============================================================
-- GRANT EXECUTE ON FUNCTIONS
-- ============================================================

GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin_or_super() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;

-- ============================================================
-- DONE!
-- ============================================================
-- Now the RLS policies use SECURITY DEFINER functions
-- which bypass RLS when checking the user's role,
-- preventing infinite recursion.
-- ============================================================
