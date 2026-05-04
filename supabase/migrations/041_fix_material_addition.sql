-- ============================================================
-- Migration 041: Fix Material Addition Issues
-- ============================================================
-- Date: 2026-02-06
-- Description: Fixes material addition failures by:
--   1. Replacing receive_material RPC with atomic UPSERT
--   2. Fixing update_vendor_materials trigger constraint
--   3. Allowing NULL grades in stock_items
-- ============================================================

-- 1. Allow NULL grades (materials like Sand don't have grades)
ALTER TABLE public.stock_items
  ALTER COLUMN grade DROP NOT NULL;

-- 2. Replace receive_material RPC with improved UPSERT version
DROP FUNCTION IF EXISTS public.receive_material;

CREATE OR REPLACE FUNCTION public.receive_material(
    p_project_id UUID,
    p_material_name TEXT,
    p_grade TEXT,
    p_unit TEXT,
    p_quantity NUMERIC,
    p_supplier_id UUID,
    p_bill_amount NUMERIC,
    p_payment_type TEXT DEFAULT 'Cash',
    p_activity TEXT DEFAULT 'Material Received',
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp  -- Security fix: prevent search_path attacks
AS $$
DECLARE
    v_stock_item_id UUID;
    v_log_id UUID;
    v_user_id UUID := auth.uid();
    v_grade TEXT := NULLIF(TRIM(p_grade), '');  -- Convert empty string to NULL
BEGIN
    -- 1) UPSERT stock item (Atomic: prevents race conditions)
    INSERT INTO public.stock_items (project_id, name, grade, unit, quantity, created_by)
    VALUES (p_project_id, TRIM(p_material_name), v_grade, p_unit, p_quantity, v_user_id)
    ON CONFLICT ON CONSTRAINT uq_stock_item_grade_project_name
    DO UPDATE SET
        quantity = public.stock_items.quantity + EXCLUDED.quantity,
        unit = EXCLUDED.unit;

    -- Get the stock item ID
    SELECT id INTO v_stock_item_id
    FROM public.stock_items
    WHERE project_id = p_project_id
      AND name = TRIM(p_material_name)
      AND (grade IS NOT DISTINCT FROM v_grade);

    -- 2) Insert material log (audit trail)
    INSERT INTO public.material_logs (
        project_id, item_id, log_type, quantity, activity, notes,
        logged_by, supplier_id, payment_type, bill_amount, grade, logged_at
    )
    VALUES (
        p_project_id, v_stock_item_id, 'inward', p_quantity, p_activity, p_notes,
        v_user_id, p_supplier_id, p_payment_type, p_bill_amount, v_grade, NOW()
    )
    RETURNING id INTO v_log_id;

    -- 3) Update vendor materials (for dropdown suggestions)
    INSERT INTO public.vendor_materials (project_id, supplier_id, material_name, grade, last_used_at)
    VALUES (p_project_id, p_supplier_id, TRIM(p_material_name), v_grade, NOW())
    ON CONFLICT ON CONSTRAINT uq_vendor_materials_unique
    DO UPDATE SET last_used_at = NOW();

    RETURN v_log_id;
END;
$$;

-- 3. Fix update_vendor_materials trigger to include project_id
CREATE OR REPLACE FUNCTION public.update_vendor_materials()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.log_type = 'inward' AND NEW.supplier_id IS NOT NULL THEN
    -- FIXED: Include project_id in the UPSERT
    INSERT INTO public.vendor_materials (project_id, supplier_id, material_name, grade, last_price, last_used_at)
    SELECT 
      NEW.project_id,  -- ADDED: project_id
      NEW.supplier_id,
      s.name,
      COALESCE(NEW.grade, s.grade),
      NEW.bill_amount / NULLIF(NEW.quantity, 0),
      NOW()
    FROM public.stock_items s WHERE s.id = NEW.item_id
    ON CONFLICT ON CONSTRAINT uq_vendor_materials_unique  -- Use constraint name
    DO UPDATE SET 
      last_price = EXCLUDED.last_price,
      last_used_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';

-- ============================================================
-- VERIFICATION QUERIES (Run these to validate)
-- ============================================================
-- Check function exists with correct signature:
-- SELECT proname, prosecdef, pg_get_function_identity_arguments(oid)
-- FROM pg_proc WHERE proname = 'receive_material';

-- Check grade column allows NULL:
-- SELECT column_name, is_nullable FROM information_schema.columns
-- WHERE table_name = 'stock_items' AND column_name = 'grade';

-- Test material addition:
-- SELECT receive_material(
--   p_project_id := 'your-project-id'::uuid,
--   p_material_name := 'Test Material',
--   p_grade := 'Grade A',
--   p_unit := 'Kg',
--   p_quantity := 100,
--   p_supplier_id := 'your-supplier-id'::uuid,
--   p_bill_amount := 5000
-- );
-- ============================================================
