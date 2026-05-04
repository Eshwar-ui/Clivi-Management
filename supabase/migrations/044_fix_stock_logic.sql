-- ============================================================
-- Migration 044: Fix Stock Logic (Auto-update on Logs)
-- ============================================================

-- 1. Create Trigger Function to update stock based on logs
CREATE OR REPLACE FUNCTION public.update_stock_from_log()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.log_type = 'inward' THEN
        -- Increase stock
        UPDATE public.stock_items
        SET quantity = quantity + NEW.quantity,
            updated_at = NOW()
        WHERE id = NEW.item_id;
    ELSIF NEW.log_type = 'outward' THEN
        -- Decrease stock
        UPDATE public.stock_items
        SET quantity = quantity - NEW.quantity,
            updated_at = NOW()
        WHERE id = NEW.item_id;
    END IF;
    RETURN NEW;
END;
$$;

-- 2. Create Trigger on material_logs
DROP TRIGGER IF EXISTS trigger_update_stock_on_log ON public.material_logs;
CREATE TRIGGER trigger_update_stock_on_log
    AFTER INSERT ON public.material_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.update_stock_from_log();


-- 3. Update receive_material RPC to remove manual stock update (Prevent Double Counting)
-- Logic change: We now insert/ensure the item exists with 0 quantity (or ignore if exists),
-- and let the subsequent INSERT into material_logs trigger the actual quantity update.

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
SET search_path = public, pg_temp
AS $$
DECLARE
    v_stock_item_id UUID;
    v_log_id UUID;
    v_user_id UUID := auth.uid();
    v_grade TEXT := NULLIF(TRIM(p_grade), '');
BEGIN
    -- 1) Ensure Stock Item Exists (Idempotent)
    -- We insert with 0 quantity if new. If exists, we DO NOTHING (preserve current qty).
    -- The trigger on material_logs will handle the addition.
    INSERT INTO public.stock_items (project_id, name, grade, unit, quantity, created_by)
    VALUES (p_project_id, TRIM(p_material_name), v_grade, p_unit, 0, v_user_id)
    ON CONFLICT ON CONSTRAINT uq_stock_item_grade_project_name
    DO UPDATE SET unit = EXCLUDED.unit; -- Optional: update unit if changed, but don't touch quantity

    -- Get the stock item ID
    SELECT id INTO v_stock_item_id
    FROM public.stock_items
    WHERE project_id = p_project_id
      AND name = TRIM(p_material_name)
      AND (grade IS NOT DISTINCT FROM v_grade);

    -- 2) Insert material log (THIS FIRES THE TRIGGER to update stock)
    INSERT INTO public.material_logs (
        project_id, item_id, log_type, quantity, activity, notes,
        logged_by, supplier_id, payment_type, bill_amount, grade, logged_at
    )
    VALUES (
        p_project_id, v_stock_item_id, 'inward', p_quantity, p_activity, p_notes,
        v_user_id, p_supplier_id, p_payment_type, p_bill_amount, v_grade, NOW()
    )
    RETURNING id INTO v_log_id;

    -- 3) Update vendor materials (unchanged)
    INSERT INTO public.vendor_materials (project_id, supplier_id, material_name, grade, last_used_at)
    VALUES (p_project_id, p_supplier_id, TRIM(p_material_name), v_grade, NOW())
    ON CONFLICT ON CONSTRAINT uq_vendor_materials_unique
    DO UPDATE SET last_used_at = NOW();

    -- Also update price tracking since we have bill amount
    IF p_quantity > 0 THEN
      UPDATE public.vendor_materials
      SET last_price = p_bill_amount / p_quantity
      WHERE project_id = p_project_id
        AND supplier_id = p_supplier_id
        AND material_name = TRIM(p_material_name)
        AND (grade IS NOT DISTINCT FROM v_grade);
    END IF;

    RETURN v_log_id;
END;
$$;
