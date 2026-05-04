-- =============================================================================
-- MATERIAL OPERATIONS - MASTER TABLES & DYNAMIC STOCK MIGRATION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. MASTER TABLES (Global suggestions)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.material_master (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.material_grades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  material_id UUID REFERENCES public.material_master(id) ON DELETE CASCADE,
  grade_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(material_id, grade_name)
);

-- Enable RLS
ALTER TABLE public.material_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.material_grades ENABLE ROW LEVEL SECURITY;

-- Policies for Master Tables (Viewable by all authenticated, manageable by Admin)
CREATE POLICY "Authenticated users can view material master"
  ON public.material_master FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage material master"
  ON public.material_master FOR ALL TO authenticated
  USING (public.is_admin_or_super());

CREATE POLICY "Authenticated users can view material grades"
  ON public.material_grades FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage material grades"
  ON public.material_grades FOR ALL TO authenticated
  USING (public.is_admin_or_super());

-- Users (Site Managers) can also insert new suggestions implicitly? 
-- The user request says "Add new material" is allowed. 
-- Let's allow authenticated users to INSERT into master if it doesn't exist.
CREATE POLICY "Authenticated users can insert material master"
  ON public.material_master FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can insert material grades"
  ON public.material_grades FOR INSERT TO authenticated
  WITH CHECK (true);


-- -----------------------------------------------------------------------------
-- 2. DYNAMIC STOCK BALANCE VIEW
-- -----------------------------------------------------------------------------
-- Ensure stock_items has project_id NOT NULL if not already
ALTER TABLE public.stock_items ALTER COLUMN project_id SET NOT NULL;

-- Dynamic view replacing the static balance logic
CREATE OR REPLACE VIEW public.v_stock_balance_dynamic AS
SELECT 
  s.id AS item_id,
  s.project_id,
  s.name,
  s.grade,
  s.unit,
  s.low_stock_threshold,
  s.category,
  -- Dynamic calculation
  COALESCE(received.total, 0) AS total_received,
  COALESCE(consumed.total, 0) AS total_consumed,
  (COALESCE(received.total, 0) - COALESCE(consumed.total, 0)) AS current_stock,
  CASE 
    WHEN (COALESCE(received.total, 0) - COALESCE(consumed.total, 0)) <= s.low_stock_threshold THEN true 
    ELSE false 
  END AS is_low_stock
FROM public.stock_items s
LEFT JOIN (
  SELECT item_id, SUM(quantity) AS total
  FROM public.material_logs
  WHERE log_type = 'inward'
  GROUP BY item_id
) received ON received.item_id = s.id
LEFT JOIN (
  SELECT item_id, SUM(quantity) AS total
  FROM public.material_logs
  WHERE log_type = 'outward'
  GROUP BY item_id
) consumed ON consumed.item_id = s.id;

-- -----------------------------------------------------------------------------
-- 3. UPDATED LOGGING FUNCTIONS & TRIGGERS
-- -----------------------------------------------------------------------------

-- Helper to ensure stock item exists before logging (Idempotent Get-or-Create)
CREATE OR REPLACE FUNCTION public.get_or_create_stock_item(
  p_project_id UUID,
  p_name TEXT,
  p_grade TEXT,
  p_unit TEXT
) RETURNS UUID AS $$
DECLARE
  v_item_id UUID;
BEGIN
  -- Check for existing item in project (Name + Grade must be unique per project)
  SELECT id INTO v_item_id
  FROM public.stock_items
  WHERE project_id = p_project_id
    AND name = p_name
    AND COALESCE(grade, '') = COALESCE(p_grade, '');
    
  IF v_item_id IS NULL THEN
    INSERT INTO public.stock_items (project_id, name, grade, unit, quantity, created_by)
    VALUES (p_project_id, p_name, p_grade, p_unit, 0, auth.uid())
    RETURNING id INTO v_item_id;
  END IF;
  
  RETURN v_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Validation trigger for Consumptions
CREATE OR REPLACE FUNCTION public.validate_material_consumption()
RETURNS TRIGGER AS $$
DECLARE
  v_current_stock NUMERIC;
BEGIN
  IF NEW.log_type = 'outward' THEN
    -- Calculate current stock for this item
    SELECT current_stock INTO v_current_stock
    FROM public.v_stock_balance_dynamic
    WHERE item_id = NEW.item_id;
    
    IF v_current_stock IS NULL THEN 
       v_current_stock := 0; 
    END IF;
    
    IF NEW.quantity > v_current_stock THEN
      RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %', v_current_stock, NEW.quantity;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validate_consumption ON public.material_logs;
CREATE TRIGGER trigger_validate_consumption
  BEFORE INSERT ON public.material_logs
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_material_consumption();

-- Trigger to auto-add to Master tables on new Stock Item creation
CREATE OR REPLACE FUNCTION public.sync_material_master()
RETURNS TRIGGER AS $$
DECLARE
  v_materail_id UUID;
BEGIN
  -- 1. Sync Material Name
  INSERT INTO public.material_master (name)
  VALUES (NEW.name)
  ON CONFLICT (name) DO NOTHING;
  
  SELECT id INTO v_materail_id FROM public.material_master WHERE name = NEW.name;

  -- 2. Sync Grade if present
  IF NEW.grade IS NOT NULL THEN
    INSERT INTO public.material_grades (material_id, grade_name)
    VALUES (v_materail_id, NEW.grade)
    ON CONFLICT (material_id, grade_name) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_sync_material_master ON public.stock_items;
CREATE TRIGGER trigger_sync_material_master
  AFTER INSERT ON public.stock_items
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_material_master();

-- -----------------------------------------------------------------------------
-- 4. PERMISSIONS
-- -----------------------------------------------------------------------------

-- Grant access to the view
GRANT SELECT ON public.v_stock_balance_dynamic TO authenticated;

-- Notify schema reload
NOTIFY pgrst, 'reload schema';
