-- ============================================================
-- MIGRATION 015: DASHBOARD SCHEMA
-- Creates operation_logs table and RPC functions for dashboard
-- ============================================================

-- ============================================================
-- PART 1: OPERATION LOGS TABLE
-- Tracks all significant operations for activity feeds
-- ============================================================

CREATE TABLE IF NOT EXISTS public.operation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    operation_type TEXT NOT NULL CHECK (operation_type IN ('create', 'update', 'delete', 'upload', 'status_change')),
    entity_type TEXT NOT NULL CHECK (entity_type IN ('project', 'stock', 'labour', 'blueprint', 'machinery', 'attendance', 'report')),
    entity_id UUID,
    title TEXT NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.operation_logs ENABLE ROW LEVEL SECURITY;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_operation_logs_user ON public.operation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_operation_logs_project ON public.operation_logs(project_id);
CREATE INDEX IF NOT EXISTS idx_operation_logs_created ON public.operation_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_operation_logs_entity ON public.operation_logs(entity_type, entity_id);

-- ============================================================
-- PART 2: RLS POLICIES FOR OPERATION LOGS
-- ============================================================

-- Admins can see all operation logs
CREATE POLICY "Admins can view all operation logs"
ON public.operation_logs FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'super_admin')
    )
);

-- Site managers can see logs for their assigned projects
CREATE POLICY "Site managers can view assigned project logs"
ON public.operation_logs FOR SELECT
TO authenticated
USING (
    project_id IN (
        SELECT project_id FROM public.project_assignments
        WHERE user_id = auth.uid()
    )
);

-- Anyone can insert operation logs (for triggers)
CREATE POLICY "Users can create operation logs"
ON public.operation_logs FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

-- ============================================================
-- PART 3: GET DASHBOARD STATS RPC FUNCTION
-- Returns all dashboard metrics in a single call
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_dashboard_stats(p_user_id UUID DEFAULT NULL)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSON;
    user_role TEXT;
    accessible_projects UUID[];
BEGIN
    -- Get user role
    SELECT role INTO user_role
    FROM public.user_profiles
    WHERE id = COALESCE(p_user_id, auth.uid());

    -- Get accessible project IDs based on role
    IF user_role IN ('admin', 'super_admin') THEN
        SELECT array_agg(id) INTO accessible_projects FROM public.projects WHERE status != 'cancelled';
    ELSE
        SELECT array_agg(project_id) INTO accessible_projects
        FROM public.project_assignments
        WHERE user_id = COALESCE(p_user_id, auth.uid());
    END IF;

    -- Build stats JSON
    SELECT json_build_object(
        'active_projects', (
            SELECT COUNT(*) FROM public.projects 
            WHERE id = ANY(COALESCE(accessible_projects, ARRAY[]::UUID[]))
            AND status = 'in_progress'
        ),
        'total_projects', (
            SELECT COUNT(*) FROM public.projects 
            WHERE id = ANY(COALESCE(accessible_projects, ARRAY[]::UUID[]))
        ),
        'total_workers', (
            SELECT COALESCE(COUNT(*), 0) FROM public.labour 
            WHERE project_id = ANY(COALESCE(accessible_projects, ARRAY[]::UUID[]))
            AND status = 'active'
        ),
        'low_stock_items', (
            SELECT COUNT(*) FROM public.stock_items 
            WHERE project_id = ANY(COALESCE(accessible_projects, ARRAY[]::UUID[]))
            AND quantity <= COALESCE(low_stock_threshold, 10)
        ),
        'pending_reports', (
            SELECT COUNT(*) FROM public.daily_reports 
            WHERE project_id = ANY(COALESCE(accessible_projects, ARRAY[]::UUID[]))
            AND status = 'pending'
        ),
        'blueprints_count', (
            SELECT COUNT(*) FROM public.blueprints 
            WHERE project_id = ANY(COALESCE(accessible_projects, ARRAY[]::UUID[]))
        ),
        'growth_percentage', 12.5, -- Placeholder: calculate weekly growth
        'last_updated', NOW()
    ) INTO result;

    RETURN result;
END;
$$;

-- ============================================================
-- PART 4: GET RECENT ACTIVITY RPC FUNCTION
-- Returns recent operation logs for activity feed
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_recent_activity(
    p_limit INT DEFAULT 10,
    p_offset INT DEFAULT 0,
    p_project_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSON;
    user_role TEXT;
BEGIN
    -- Get user role
    SELECT role INTO user_role
    FROM public.user_profiles
    WHERE id = auth.uid();

    -- Return activity based on role
    IF user_role IN ('admin', 'super_admin') THEN
        SELECT json_agg(activity) INTO result
        FROM (
            SELECT json_build_object(
                'id', ol.id,
                'operation_type', ol.operation_type,
                'entity_type', ol.entity_type,
                'title', ol.title,
                'description', ol.description,
                'project_name', p.name,
                'user_name', up.full_name,
                'created_at', ol.created_at
            ) as activity
            FROM public.operation_logs ol
            LEFT JOIN public.projects p ON ol.project_id = p.id
            LEFT JOIN public.user_profiles up ON ol.user_id = up.id
            WHERE (p_project_id IS NULL OR ol.project_id = p_project_id)
            ORDER BY ol.created_at DESC
            LIMIT p_limit OFFSET p_offset
        ) sub;
    ELSE
        -- Site managers see only their assigned projects
        SELECT json_agg(activity) INTO result
        FROM (
            SELECT json_build_object(
                'id', ol.id,
                'operation_type', ol.operation_type,
                'entity_type', ol.entity_type,
                'title', ol.title,
                'description', ol.description,
                'project_name', p.name,
                'user_name', up.full_name,
                'created_at', ol.created_at
            ) as activity
            FROM public.operation_logs ol
            LEFT JOIN public.projects p ON ol.project_id = p.id
            LEFT JOIN public.user_profiles up ON ol.user_id = up.id
            WHERE ol.project_id IN (
                SELECT project_id FROM public.project_assignments
                WHERE user_id = auth.uid()
            )
            AND (p_project_id IS NULL OR ol.project_id = p_project_id)
            ORDER BY ol.created_at DESC
            LIMIT p_limit OFFSET p_offset
        ) sub;
    END IF;

    RETURN COALESCE(result, '[]'::JSON);
END;
$$;

-- ============================================================
-- PART 5: GET ACTIVE PROJECTS SUMMARY RPC
-- Returns top N active projects with progress
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_active_projects_summary(p_limit INT DEFAULT 3)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSON;
    user_role TEXT;
BEGIN
    SELECT role INTO user_role
    FROM public.user_profiles
    WHERE id = auth.uid();

    IF user_role IN ('admin', 'super_admin') THEN
        SELECT json_agg(proj) INTO result
        FROM (
            SELECT json_build_object(
                'id', p.id,
                'name', p.name,
                'project_type', p.project_type,
                'status', p.status,
                'progress', COALESCE(p.progress, 0),
                'start_date', p.start_date,
                'end_date', p.end_date,
                'location', p.location
            ) as proj
            FROM public.projects p
            WHERE p.status = 'in_progress'
            ORDER BY p.updated_at DESC
            LIMIT p_limit
        ) sub;
    ELSE
        SELECT json_agg(proj) INTO result
        FROM (
            SELECT json_build_object(
                'id', p.id,
                'name', p.name,
                'project_type', p.project_type,
                'status', p.status,
                'progress', COALESCE(p.progress, 0),
                'start_date', p.start_date,
                'end_date', p.end_date,
                'location', p.location
            ) as proj
            FROM public.projects p
            JOIN public.project_assignments pa ON p.id = pa.project_id
            WHERE pa.user_id = auth.uid()
            AND p.status = 'in_progress'
            ORDER BY p.updated_at DESC
            LIMIT p_limit
        ) sub;
    END IF;

    RETURN COALESCE(result, '[]'::JSON);
END;
$$;

-- ============================================================
-- PART 6: LOG OPERATION HELPER FUNCTION
-- Convenience function for logging operations
-- ============================================================

CREATE OR REPLACE FUNCTION public.log_operation(
    p_operation_type TEXT,
    p_entity_type TEXT,
    p_entity_id UUID,
    p_title TEXT,
    p_description TEXT DEFAULT NULL,
    p_project_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_log_id UUID;
BEGIN
    INSERT INTO public.operation_logs (
        user_id, project_id, operation_type, entity_type, 
        entity_id, title, description, metadata
    ) VALUES (
        auth.uid(), p_project_id, p_operation_type, p_entity_type,
        p_entity_id, p_title, p_description, p_metadata
    )
    RETURNING id INTO new_log_id;
    
    RETURN new_log_id;
END;
$$;

-- ============================================================
-- PART 7: AUTO-LOGGING TRIGGERS
-- Automatically log significant operations
-- ============================================================

-- Trigger function for projects
CREATE OR REPLACE FUNCTION public.log_project_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM public.log_operation(
            'create', 'project', NEW.id,
            'New project created: ' || NEW.name,
            'Project type: ' || COALESCE(NEW.project_type, 'N/A'),
            NEW.id
        );
    ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        PERFORM public.log_operation(
            'status_change', 'project', NEW.id,
            'Project status changed: ' || NEW.name,
            'Changed from ' || OLD.status || ' to ' || NEW.status,
            NEW.id
        );
    END IF;
    RETURN NEW;
END;
$$;

-- Create trigger for projects (drop if exists first)
DROP TRIGGER IF EXISTS trigger_log_project_changes ON public.projects;
CREATE TRIGGER trigger_log_project_changes
AFTER INSERT OR UPDATE ON public.projects
FOR EACH ROW EXECUTE FUNCTION public.log_project_changes();

-- Trigger function for blueprints
CREATE OR REPLACE FUNCTION public.log_blueprint_upload()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    PERFORM public.log_operation(
        'upload', 'blueprint', NEW.id,
        'Blueprint uploaded: ' || NEW.title,
        'Version: ' || COALESCE(NEW.version, '1.0'),
        NEW.project_id
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_log_blueprint_upload ON public.blueprints;
CREATE TRIGGER trigger_log_blueprint_upload
AFTER INSERT ON public.blueprints
FOR EACH ROW EXECUTE FUNCTION public.log_blueprint_upload();

-- ============================================================
-- GRANT PERMISSIONS
-- ============================================================

GRANT EXECUTE ON FUNCTION public.get_dashboard_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_recent_activity TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_active_projects_summary TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_operation TO authenticated;

-- ============================================================
-- MIGRATION COMPLETE
-- Run in Supabase SQL Editor
-- ============================================================
