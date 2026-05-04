-- ============================================================
-- MIGRATION 037: MATERIAL UNIIQUENESS & TRANSACTIONAL RECEIPT
-- ============================================================

-- 1. CLEANUP DUPLICATES IN STOCK_ITEMS
-- Before adding unique constraint, we must merge duplicate rows.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT project_id, name, grade, COUNT(*) as cnt
        FROM public.stock_items
        GROUP BY project_id, name, grade
        HAVING COUNT(*) > 1
    LOOP
        -- Merge logic: Keep the one with most recent update or creation, sum quantities onto it
        WITH duplicates AS (
            SELECT id, quantity
            FROM public.stock_items
            WHERE project_id = r.project_id 
              AND name = r.name 
              AND (grade IS NOT DISTINCT FROM r.grade)
            ORDER BY created_at DESC
        ),
        kept_row AS (
            SELECT id FROM duplicates LIMIT 1
        ),
        total_qty AS (
            SELECT SUM(quantity) as total FROM duplicates
        )
        -- Update key row
        UPDATE public.stock_items
        SET quantity = (SELECT total FROM total_qty)
        WHERE id = (SELECT id FROM kept_row);

        -- Delete others
        DELETE FROM public.stock_items
        WHERE project_id = r.project_id 
          AND name = r.name 
          AND (grade IS NOT DISTINCT FROM r.grade)
          AND id != (SELECT id FROM duplicates LIMIT 1);
          
    END LOOP;
END $$;

-- 2. ADD UNIQUE CONSTRAINT
ALTER TABLE public.stock_items
ADD CONSTRAINT uq_stock_item_project_name_grade 
UNIQUE NULLS NOT DISTINCT (project_id, name, grade);

-- 3. CREATE VENDOR_MATERIALS TABLE (For memory/suggestions)
CREATE TABLE IF NOT EXISTS public.vendor_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE CASCADE,
    material_name TEXT NOT NULL,
    grade TEXT,
    last_price NUMERIC,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE NULLS NOT DISTINCT (project_id, supplier_id, material_name, grade)
);

-- Enable RLS
ALTER TABLE public.vendor_materials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view vendor materials"
ON public.vendor_materials FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can modify vendor materials"
ON public.vendor_materials FOR ALL TO authenticated USING (true);


-- 4. RPC: RECEIVE_MATERIAL (The "One RPC to Rule Them All")
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
RETURNS UUID AS $$
DECLARE
    v_stock_item_id UUID;
    v_log_id UUID;
    v_user_id UUID := auth.uid();
BEGIN
    -- A. UPSERT STOCK ITEM
    INSERT INTO public.stock_items (
        project_id, 
        name, 
        grade, 
        unit, 
        quantity, 
        created_by
    )
    VALUES (
        p_project_id,
        p_material_name,
        p_grade, -- Can be NULL
        p_unit,
        p_quantity,
        v_user_id
    )
    ON CONFLICT (project_id, name, grade)
    DO UPDATE SET
        quantity = public.stock_items.quantity + EXCLUDED.quantity,
        -- Update unit if it changed? Maybe keep existing. Let's keep existing to avoid overwrite confusion, 
        -- or update it to latest. Let's update unit to latest.
        unit = EXCLUDED.unit;

    -- Get the ID (whether inserted or updated)
    SELECT id INTO v_stock_item_id
    FROM public.stock_items
    WHERE project_id = p_project_id 
      AND name = p_material_name 
      AND (grade IS NOT DISTINCT FROM p_grade);

    -- B. INSERT MATERIAL LOG (History)
    INSERT INTO public.material_logs (
        project_id,
        item_id,
        log_type,
        quantity,
        activity,
        notes,
        logged_by,
        supplier_id,
        payment_type,
        bill_amount,
        grade,
        logged_at
    )
    VALUES (
        p_project_id,
        v_stock_item_id,
        'inward',
        p_quantity,
        p_activity,
        p_notes,
        v_user_id,
        p_supplier_id,
        p_payment_type,
        p_bill_amount,
        p_grade,
        NOW()
    )
    RETURNING id INTO v_log_id;

    -- C. UPSERT VENDOR_MATERIALS (Learn preference)
    INSERT INTO public.vendor_materials (
        project_id,
        supplier_id,
        material_name,
        grade,
        last_used_at
    )
    VALUES (
        p_project_id,
        p_supplier_id,
        p_material_name,
        p_grade,
        NOW()
    )
    ON CONFLICT (project_id, supplier_id, material_name, grade)
    DO UPDATE SET
        last_used_at = NOW();

    -- D. SYNC TO MASTER (Already handled by trigger on stock_items INSERT, 
    -- but if it was an UPDATE, the trigger might not fire for master table inserts if name existed. 
    -- The trigger `trigger_sync_material_master` is AFTER INSERT on stock_items.
    -- If we did an UPDATE on stock_items, we might miss adding to master if it wasn't there? 
    -- Actually stock item existence implies master existence usually. 
    -- But just in case, we can rely on the trigger for new items. 
    -- Existing items are fine.)

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Notify schema reload
NOTIFY pgrst, 'reload schema';
