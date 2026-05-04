-- ============================================================
-- MACHINERY AND MACHINERY LOGS TABLES
-- ============================================================

-- Create machinery table if not exists
CREATE TABLE IF NOT EXISTS public.machinery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT, -- Excavator, Crane, Mixer, etc.
    registration_no TEXT UNIQUE,
    current_reading DECIMAL(10,2) DEFAULT 0,
    total_hours DECIMAL(10,2) DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'idle', 'retired')),
    purchase_date DATE,
    last_service DATE,
    current_project_id UUID REFERENCES public.projects(id), -- Tracks which project explicitly has it
    created_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create machinery_logs table if not exists
CREATE TABLE IF NOT EXISTS public.machinery_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    machinery_id UUID NOT NULL REFERENCES public.machinery(id) ON DELETE CASCADE,
    work_activity TEXT NOT NULL,
    start_reading DECIMAL(10,2) NOT NULL,
    end_reading DECIMAL(10,2) NOT NULL,
    execution_hours DECIMAL(10,2) GENERATED ALWAYS AS (end_reading - start_reading) STORED,
    notes TEXT,
    logged_by UUID REFERENCES public.user_profiles(id),
    logged_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.machinery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.machinery_logs ENABLE ROW LEVEL SECURITY;

-- Machinery policies (global resource, but logs are project-specific)
DROP POLICY IF EXISTS "Everyone can view machinery" ON public.machinery;
CREATE POLICY "Everyone can view machinery"
    ON public.machinery FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admins can manage machinery" ON public.machinery;
CREATE POLICY "Admins can manage machinery"
    ON public.machinery FOR ALL
    USING (public.is_admin_or_super())
    WITH CHECK (public.is_admin_or_super());

-- Machinery logs policies
DROP POLICY IF EXISTS "Admins can manage all machinery logs" ON public.machinery_logs;
CREATE POLICY "Admins can manage all machinery logs"
    ON public.machinery_logs FOR ALL
    USING (public.is_admin_or_super())
    WITH CHECK (public.is_admin_or_super());

DROP POLICY IF EXISTS "Site managers can view project machinery logs" ON public.machinery_logs;
CREATE POLICY "Site managers can view project machinery logs"
    ON public.machinery_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = machinery_logs.project_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Site managers can create project machinery logs" ON public.machinery_logs;
CREATE POLICY "Site managers can create project machinery logs"
    ON public.machinery_logs FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = machinery_logs.project_id AND user_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX IF NOT EXISTS idx_machinery_logs_project ON public.machinery_logs(project_id);
CREATE INDEX IF NOT EXISTS idx_machinery_logs_machinery ON public.machinery_logs(machinery_id);
CREATE INDEX IF NOT EXISTS idx_machinery_status ON public.machinery(status);

-- Refresh schema
NOTIFY pgrst, 'reload schema';
