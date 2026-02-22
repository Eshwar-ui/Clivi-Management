-- ============================================================
-- FIX: Clean Up Duplicate Constraints & Recreate RPC
-- ============================================================
-- ⚠️ NOTE: These fixes have been applied to production (2026-02-06)
-- ⚠️ See migration 041_fix_material_addition.sql for the official migration
-- ============================================================
-- This script fixes the 42P10 error by ensuring only ONE
-- unique constraint exists and the RPC references it correctly.
-- ============================================================

-- 1A) CLEAN UP DUPLICATE STOCK_ITEMS CONSTRAINTS
-- Keep only: uq_stock_item_grade_project_name (NULLS NOT DISTINCT)
-- Drop the duplicate/confusing one

ALTER TABLE public.stock_items
  DROP CONSTRAINT IF EXISTS uq_stock_items_project_name_grade;

ALTER TABLE public.stock_items
  DROP CONSTRAINT IF EXISTS uq_stock_item_project_name_grade;

-- Ensure we have the correct one
ALTER TABLE public.stock_items
  DROP CONSTRAINT IF EXISTS uq_stock_item_grade_project_name;

ALTER TABLE public.stock_items
  ADD CONSTRAINT uq_stock_item_grade_project_name
  UNIQUE NULLS NOT DISTINCT (project_id, name, grade);

-- Verify (run this to see what constraints exist)
-- SELECT c.conname, pg_get_constraintdef(c.oid) AS def
-- FROM pg_constraint c
-- WHERE c.conrelid = 'public.stock_items'::regclass AND c.contype='u'
-- ORDER BY c.conname;


-- 1B) FIX VENDOR_MATERIALS CONSTRAINT
ALTER TABLE public.vendor_materials
  DROP CONSTRAINT IF EXISTS uq_vendor_materials_unique;

ALTER TABLE public.vendor_materials
  ADD CONSTRAINT uq_vendor_materials_unique
  UNIQUE NULLS NOT DISTINCT (project_id, supplier_id, material_name, grade);


-- 1C) RECREATE RPC WITH CORRECT CONSTRAINT NAMES
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
AS $$
DECLARE
    v_stock_item_id UUID;
    v_log_id UUID;
    v_user_id UUID := auth.uid();
    v_grade TEXT := NULLIF(TRIM(p_grade), '');  -- convert "" => NULL
BEGIN
    -- 1) UPSERT stock item (THIS is what will make 100 + 50 => 150)
    INSERT INTO public.stock_items (project_id, name, grade, unit, quantity, created_by)
    VALUES (p_project_id, TRIM(p_material_name), v_grade, p_unit, p_quantity, v_user_id)
    ON CONFLICT ON CONSTRAINT uq_stock_item_grade_project_name
    DO UPDATE SET
        quantity = public.stock_items.quantity + EXCLUDED.quantity,
        unit = EXCLUDED.unit;

    SELECT id INTO v_stock_item_id
    FROM public.stock_items
    WHERE project_id = p_project_id
      AND name = TRIM(p_material_name)
      AND (grade IS NOT DISTINCT FROM v_grade);

    -- 2) Insert log (history)
    INSERT INTO public.material_logs (
        project_id, item_id, log_type, quantity, activity, notes,
        logged_by, supplier_id, payment_type, bill_amount, grade, logged_at
    )
    VALUES (
        p_project_id, v_stock_item_id, 'inward', p_quantity, p_activity, p_notes,
        v_user_id, p_supplier_id, p_payment_type, p_bill_amount, v_grade, NOW()
    )
    RETURNING id INTO v_log_id;

    -- 3) vendor_materials memory (dropdown suggestions)
    INSERT INTO public.vendor_materials (project_id, supplier_id, material_name, grade, last_used_at)
    VALUES (p_project_id, p_supplier_id, TRIM(p_material_name), v_grade, NOW())
    ON CONFLICT ON CONSTRAINT uq_vendor_materials_unique
    DO UPDATE SET last_used_at = NOW();

    RETURN v_log_id;
END;
$$;

NOTIFY pgrst, 'reload schema';

-- ============================================================
-- DONE! Now test your material receipt in the app.
-- ============================================================
