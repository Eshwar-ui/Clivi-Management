-- ============================================================
-- MIGRATION 010: STORAGE POLICIES FOR PRIVATE BUCKETS
-- Secure storage access with project-based authorization
-- ============================================================

-- ============================================================
-- PART 1: HELPER FUNCTION TO CHECK PROJECT ASSIGNMENT
-- ============================================================

-- Check if current user is assigned to a project
CREATE OR REPLACE FUNCTION public.is_assigned_to_project(p_project_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.project_assignments pa
    WHERE pa.user_id = auth.uid()
      AND pa.project_id = p_project_id
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_assigned_to_project(uuid) TO authenticated;

-- ============================================================
-- PART 2: FIX uploaded_by DEFAULT (prevents null constraint errors)
-- ============================================================

ALTER TABLE public.blueprints
ALTER COLUMN uploaded_by SET DEFAULT auth.uid();

-- ============================================================
-- PART 3: STORAGE POLICIES FOR BLUEPRINTS BUCKET
-- Path format: <projectId>/<folderName>/<fileName>
-- ============================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "blueprints_read_assigned" ON storage.objects;
DROP POLICY IF EXISTS "blueprints_upload_assigned" ON storage.objects;
DROP POLICY IF EXISTS "blueprints_delete_admin" ON storage.objects;
DROP POLICY IF EXISTS "blueprints_update_admin" ON storage.objects;

-- SELECT (view/download/list) - Assigned users + Admins
CREATE POLICY "blueprints_read_assigned"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'blueprints'
  AND (
    public.is_admin_or_super()
    OR public.is_assigned_to_project(
      (split_part(name, '/', 1))::uuid
    )
  )
);

-- INSERT (upload) - Assigned users + Admins
CREATE POLICY "blueprints_upload_assigned"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'blueprints'
  AND (
    public.is_admin_or_super()
    OR public.is_assigned_to_project(
      (split_part(name, '/', 1))::uuid
    )
  )
);

-- DELETE (remove) - Admin only
CREATE POLICY "blueprints_delete_admin"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'blueprints'
  AND public.is_admin_or_super()
);

-- UPDATE (overwrite) - Admin only
CREATE POLICY "blueprints_update_admin"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'blueprints'
  AND public.is_admin_or_super()
);

-- ============================================================
-- PART 4: STORAGE POLICIES FOR BILLS BUCKET
-- Path format: <projectId>/<billId>/<fileName>
-- ============================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "bills_read_admin_or_assigned" ON storage.objects;
DROP POLICY IF EXISTS "bills_upload_assigned" ON storage.objects;
DROP POLICY IF EXISTS "bills_delete_admin" ON storage.objects;
DROP POLICY IF EXISTS "bills_update_admin" ON storage.objects;

-- SELECT (view/download) - Admin + assigned site manager
CREATE POLICY "bills_read_admin_or_assigned"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'bills'
  AND (
    public.is_admin_or_super()
    OR public.is_assigned_to_project(
      (split_part(name, '/', 1))::uuid
    )
  )
);

-- INSERT (upload) - Assigned users + Admins
CREATE POLICY "bills_upload_assigned"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'bills'
  AND (
    public.is_admin_or_super()
    OR public.is_assigned_to_project(
      (split_part(name, '/', 1))::uuid
    )
  )
);

-- DELETE - Admin only
CREATE POLICY "bills_delete_admin"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'bills'
  AND public.is_admin_or_super()
);

-- UPDATE - Admin only
CREATE POLICY "bills_update_admin"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'bills'
  AND public.is_admin_or_super()
);

-- ============================================================
-- MIGRATION COMPLETE
-- Run: supabase db push
-- ============================================================
