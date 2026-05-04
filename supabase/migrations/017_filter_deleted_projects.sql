-- ============================================================
-- MIGRATION 017: FILTER DELETED PROJECTS
-- Updates dashboard RPCs to ignore soft-deleted projects
-- ============================================================

-- Update get_dashboard_stats to filter deleted projects
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
        SELECT array_agg(id) INTO accessible_projects 
        FROM public.projects 
        WHERE status != 'cancelled' AND deleted_at IS NULL;
    ELSE
        SELECT array_agg(pa.project_id) INTO accessible_projects
        FROM public.project_assignments pa
        JOIN public.projects p ON pa.project_id = p.id
        WHERE pa.user_id = COALESCE(p_user_id, auth.uid()) AND p.deleted_at IS NULL;
    END IF;

    -- Build stats JSON
    SELECT json_build_object(
        'active_projects', (
            SELECT COUNT(*) FROM public.projects 
            WHERE id = ANY(COALESCE(accessible_projects, ARRAY[]::UUID[]))
            AND status = 'in_progress' AND deleted_at IS NULL
        ),
        'total_projects', (
            SELECT COUNT(*) FROM public.projects 
            WHERE id = ANY(COALESCE(accessible_projects, ARRAY[]::UUID[])) AND deleted_at IS NULL
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
            AND deleted_at IS NULL
        ),
        'growth_percentage', 12.5, -- Placeholder: calculate weekly growth
        'last_updated', NOW()
    ) INTO result;

    RETURN result;
END;
$$;

-- Update get_active_projects_summary to filter deleted projects
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
            WHERE p.status = 'in_progress' AND p.deleted_at IS NULL
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
            AND p.status = 'in_progress' AND p.deleted_at IS NULL
            ORDER BY p.updated_at DESC
            LIMIT p_limit
        ) sub;
    END IF;

    RETURN COALESCE(result, '[]'::JSON);
END;
$$;
