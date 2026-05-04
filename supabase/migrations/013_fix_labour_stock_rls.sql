-- ============================================================
-- MIGRATION 013: CREATE TABLES & FIX RLS POLICIES
-- Creates labour, stock, attendance, material_logs tables if missing
-- Then applies proper RLS policies for Admin and Site Managers
-- ============================================================

-- ============================================================
-- PART 0: ENSURE HELPER FUNCTIONS EXIST
-- ============================================================

-- Check if user is admin or super_admin
CREATE OR REPLACE FUNCTION public.is_admin_or_super()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles 
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  );
$$;

-- Check if user is assigned to a project
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

GRANT EXECUTE ON FUNCTION public.is_admin_or_super() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_assigned_to_project(uuid) TO authenticated;

-- ============================================================
-- PART 1: CREATE LABOUR TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.labour (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    skill_type TEXT,
    daily_wage DECIMAL(10, 2),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.labour ENABLE ROW LEVEL SECURITY;

-- Drop existing policies safely
DROP POLICY IF EXISTS "Admins can manage labour" ON public.labour;
DROP POLICY IF EXISTS "Site managers can manage project labour" ON public.labour;
DROP POLICY IF EXISTS "Site managers can view project labour" ON public.labour;
DROP POLICY IF EXISTS "Site managers can add project labour" ON public.labour;
DROP POLICY IF EXISTS "Site managers can update project labour" ON public.labour;
DROP POLICY IF EXISTS "Site managers can delete project labour" ON public.labour;

-- Admin/Super Admin: Full access
CREATE POLICY "Admins can manage labour"
ON public.labour FOR ALL
USING (public.is_admin_or_super())
WITH CHECK (public.is_admin_or_super());

-- Site Managers: SELECT
CREATE POLICY "Site managers can view project labour"
ON public.labour FOR SELECT
USING (public.is_assigned_to_project(project_id));

-- Site Managers: INSERT
CREATE POLICY "Site managers can add project labour"
ON public.labour FOR INSERT
WITH CHECK (public.is_assigned_to_project(project_id));

-- Site Managers: UPDATE
CREATE POLICY "Site managers can update project labour"
ON public.labour FOR UPDATE
USING (public.is_assigned_to_project(project_id))
WITH CHECK (public.is_assigned_to_project(project_id));

-- Site Managers: DELETE
CREATE POLICY "Site managers can delete project labour"
ON public.labour FOR DELETE
USING (public.is_assigned_to_project(project_id));

-- ============================================================
-- PART 2: CREATE LABOUR_ATTENDANCE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.labour_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    labour_id UUID NOT NULL REFERENCES public.labour(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status TEXT DEFAULT 'present' CHECK (status IN ('present', 'absent', 'half_day')),
    hours_worked DECIMAL(4, 2),
    notes TEXT,
    recorded_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(labour_id, date)
);

-- Enable RLS
ALTER TABLE public.labour_attendance ENABLE ROW LEVEL SECURITY;

-- Drop existing policies safely
DROP POLICY IF EXISTS "Site managers can manage attendance" ON public.labour_attendance;
DROP POLICY IF EXISTS "Admins can manage attendance" ON public.labour_attendance;
DROP POLICY IF EXISTS "Site managers can view project attendance" ON public.labour_attendance;
DROP POLICY IF EXISTS "Site managers can add project attendance" ON public.labour_attendance;
DROP POLICY IF EXISTS "Site managers can update project attendance" ON public.labour_attendance;
DROP POLICY IF EXISTS "Site managers can delete project attendance" ON public.labour_attendance;

-- Admin/Super Admin: Full access
CREATE POLICY "Admins can manage attendance"
ON public.labour_attendance FOR ALL
USING (public.is_admin_or_super())
WITH CHECK (public.is_admin_or_super());

-- Site Managers: SELECT
CREATE POLICY "Site managers can view project attendance"
ON public.labour_attendance FOR SELECT
USING (public.is_assigned_to_project(project_id));

-- Site Managers: INSERT
CREATE POLICY "Site managers can add project attendance"
ON public.labour_attendance FOR INSERT
WITH CHECK (public.is_assigned_to_project(project_id));

-- Site Managers: UPDATE
CREATE POLICY "Site managers can update project attendance"
ON public.labour_attendance FOR UPDATE
USING (public.is_assigned_to_project(project_id))
WITH CHECK (public.is_assigned_to_project(project_id));

-- Site Managers: DELETE
CREATE POLICY "Site managers can delete project attendance"
ON public.labour_attendance FOR DELETE
USING (public.is_assigned_to_project(project_id));

-- ============================================================
-- PART 3: CREATE STOCK_ITEMS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.stock_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    unit TEXT DEFAULT 'units',
    quantity DECIMAL(15, 2) DEFAULT 0,
    min_quantity DECIMAL(15, 2) DEFAULT 0,
    low_stock_threshold DECIMAL DEFAULT 10,
    unit_price DECIMAL(15, 2),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.stock_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies safely
DROP POLICY IF EXISTS "Admins can manage stock" ON public.stock_items;
DROP POLICY IF EXISTS "Site managers can view project stock" ON public.stock_items;
DROP POLICY IF EXISTS "Site managers can update project stock" ON public.stock_items;
DROP POLICY IF EXISTS "Site managers can add project stock" ON public.stock_items;
DROP POLICY IF EXISTS "Site managers can delete project stock" ON public.stock_items;

-- Admin/Super Admin: Full access
CREATE POLICY "Admins can manage stock"
ON public.stock_items FOR ALL
USING (public.is_admin_or_super())
WITH CHECK (public.is_admin_or_super());

-- Site Managers: SELECT
CREATE POLICY "Site managers can view project stock"
ON public.stock_items FOR SELECT
USING (public.is_assigned_to_project(project_id));

-- Site Managers: INSERT
CREATE POLICY "Site managers can add project stock"
ON public.stock_items FOR INSERT
WITH CHECK (public.is_assigned_to_project(project_id));

-- Site Managers: UPDATE
CREATE POLICY "Site managers can update project stock"
ON public.stock_items FOR UPDATE
USING (public.is_assigned_to_project(project_id))
WITH CHECK (public.is_assigned_to_project(project_id));

-- Site Managers: DELETE
CREATE POLICY "Site managers can delete project stock"
ON public.stock_items FOR DELETE
USING (public.is_assigned_to_project(project_id));

-- ============================================================
-- PART 4: CREATE MATERIAL_LOGS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.material_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES public.stock_items(id) ON DELETE CASCADE,
  log_type TEXT NOT NULL CHECK (log_type IN ('inward', 'outward')),
  quantity DECIMAL NOT NULL CHECK (quantity > 0),
  activity TEXT,
  challan_url TEXT,
  logged_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  logged_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.material_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies safely
DROP POLICY IF EXISTS "Admins can manage material logs" ON public.material_logs;
DROP POLICY IF EXISTS "Site managers can view assigned project logs" ON public.material_logs;
DROP POLICY IF EXISTS "Site managers can insert logs for assigned projects" ON public.material_logs;
DROP POLICY IF EXISTS "Site managers can view project material logs" ON public.material_logs;
DROP POLICY IF EXISTS "Site managers can add project material logs" ON public.material_logs;
DROP POLICY IF EXISTS "Site managers can update project material logs" ON public.material_logs;
DROP POLICY IF EXISTS "Site managers can delete project material logs" ON public.material_logs;

-- Admin/Super Admin: Full access
CREATE POLICY "Admins can manage material logs"
ON public.material_logs FOR ALL
USING (public.is_admin_or_super())
WITH CHECK (public.is_admin_or_super());

-- Site Managers: SELECT
CREATE POLICY "Site managers can view project material logs"
ON public.material_logs FOR SELECT
USING (public.is_assigned_to_project(project_id));

-- Site Managers: INSERT
CREATE POLICY "Site managers can add project material logs"
ON public.material_logs FOR INSERT
WITH CHECK (public.is_assigned_to_project(project_id));

-- Site Managers: UPDATE
CREATE POLICY "Site managers can update project material logs"
ON public.material_logs FOR UPDATE
USING (public.is_assigned_to_project(project_id))
WITH CHECK (public.is_assigned_to_project(project_id));

-- Site Managers: DELETE
CREATE POLICY "Site managers can delete project material logs"
ON public.material_logs FOR DELETE
USING (public.is_assigned_to_project(project_id));

-- ============================================================
-- PART 5: CREATE INDEXES FOR PERFORMANCE
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_labour_project ON public.labour(project_id);
CREATE INDEX IF NOT EXISTS idx_labour_status ON public.labour(project_id, status);
CREATE INDEX IF NOT EXISTS idx_attendance_project_date ON public.labour_attendance(project_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_labour ON public.labour_attendance(labour_id, date);
CREATE INDEX IF NOT EXISTS idx_stock_project ON public.stock_items(project_id);
CREATE INDEX IF NOT EXISTS idx_material_logs_project ON public.material_logs(project_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_material_logs_item ON public.material_logs(item_id, logged_at DESC);

-- ============================================================
-- PART 6: CREATE TRIGGER FOR UPDATED_AT
-- ============================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
DROP TRIGGER IF EXISTS update_labour_updated_at ON public.labour;
CREATE TRIGGER update_labour_updated_at
    BEFORE UPDATE ON public.labour
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_stock_items_updated_at ON public.stock_items;
CREATE TRIGGER update_stock_items_updated_at
    BEFORE UPDATE ON public.stock_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- MIGRATION COMPLETE
-- Run in Supabase SQL Editor
-- ============================================================
