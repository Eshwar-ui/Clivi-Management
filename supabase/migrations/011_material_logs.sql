-- ============================================================
-- MIGRATION 011: STOCK ITEMS + MATERIAL LOGS
-- Creates stock_items if missing and material_logs for tracking
-- ============================================================

-- ============================================================
-- PART 1: STOCK ITEMS TABLE (if not exists)
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

-- Enable RLS on stock_items
ALTER TABLE public.stock_items ENABLE ROW LEVEL SECURITY;

-- Stock items RLS policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admins can manage stock' AND tablename = 'stock_items') THEN
    CREATE POLICY "Admins can manage stock"
      ON public.stock_items FOR ALL
      USING (public.is_admin_or_super());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Site managers can view project stock' AND tablename = 'stock_items') THEN
    CREATE POLICY "Site managers can view project stock"
      ON public.stock_items FOR SELECT
      USING (public.is_assigned_to_project(project_id));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Site managers can update project stock' AND tablename = 'stock_items') THEN
    CREATE POLICY "Site managers can update project stock"
      ON public.stock_items FOR UPDATE
      USING (public.is_assigned_to_project(project_id));
  END IF;
END $$;

-- ============================================================
-- PART 2: MATERIAL LOGS TABLE
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

-- ============================================================
-- PART 3: INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_material_logs_project
ON material_logs(project_id, logged_at DESC);

CREATE INDEX IF NOT EXISTS idx_material_logs_item
ON material_logs(item_id, logged_at DESC);

CREATE INDEX IF NOT EXISTS idx_material_logs_type
ON material_logs(project_id, log_type, logged_at DESC);

CREATE INDEX IF NOT EXISTS idx_stock_items_project
ON stock_items(project_id);

-- ============================================================
-- PART 4: RLS POLICIES FOR MATERIAL LOGS
-- ============================================================

ALTER TABLE public.material_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage material logs"
ON public.material_logs FOR ALL
USING (public.is_admin_or_super());

CREATE POLICY "Site managers can view assigned project logs"
ON public.material_logs FOR SELECT
USING (public.is_assigned_to_project(project_id));

CREATE POLICY "Site managers can insert logs for assigned projects"
ON public.material_logs FOR INSERT
WITH CHECK (public.is_assigned_to_project(project_id));

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
