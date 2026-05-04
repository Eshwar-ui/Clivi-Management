-- ============================================================
-- MIGRATION 038: ROBUST DUPLICATE CLEANUP & CONSTRAINT FIX
-- ============================================================

-- 1. CLEANUP DUPLICATES WITH FOREIGN KEY HANDLING
DO $$
DECLARE
    r RECORD;
    winner_id UUID;
    loser_id UUID;
    total_q NUMERIC;
BEGIN
    FOR r IN 
        SELECT project_id, name, grade, COUNT(*) as cnt
        FROM public.stock_items
        GROUP BY project_id, name, grade
        HAVING COUNT(*) > 1
    LOOP
        SELECT id INTO winner_id
        FROM public.stock_items
        WHERE project_id = r.project_id 
          AND name = r.name 
          AND (grade IS NOT DISTINCT FROM r.grade)
        ORDER BY created_at DESC
        LIMIT 1;

        SELECT SUM(quantity) INTO total_q
        FROM public.stock_items
        WHERE project_id = r.project_id 
          AND name = r.name 
          AND (grade IS NOT DISTINCT FROM r.grade);

        UPDATE public.stock_items
        SET quantity = total_q
        WHERE id = winner_id;

        FOR loser_id IN
            SELECT id
            FROM public.stock_items
            WHERE project_id = r.project_id 
              AND name = r.name 
              AND (grade IS NOT DISTINCT FROM r.grade)
              AND id != winner_id
        LOOP
            UPDATE public.material_logs
            SET item_id = winner_id
            WHERE item_id = loser_id;

            DELETE FROM public.stock_items WHERE id = loser_id;
        END LOOP;
    END LOOP;
END $$;

-- 2. ADD UNIQUE CONSTRAINT TO STOCK ITEMS (Explicit Name)
ALTER TABLE public.stock_items 
DROP CONSTRAINT IF EXISTS uq_stock_item_grade_project_name;

ALTER TABLE public.stock_items
ADD CONSTRAINT uq_stock_item_grade_project_name 
UNIQUE NULLS NOT DISTINCT (project_id, name, grade);


-- 3. RECREATE VENDOR_MATERIALS (With Explicit Constraint Name)
DROP TABLE IF EXISTS public.vendor_materials CASCADE;

CREATE TABLE public.vendor_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE CASCADE,
    material_name TEXT NOT NULL,
    grade TEXT,
    last_price NUMERIC,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    -- Explicit constraint name for RPC usage
    CONSTRAINT uq_vendor_materials_unique 
    UNIQUE NULLS NOT DISTINCT (project_id, supplier_id, material_name, grade)
);

ALTER TABLE public.vendor_materials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view vendor materials"
ON public.vendor_materials FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can modify vendor materials"
ON public.vendor_materials FOR ALL TO authenticated USING (true);


-- 4. RPC: FIXED ON CONFLICT CLAUSES
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
        p_grade, 
        p_unit,
        p_quantity,
        v_user_id
    )
    ON CONFLICT ON CONSTRAINT uq_stock_item_grade_project_name
    DO UPDATE SET
        quantity = public.stock_items.quantity + EXCLUDED.quantity,
        unit = EXCLUDED.unit;

    SELECT id INTO v_stock_item_id
    FROM public.stock_items
    WHERE project_id = p_project_id 
      AND name = p_material_name 
      AND (grade IS NOT DISTINCT FROM p_grade);

    -- B. INSERT LOG
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

    -- C. UPSERT VENDOR_MATERIALS (Use Named Constraint)
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
    ON CONFLICT ON CONSTRAINT uq_vendor_materials_unique
    DO UPDATE SET
        last_used_at = NOW();

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

NOTIFY pgrst, 'reload schema';
