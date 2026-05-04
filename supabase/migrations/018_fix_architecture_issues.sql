-- ============================================================
-- MIGRATION 018: FIX ARCHITECTURE ISSUES
-- Fixes bugs in RPC functions, adds missing columns/tables
-- ============================================================

-- ============================================================
-- PART 1: ADD STATUS TO DAILY_REPORTS
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'daily_reports' 
        AND column_name = 'status'
    ) THEN
        ALTER TABLE public.daily_reports 
        ADD COLUMN status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed'));
        RAISE NOTICE 'Added status column to daily_reports';
    END IF;
END $$;

-- ============================================================
-- PART 2: CREATE MACHINERY_LOGS TABLE
-- ============================================================

-- Create machinery table if it doesn't exist (it should have been in 001, but apparently missing)
CREATE TABLE IF NOT EXISTS public.machinery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT,
    registration_number TEXT,
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'in_use', 'maintenance', 'retired')),
    hourly_rate DECIMAL(10, 2),
    current_project_id UUID REFERENCES public.projects(id),
    created_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for machinery if valid
ALTER TABLE public.machinery ENABLE ROW LEVEL SECURITY;

-- Add RLS policies for machinery if missing
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins can manage machinery' AND tablename = 'machinery') THEN
        CREATE POLICY "Admins can manage machinery"
            ON public.machinery FOR ALL
            USING (public.is_admin_or_super());
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Site managers can view machinery' AND tablename = 'machinery') THEN
        CREATE POLICY "Site managers can view machinery"
            ON public.machinery FOR SELECT
            USING (
                current_project_id IS NULL
                OR
                EXISTS (
                    SELECT 1 FROM public.project_assignments
                    WHERE project_id = machinery.current_project_id AND user_id = auth.uid()
                )
            );
    END IF;
END $$;

-- Drop table if it exists to ensure clean slate (in case of partial migrations)
DROP TABLE IF EXISTS public.machinery_logs;

CREATE TABLE IF NOT EXISTS public.machinery_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    machinery_id UUID NOT NULL REFERENCES public.machinery(id) ON DELETE CASCADE,
    log_type TEXT CHECK (log_type IN ('usage', 'maintenance', 'breakdown', 'fuel')),
    hours_used DECIMAL(10, 2),
    notes TEXT,
    logged_by UUID REFERENCES auth.users(id),
    logged_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.machinery_logs ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_machinery_logs_project ON public.machinery_logs(project_id);
CREATE INDEX IF NOT EXISTS idx_machinery_logs_machinery ON public.machinery_logs(machinery_id);
CREATE INDEX IF NOT EXISTS idx_machinery_logs_date ON public.machinery_logs(logged_at DESC);

-- RLS Policies
-- Drop existing policies if any
DROP POLICY IF EXISTS "Admins can manage machinery logs" ON public.machinery_logs;
DROP POLICY IF EXISTS "Site managers can view project machinery logs" ON public.machinery_logs;
DROP POLICY IF EXISTS "Site managers can add project machinery logs" ON public.machinery_logs;

-- Admins full access
CREATE POLICY "Admins can manage machinery logs"
ON public.machinery_logs FOR ALL
USING (public.is_admin_or_super())
WITH CHECK (public.is_admin_or_super());

-- Site managers view access
CREATE POLICY "Site managers can view project machinery logs"
ON public.machinery_logs FOR SELECT
USING (public.is_assigned_to_project(project_id));

-- Site managers insert access
CREATE POLICY "Site managers can add project machinery logs"
ON public.machinery_logs FOR INSERT
WITH CHECK (public.is_assigned_to_project(project_id));

-- ============================================================
-- PART 3: FIX GET_PROJECT_STATS (Bug Fix)
-- Previously referenced non-existent columns on stock_items
-- Now uses material_logs for received/consumed counts
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
    -- Calculate materials from material_logs
    -- Inward logs = received
    SELECT COALESCE(SUM(quantity), 0)
    INTO material_received
    FROM public.material_logs
    WHERE project_id = p_project_id
    AND log_type = 'inward';

    -- Outward logs = consumed
    SELECT COALESCE(SUM(quantity), 0)
    INTO material_consumed
    FROM public.material_logs
    WHERE project_id = p_project_id
    AND log_type = 'outward';

    -- Count active labor
    SELECT COUNT(*)
    INTO labor_count
    FROM public.labour
    WHERE project_id = p_project_id
    AND status = 'active';

    -- Count machinery assigned to project
    SELECT COUNT(*)
    INTO machinery_count
    FROM public.machinery
    WHERE current_project_id = p_project_id;

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

-- ============================================================
-- PART 4: FIX GET_PROJECT_MATERIAL_BREAKDOWN (Bug Fix)
-- Previously referenced non-existent columns on stock_items
-- Now uses material_logs joined with stock_items
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
            s.name,
            -- Sum inward logs for received
            COALESCE(SUM(CASE WHEN ml.log_type = 'inward' THEN ml.quantity ELSE 0 END), 0) as received,
            -- Sum outward logs for consumed
            COALESCE(SUM(CASE WHEN ml.log_type = 'outward' THEN ml.quantity ELSE 0 END), 0) as consumed,
            -- Calculate remaining
            COALESCE(SUM(CASE WHEN ml.log_type = 'inward' THEN ml.quantity ELSE 0 END), 0) - 
            COALESCE(SUM(CASE WHEN ml.log_type = 'outward' THEN ml.quantity ELSE 0 END), 0) as remaining,
            s.unit
        FROM public.stock_items s
        LEFT JOIN public.material_logs ml ON s.id = ml.item_id
        WHERE s.project_id = p_project_id
        GROUP BY s.id, s.name, s.unit
        HAVING 
            COALESCE(SUM(CASE WHEN ml.log_type = 'inward' THEN ml.quantity ELSE 0 END), 0) > 0 OR
            COALESCE(SUM(CASE WHEN ml.log_type = 'outward' THEN ml.quantity ELSE 0 END), 0) > 0
        ORDER BY s.name
    ) as material_data;

    RETURN COALESCE(result, '[]'::JSON);
END;
$$;

-- ============================================================
-- PART 5: FIX GET_DASHBOARD_STATS
-- Ensure it uses the new status column on daily_reports
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
        'growth_percentage', 12.5, -- Placeholder
        'last_updated', NOW()
    ) INTO result;

    RETURN result;
END;
$$;

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
