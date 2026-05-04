-- ============================================================
-- FIX: Add missing columns to match Flutter code expectations
-- ============================================================
-- Run this in Supabase SQL Editor after migration 004
-- ============================================================

-- ============================================================
-- 1. Add missing columns to PROJECTS table
-- ============================================================

-- Add budget column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'projects' 
        AND column_name = 'budget'
    ) THEN
        ALTER TABLE public.projects ADD COLUMN budget DECIMAL(15, 2);
        RAISE NOTICE 'Added budget column to projects';
    END IF;
END $$;

-- Add start_date column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'projects' 
        AND column_name = 'start_date'
    ) THEN
        ALTER TABLE public.projects ADD COLUMN start_date DATE;
        RAISE NOTICE 'Added start_date column to projects';
    END IF;
END $$;

-- Add end_date column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'projects' 
        AND column_name = 'end_date'
    ) THEN
        ALTER TABLE public.projects ADD COLUMN end_date DATE;
        RAISE NOTICE 'Added end_date column to projects';
    END IF;
END $$;

-- Add created_by column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'projects' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.projects ADD COLUMN created_by UUID REFERENCES public.user_profiles(id);
        RAISE NOTICE 'Added created_by column to projects';
    END IF;
END $$;

-- Add location column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'projects' 
        AND column_name = 'location'
    ) THEN
        ALTER TABLE public.projects ADD COLUMN location TEXT;
        RAISE NOTICE 'Added location column to projects';
    END IF;
END $$;

-- Make sure status column has correct check constraint
DO $$
BEGIN
    -- First drop the existing constraint if any
    ALTER TABLE public.projects DROP CONSTRAINT IF EXISTS projects_status_check;
    
    -- Add the correct constraint
    ALTER TABLE public.projects ADD CONSTRAINT projects_status_check 
        CHECK (status IN ('planning', 'in_progress', 'on_hold', 'completed', 'cancelled'));
        
    RAISE NOTICE 'Updated status constraint on projects';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not update status constraint: %', SQLERRM;
END $$;

-- ============================================================
-- 2. Add missing columns to PROJECT_ASSIGNMENTS table
-- ============================================================

-- Add assigned_role column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'project_assignments' 
        AND column_name = 'assigned_role'
    ) THEN
        ALTER TABLE public.project_assignments 
            ADD COLUMN assigned_role TEXT DEFAULT 'manager' 
            CHECK (assigned_role IN ('manager', 'member', 'viewer'));
        RAISE NOTICE 'Added assigned_role column to project_assignments';
    END IF;
END $$;

-- Add assigned_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'project_assignments' 
        AND column_name = 'assigned_at'
    ) THEN
        ALTER TABLE public.project_assignments 
            ADD COLUMN assigned_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added assigned_at column to project_assignments';
    END IF;
END $$;

-- Add assigned_by column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'project_assignments' 
        AND column_name = 'assigned_by'
    ) THEN
        ALTER TABLE public.project_assignments 
            ADD COLUMN assigned_by UUID REFERENCES public.user_profiles(id);
        RAISE NOTICE 'Added assigned_by column to project_assignments';
    END IF;
END $$;

-- ============================================================
-- 3. Add missing columns to USER_PROFILES table (if needed)
-- ============================================================

-- Add full_name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles' 
        AND column_name = 'full_name'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN full_name TEXT;
        RAISE NOTICE 'Added full_name column to user_profiles';
    END IF;
END $$;

-- Add phone column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles' 
        AND column_name = 'phone'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN phone TEXT;
        RAISE NOTICE 'Added phone column to user_profiles';
    END IF;
END $$;

-- Add avatar_url column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles' 
        AND column_name = 'avatar_url'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN avatar_url TEXT;
        RAISE NOTICE 'Added avatar_url column to user_profiles';
    END IF;
END $$;

-- Add role column if it doesn't exist (with correct default and check)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles' 
        AND column_name = 'role'
    ) THEN
        ALTER TABLE public.user_profiles 
            ADD COLUMN role TEXT NOT NULL DEFAULT 'site_manager' 
            CHECK (role IN ('super_admin', 'admin', 'site_manager'));
        RAISE NOTICE 'Added role column to user_profiles';
    END IF;
END $$;

-- ============================================================
-- 4. Create PROJECT_ASSIGNMENTS table if it doesn't exist
-- ============================================================

CREATE TABLE IF NOT EXISTS public.project_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    assigned_role TEXT DEFAULT 'manager' CHECK (assigned_role IN ('manager', 'member', 'viewer')),
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    assigned_by UUID REFERENCES public.user_profiles(id),
    UNIQUE(project_id, user_id)
);

-- Enable RLS on project_assignments
ALTER TABLE public.project_assignments ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 5. Create/Update RLS policies for PROJECT_ASSIGNMENTS
-- ============================================================

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view own assignments" ON public.project_assignments;
DROP POLICY IF EXISTS "Admins can view all assignments" ON public.project_assignments;
DROP POLICY IF EXISTS "Admins can manage assignments" ON public.project_assignments;

-- Create new policies
CREATE POLICY "Users can view own assignments"
    ON public.project_assignments FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Admins can view all assignments"
    ON public.project_assignments FOR SELECT
    USING (public.is_admin_or_super());

CREATE POLICY "Admins can manage assignments"
    ON public.project_assignments FOR ALL
    USING (public.is_admin_or_super());

-- ============================================================
-- 6. Update RLS policies for PROJECTS to allow Site Manager view
-- ============================================================

-- Drop and recreate site manager view policy
DROP POLICY IF EXISTS "Site managers can view assigned projects" ON public.projects;

CREATE POLICY "Site managers can view assigned projects"
    ON public.projects FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = projects.id AND user_id = auth.uid()
        )
    );

-- ============================================================
-- 7. Verify column existence (optional - for debugging)
-- ============================================================

-- This will show all columns in the key tables
-- SELECT table_name, column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_schema = 'public' 
-- AND table_name IN ('projects', 'project_assignments', 'user_profiles')
-- ORDER BY table_name, ordinal_position;

-- ============================================================
-- DONE!
-- ============================================================
-- After running this migration:
-- 1. projects table will have: budget, start_date, end_date, location, created_by
-- 2. project_assignments table will have: assigned_role, assigned_at, assigned_by
-- 3. user_profiles table will have: full_name, phone, avatar_url, role
-- ============================================================
