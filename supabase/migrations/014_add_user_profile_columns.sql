-- ============================================================
-- MIGRATION 014: ADD USER PROFILE COLUMNS
-- Adds email and company_id columns to user_profiles
-- ============================================================

-- ============================================================
-- PART 1: ADD NEW COLUMNS
-- ============================================================

-- Add email column (synced from auth.users)
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS email TEXT;

-- Add company_id column for future multi-tenant support
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS company_id UUID;

-- ============================================================
-- PART 2: CREATE INDEX FOR EMAIL LOOKUPS
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_user_profiles_email
ON public.user_profiles(email);

CREATE INDEX IF NOT EXISTS idx_user_profiles_company
ON public.user_profiles(company_id);

-- ============================================================
-- PART 3: UPDATE HANDLE_NEW_USER FUNCTION TO SYNC EMAIL
-- ============================================================

-- Update the trigger function to include email when creating profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, role, full_name, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        'site_manager',
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- PART 4: BACKFILL EMAIL FOR EXISTING USERS
-- ============================================================

-- Sync email from auth.users to user_profiles for existing records
UPDATE public.user_profiles up
SET email = au.email
FROM auth.users au
WHERE up.id = au.id AND up.email IS NULL;

-- ============================================================
-- MIGRATION COMPLETE
-- Run in Supabase SQL Editor
-- ============================================================
