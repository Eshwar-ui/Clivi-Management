-- ============================================================
-- MIGRATION 009: FIX RLS FOR ADMIN USER MANAGEMENT
-- Allows admins to create and manage site manager profiles
-- ============================================================

-- ============================================================
-- PART 1: FIX USER_PROFILES RLS FOR ADMIN
-- ============================================================

-- Drop the restrictive insert policy
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;

-- Allow users to insert their own profile (signup) OR admins to insert any profile
CREATE POLICY "Users or admins can insert profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (
        auth.uid() = id  -- User creating their own profile
        OR public.is_admin_or_super()  -- Admin creating profile for another user
    );

-- Also allow admins to update any profile (not just super_admin)
DROP POLICY IF EXISTS "Super admins can update any profile" ON public.user_profiles;

CREATE POLICY "Admins can update any profile"
    ON public.user_profiles FOR UPDATE
    USING (
        auth.uid() = id  -- User updating own profile
        OR public.is_admin_or_super()  -- Admin updating any profile
    );

-- ============================================================
-- PART 2: ADD UPLOADER_ID COLUMN TO BLUEPRINTS
-- ============================================================

-- Add uploader_id column if it doesn't exist
ALTER TABLE public.blueprints 
ADD COLUMN IF NOT EXISTS uploader_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Create index for the new column
CREATE INDEX IF NOT EXISTS idx_blueprints_uploader_id
ON blueprints(uploader_id);

-- ============================================================
-- MIGRATION COMPLETE
-- Run: supabase db push
-- ============================================================
