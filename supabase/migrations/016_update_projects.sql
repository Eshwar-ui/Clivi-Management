-- ============================================================
-- MIGRATION 016: UPDATE PROJECTS TABLE
-- Adds client_name, project_type, progress, deleted_at columns
-- Implements soft delete and project stats RPC
-- ============================================================

-- ============================================================
-- PART 1: ADD NEW COLUMNS TO PROJECTS TABLE
-- ============================================================

-- Add client_name column
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS client_name TEXT;

-- Add project_type column with enum validation
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS project_type TEXT 
CHECK (project_type IN ('Residential', 'Commercial', 'Infrastructure', 'Industrial'));

-- Add progress column (0-100 percentage)
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS progress INT DEFAULT 0 
CHECK (progress >= 0 AND progress <= 100);

-- Add deleted_at for soft delete
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- ============================================================
-- PART 2: UPDATE RLS POLICIES FOR SOFT DELETE
-- ============================================================

-- Drop existing select policies to recreate with soft delete filter
DROP POLICY IF EXISTS "Admins can view all projects" ON public.projects;
DROP POLICY IF EXISTS "Site managers can view assigned projects" ON public.projects;

-- Recreate admin policy with soft delete filter
CREATE POLICY "Admins can view all projects"
ON public.projects FOR SELECT
TO authenticated
USING (
    deleted_at IS NULL
    AND EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'super_admin')
    )
);

-- Recreate site manager policy with soft delete filter
CREATE POLICY "Site managers can view assigned projects"
ON public.projects FOR SELECT
TO authenticated
USING (
    deleted_at IS NULL
    AND id IN (
        SELECT project_id FROM public.project_assignments
        WHERE user_id = auth.uid()
    )
);

-- ============================================================
-- PART 3: GET PROJECT STATS RPC FUNCTION
-- Returns material, labor, machinery counts for a project
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_project_stats(p_project_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSON;
    material_received INT := 0;
    material_consumed INT := 0;
    labor_count INT := 0;
    machinery_count INT := 0;
    blueprint_count INT := 0;
BEGIN
    -- Count materials (from stock_items)
    SELECT 
        COALESCE(SUM(CASE WHEN entry_type = 'received' THEN quantity ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN entry_type = 'consumed' THEN quantity ELSE 0 END), 0)
    INTO material_received, material_consumed
    FROM public.stock_items
    WHERE project_id = p_project_id;

    -- Count active labor
    SELECT COUNT(*)
    INTO labor_count
    FROM public.labour
    WHERE project_id = p_project_id
    AND status = 'active';

    -- Count blueprints
    SELECT COUNT(*)
    INTO blueprint_count
    FROM public.blueprints
    WHERE project_id = p_project_id;

    -- Build result JSON
    SELECT json_build_object(
        'material_received', material_received,
        'material_consumed', material_consumed,
        'material_remaining', material_received - material_consumed,
        'labor_count', labor_count,
        'machinery_count', machinery_count,
        'blueprint_count', blueprint_count
    ) INTO result;

    RETURN result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_project_stats TO authenticated;

-- ============================================================
-- PART 4: GET PROJECT MATERIAL BREAKDOWN
-- Returns breakdown by material type (Steel, Cement, etc.)
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_project_material_breakdown(p_project_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_agg(material_data)
    INTO result
    FROM (
        SELECT 
            name,
            COALESCE(SUM(CASE WHEN entry_type = 'received' THEN quantity ELSE 0 END), 0) as received,
            COALESCE(SUM(CASE WHEN entry_type = 'consumed' THEN quantity ELSE 0 END), 0) as consumed,
            COALESCE(SUM(CASE WHEN entry_type = 'received' THEN quantity ELSE 0 END), 0) - 
            COALESCE(SUM(CASE WHEN entry_type = 'consumed' THEN quantity ELSE 0 END), 0) as remaining,
            unit
        FROM public.stock_items
        WHERE project_id = p_project_id
        GROUP BY name, unit
        ORDER BY name
    ) as material_data;

    RETURN COALESCE(result, '[]'::JSON);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_project_material_breakdown TO authenticated;

-- ============================================================
-- PART 5: SOFT DELETE FUNCTION
-- Helper function for soft deleting projects
-- ============================================================

CREATE OR REPLACE FUNCTION public.soft_delete_project(p_project_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check if user is admin
    IF NOT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'super_admin')
    ) THEN
        RAISE EXCEPTION 'Only admins can delete projects';
    END IF;

    -- Perform soft delete
    UPDATE public.projects
    SET deleted_at = NOW(), updated_at = NOW()
    WHERE id = p_project_id AND deleted_at IS NULL;

    -- Log the operation
    PERFORM public.log_operation(
        'delete', 'project', p_project_id,
        'Project deleted',
        NULL,
        p_project_id
    );

    RETURN FOUND;
END;
$$;

GRANT EXECUTE ON FUNCTION public.soft_delete_project TO authenticated;

-- ============================================================
-- PART 6: UPDATE PROJECT PROGRESS FUNCTION
-- Updates progress and handles status transitions
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_project_progress(
    p_project_id UUID,
    p_progress INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_status TEXT;
    new_status TEXT;
BEGIN
    -- Get current status
    SELECT status INTO current_status
    FROM public.projects
    WHERE id = p_project_id;

    -- Determine new status based on progress
    new_status := current_status;
    IF p_progress = 100 AND current_status != 'completed' THEN
        new_status := 'completed';
    ELSIF p_progress > 0 AND p_progress < 100 AND current_status = 'planning' THEN
        new_status := 'in_progress';
    END IF;

    -- Update project
    UPDATE public.projects
    SET 
        progress = p_progress,
        status = new_status,
        updated_at = NOW()
    WHERE id = p_project_id;

    RETURN FOUND;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_project_progress TO authenticated;

-- ============================================================
-- PART 7: ADD INDEXES FOR NEW COLUMNS
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_projects_client_name ON public.projects(client_name);
CREATE INDEX IF NOT EXISTS idx_projects_project_type ON public.projects(project_type);
CREATE INDEX IF NOT EXISTS idx_projects_deleted_at ON public.projects(deleted_at);

-- ============================================================
-- MIGRATION COMPLETE
-- Run in Supabase SQL Editor
-- ============================================================
