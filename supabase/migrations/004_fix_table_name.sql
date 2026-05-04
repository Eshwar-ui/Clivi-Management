-- ============================================================
-- FIX: Table name mismatch and RLS recursion
-- ============================================================
-- This migration fixes two issues:
-- 1. Table named 'profiles' should be 'user_profiles'
-- 2. Infinite recursion in RLS policies
-- ============================================================

-- Step 1: Check if 'profiles' table exists and 'user_profiles' doesn't
-- If so, rename it. If 'user_profiles' already exists, just fix RLS.

-- First, let's handle the case where 'profiles' exists but 'user_profiles' doesn't
DO $$
BEGIN
    -- Check if profiles exists and user_profiles doesn't
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles')
       AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_profiles')
    THEN
        -- Rename profiles to user_profiles
        ALTER TABLE public.profiles RENAME TO user_profiles;
        RAISE NOTICE 'Renamed profiles to user_profiles';
    END IF;
END $$;

-- Step 2: If user_profiles still doesn't exist, create it
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'site_manager' CHECK (role IN ('super_admin', 'admin', 'site_manager')),
    full_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Drop ALL existing policies on user_profiles to start fresh
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'user_profiles'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.user_profiles', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- Step 4: Create SECURITY DEFINER functions to avoid recursion
-- These functions bypass RLS when checking user role

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT role FROM public.user_profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_admin_or_super()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles 
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles 
    WHERE id = auth.uid() AND role = 'super_admin'
  );
$$;

-- Step 5: Create NEW RLS POLICIES (no recursion!)

-- SELECT policies
CREATE POLICY "Users can view own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
    ON public.user_profiles FOR SELECT
    USING (public.is_admin_or_super());

-- INSERT policy
CREATE POLICY "Users can insert own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- UPDATE policies
CREATE POLICY "Users can update own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Super admins can update any profile"
    ON public.user_profiles FOR UPDATE
    USING (public.is_super_admin());

-- DELETE policy
CREATE POLICY "Super admins can delete profiles"
    ON public.user_profiles FOR DELETE
    USING (public.is_super_admin());

-- Step 6: Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin_or_super() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;

-- Step 7: Create/update the trigger function for auto-creating user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, role, full_name, created_at)
    VALUES (
        NEW.id,
        'site_manager',
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create/replace the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 8: Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- Step 9: Fix RLS on other tables that reference user_profiles
-- ============================================================

-- Fix projects table policies
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

-- Fix project_assignments table policies
DROP POLICY IF EXISTS "Admins can view all assignments" ON public.project_assignments;
DROP POLICY IF EXISTS "Admins can manage assignments" ON public.project_assignments;

CREATE POLICY "Admins can view all assignments"
    ON public.project_assignments FOR SELECT
    USING (public.is_admin_or_super());

CREATE POLICY "Admins can manage assignments"
    ON public.project_assignments FOR ALL
    USING (public.is_admin_or_super());

-- ============================================================
-- DONE!
-- ============================================================
-- Now run this SQL in your Supabase SQL Editor:
-- Dashboard: https://supabase.com/dashboard/project/YOUR_PROJECT/sql
-- ============================================================
