-- Allow labour.project_id to be NULL so we can store master labour records
ALTER TABLE public.labour
  ALTER COLUMN project_id DROP NOT NULL;

-- Update site manager policy to allow reading master (project_id IS NULL) and keep project-scoped access
DROP POLICY IF EXISTS "Site managers can manage project labour" ON public.labour;
CREATE POLICY "Site managers can manage project labour"
    ON public.labour FOR ALL
    USING (
      project_id IS NULL OR
      EXISTS (
        SELECT 1 FROM public.project_assignments
        WHERE project_id = labour.project_id AND user_id = auth.uid()
      )
    )
    WITH CHECK (
      project_id IS NULL OR
      EXISTS (
        SELECT 1 FROM public.project_assignments
        WHERE project_id = labour.project_id AND user_id = auth.uid()
      )
    );

-- Keep admin policy as-is (full access), no change needed

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
