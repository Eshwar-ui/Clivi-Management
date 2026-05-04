-- ============================================================
-- MIGRATION 019: DYNAMIC DASHBOARD & REAL-TIME
-- Adds triggers for progress calculation and improved stats
-- ============================================================

-- ============================================================
-- PART 1: DYNAMIC PROJECT PROGRESS
-- Calculates progress based on budget vs expenses (Bills)
-- ============================================================

CREATE OR REPLACE FUNCTION public.calculate_project_progress()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_project_id UUID;
    v_total_budget DECIMAL;
    v_total_expenses DECIMAL;
    v_progress INTEGER;
BEGIN
    -- Determine project_id based on operation
    IF TG_OP = 'DELETE' THEN
        v_project_id := OLD.project_id;
    ELSE
        v_project_id := NEW.project_id;
    END IF;

    -- Get project budget
    SELECT budget INTO v_total_budget
    FROM public.projects
    WHERE id = v_project_id;

    -- If no budget set, default to 0 progress or keep manual
    IF v_total_budget IS NULL OR v_total_budget <= 0 THEN
        RETURN NULL;
    END IF;

    -- Calculate total approved expenses
    SELECT COALESCE(SUM(amount), 0) INTO v_total_expenses
    FROM public.bills
    WHERE project_id = v_project_id
    AND status IN ('approved', 'paid')
    AND bill_type = 'expense';

    -- Calculate percentage (capped at 100)
    v_progress := LEAST(FLOOR((v_total_expenses / v_total_budget) * 100), 100);

    -- Update project progress
    UPDATE public.projects
    SET progress = v_progress,
        updated_at = NOW()
    WHERE id = v_project_id;

    RETURN NULL;
END;
$$;

-- Trigger for Bills changes
DROP TRIGGER IF EXISTS trigger_update_project_progress ON public.bills;
CREATE TRIGGER trigger_update_project_progress
AFTER INSERT OR UPDATE OR DELETE ON public.bills
FOR EACH ROW EXECUTE FUNCTION public.calculate_project_progress();

-- ============================================================
-- PART 2: IMPROVED DASHBOARD STATS
-- Adds dynamic growth calculation
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
    v_current_week_logs INTEGER;
    v_last_week_logs INTEGER;
    v_growth_rate DECIMAL;
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

    -- Calculate Growth: Compare operation logs count (This week vs Last week)
    -- This gives a sense of "Activity Growth"
    SELECT COUNT(*) INTO v_current_week_logs
    FROM public.operation_logs
    WHERE created_at >= date_trunc('week', CURRENT_DATE)
    AND (project_id = ANY(COALESCE(accessible_projects, ARRAY[]::UUID[])) OR project_id IS NULL);

    SELECT COUNT(*) INTO v_last_week_logs
    FROM public.operation_logs
    WHERE created_at >= date_trunc('week', CURRENT_DATE - INTERVAL '1 week')
    AND created_at < date_trunc('week', CURRENT_DATE)
    AND (project_id = ANY(COALESCE(accessible_projects, ARRAY[]::UUID[])) OR project_id IS NULL);

    IF v_last_week_logs > 0 THEN
        v_growth_rate := ((v_current_week_logs::DECIMAL - v_last_week_logs::DECIMAL) / v_last_week_logs::DECIMAL) * 100;
    ELSE
        v_growth_rate := 100.0; -- 100% growth if starting from 0
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
        'growth_percentage', ROUND(v_growth_rate, 1),
        'last_updated', NOW()
    ) INTO result;

    RETURN result;
END;
$$;
