-- ============================================================
-- 003: BLUEPRINTS MODULE SCHEMA & POLICIES
-- ============================================================

-- 1. Create Storage Bucket for Blueprints
--    - Make it public for simplicity of access via URLs
--    - RLS policies on the `storage.objects` table will secure it
INSERT INTO storage.buckets (id, name, public)
VALUES ('blueprints', 'blueprints', true)
ON CONFLICT (id) DO NOTHING;


-- 2. Alter the existing `blueprints` table to match the new schema
--    The table was created in 001_initial_schema.sql with different columns
--    We need to migrate it to the new folder-based structure

DO $$ 
DECLARE
    v_has_file_url BOOLEAN;
    v_has_uploaded_by BOOLEAN;
BEGIN
    -- Check if old columns exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'blueprints' 
        AND column_name = 'file_url'
    ) INTO v_has_file_url;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'blueprints' 
        AND column_name = 'uploaded_by'
    ) INTO v_has_uploaded_by;

    -- Add folder_name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'blueprints' 
                   AND column_name = 'folder_name') THEN
        ALTER TABLE public.blueprints ADD COLUMN folder_name TEXT;
        -- Set a default folder name for existing records
        UPDATE public.blueprints SET folder_name = 'General' WHERE folder_name IS NULL;
        ALTER TABLE public.blueprints ALTER COLUMN folder_name SET NOT NULL;
    END IF;

    -- Add file_name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'blueprints' 
                   AND column_name = 'file_name') THEN
        ALTER TABLE public.blueprints ADD COLUMN file_name TEXT;
        -- Extract filename from file_url if it exists, otherwise set default
        IF v_has_file_url THEN
            UPDATE public.blueprints 
            SET file_name = COALESCE(
                NULLIF(SPLIT_PART(file_url, '/', -1), ''),
                'unknown_file'
            ) 
            WHERE file_name IS NULL;
        ELSE
            UPDATE public.blueprints SET file_name = 'unknown_file' WHERE file_name IS NULL;
        END IF;
        ALTER TABLE public.blueprints ALTER COLUMN file_name SET NOT NULL;
    END IF;

    -- Add file_path column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'blueprints' 
                   AND column_name = 'file_path') THEN
        ALTER TABLE public.blueprints ADD COLUMN file_path TEXT;
        -- Generate file_path from project_id and folder_name/file_name
        UPDATE public.blueprints 
        SET file_path = project_id::text || '/' || COALESCE(folder_name, 'General') || '/' || file_name
        WHERE file_path IS NULL;
        ALTER TABLE public.blueprints ALTER COLUMN file_path SET NOT NULL;
        -- Add unique constraint if it doesn't exist
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'blueprints_file_path_unique') THEN
            CREATE UNIQUE INDEX blueprints_file_path_unique ON public.blueprints(file_path);
        END IF;
    END IF;

    -- Add is_admin_only column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'blueprints' 
                   AND column_name = 'is_admin_only') THEN
        ALTER TABLE public.blueprints ADD COLUMN is_admin_only BOOLEAN NOT NULL DEFAULT false;
    END IF;

    -- Handle uploader_id column
    IF v_has_uploaded_by THEN
        -- Rename uploaded_by to uploader_id if uploader_id doesn't exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' 
                       AND table_name = 'blueprints' 
                       AND column_name = 'uploader_id') THEN
            ALTER TABLE public.blueprints RENAME COLUMN uploaded_by TO uploader_id;
        ELSE
            -- Both exist, migrate data and drop old column
            UPDATE public.blueprints SET uploader_id = uploaded_by WHERE uploader_id IS NULL;
            ALTER TABLE public.blueprints DROP COLUMN uploaded_by;
        END IF;
    ELSIF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_schema = 'public' 
                      AND table_name = 'blueprints' 
                      AND column_name = 'uploader_id') THEN
        ALTER TABLE public.blueprints ADD COLUMN uploader_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
    END IF;

    -- Ensure created_at exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'blueprints' 
                   AND column_name = 'created_at') THEN
        ALTER TABLE public.blueprints ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT now();
    END IF;

    -- Drop old columns that are no longer needed (after data migration)
    ALTER TABLE public.blueprints 
        DROP COLUMN IF EXISTS title,
        DROP COLUMN IF EXISTS description,
        DROP COLUMN IF EXISTS file_url,
        DROP COLUMN IF EXISTS file_type,
        DROP COLUMN IF EXISTS file_size,
        DROP COLUMN IF EXISTS version,
        DROP COLUMN IF EXISTS updated_at;
END $$;

-- Update foreign key constraint for project_id if needed
DO $$
BEGIN
    -- Drop existing constraint if it doesn't have CASCADE
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.referential_constraints rc 
        ON tc.constraint_name = rc.constraint_name
        WHERE tc.table_schema = 'public' 
        AND tc.table_name = 'blueprints'
        AND tc.constraint_type = 'FOREIGN KEY'
        AND tc.constraint_name LIKE '%project_id%'
    ) THEN
        -- Check if we need to recreate with CASCADE (simplified - just ensure it exists)
        NULL; -- Constraint exists, leave it
    ELSE
        -- Add foreign key if it doesn't exist
        ALTER TABLE public.blueprints 
        ADD CONSTRAINT blueprints_project_id_fkey 
        FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Add comments to the table and columns
COMMENT ON TABLE public.blueprints IS 'Stores metadata for blueprint files, linking them to projects and folders.';
COMMENT ON COLUMN public.blueprints.folder_name IS 'Logical grouping for files, like a folder.';
COMMENT ON COLUMN public.blueprints.file_path IS 'The full path to the file in the Supabase Storage bucket.';
COMMENT ON COLUMN public.blueprints.is_admin_only IS 'If true, only admins can view this file.';


-- 3. Enable RLS on the new table
ALTER TABLE public.blueprints ENABLE ROW LEVEL SECURITY;

-- 4. Drop existing policy if it exists from previous script
DROP POLICY IF EXISTS "Admins can manage blueprints" ON public.blueprints;


-- 5. RLS Policies for `blueprints` table

-- Policy: Admins can perform all operations
CREATE POLICY "Admins can manage blueprints"
    ON public.blueprints FOR ALL
    USING (public.is_admin_or_super())
    WITH CHECK (public.is_admin_or_super());

-- Policy: Site managers can view non-admin files in their assigned projects
CREATE POLICY "Site managers can view assigned project blueprints"
    ON public.blueprints FOR SELECT
    USING (
      (get_my_role() = 'site_manager') AND
      (is_admin_only = false) AND
      (project_id IN (
        SELECT project_id FROM public.project_assignments WHERE user_id = auth.uid()
      ))
    );
    
-- RLS will implicitly deny access to users who are not admin or site managers.


-- 6. Storage Policies for `blueprints` bucket

-- Function to check if a user is assigned to the project associated with a file path
CREATE OR REPLACE FUNCTION public.is_assigned_to_project_from_path(p_path_name TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_project_id UUID;
  v_user_role TEXT;
BEGIN
  -- Extract project_id from path (e.g., 'project-uuid/folder/file.pdf')
  BEGIN
    v_project_id := SPLIT_PART(p_path_name, '/', 1)::UUID;
  EXCEPTION WHEN others THEN
    -- If casting fails, it's not a valid path for our case
    RETURN FALSE;
  END;
  
  -- Get user's role
  v_user_role := get_my_role();

  IF v_user_role IN ('admin', 'super_admin') THEN
    RETURN TRUE;
  END IF;

  IF v_user_role = 'site_manager' THEN
    -- Check if manager is assigned to this project
    RETURN EXISTS (
      SELECT 1 FROM public.project_assignments
      WHERE project_assignments.project_id = v_project_id AND project_assignments.user_id = auth.uid()
    );
  END IF;

  RETURN FALSE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_assigned_to_project_from_path(TEXT) TO authenticated;

-- Drop existing policies just in case to avoid conflicts
DROP POLICY IF EXISTS "Admins can upload to blueprints" ON storage.objects;
DROP POLICY IF EXISTS "Project members can view blueprint files" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete blueprint files" ON storage.objects;


-- Policy: Admins can upload files
CREATE POLICY "Admins can upload to blueprints"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'blueprints' AND
        public.is_admin_or_super()
    );

-- Policy: Assigned site managers and admins can view files
CREATE POLICY "Project members can view blueprint files"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'blueprints' AND
        public.is_assigned_to_project_from_path(name)
    );

-- Policy: Admins can update/delete files
CREATE POLICY "Admins can delete blueprint files"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'blueprints' AND
        public.is_admin_or_super()
    );

