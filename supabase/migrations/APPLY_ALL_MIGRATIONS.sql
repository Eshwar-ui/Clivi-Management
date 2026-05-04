-- ============================================================
-- COMPLETE MIGRATION SCRIPT: Apply Migrations 037-040
-- ============================================================
-- Apply this script in your Supabase SQL Editor to fix the
-- material receipt functionality.
-- ============================================================

-- ============================================================
-- MIGRATION 037: MATERIAL UNIQUENESS & TRANSACTIONAL RECEIPT
-- ============================================================

-- 1. CLEANUP DUPLICATES IN STOCK_ITEMS
DO $$
DECLARE
    r RECORD;
    winner_id UUID;
    loser_ids UUID[];
    total_q NUMERIC;
BEGIN
    FOR r IN 
        SELECT project_id, name, grade, COUNT(*) as cnt
        FROM public.stock_items
        GROUP BY project_id, name, grade
        HAVING COUNT(*) > 1
    LOOP
        -- Get the winner (most recent)
        SELECT id INTO winner_id
        FROM public.stock_items
        WHERE project_id = r.project_id 
          AND name = r.name 
          AND (grade IS NOT DISTINCT FROM r.grade)
        ORDER BY created_at DESC
        LIMIT 1;

        -- Get total quantity
        SELECT SUM(quantity) INTO total_q
        FROM public.stock_items
        WHERE project_id = r.project_id 
          AND name = r.name 
          AND (grade IS NOT DISTINCT FROM r.grade);

        -- Update winner with total quantity
        UPDATE public.stock_items
        SET quantity = total_q
        WHERE id = winner_id;

        -- Update foreign keys pointing to losers
        UPDATE public.material_logs
        SET item_id = winner_id
        WHERE item_id IN (
            SELECT id
            FROM public.stock_items
            WHERE project_id = r.project_id 
              AND name = r.name 
              AND (grade IS NOT DISTINCT FROM r.grade)
              AND id != winner_id
        );

        -- Delete losers
        DELETE FROM public.stock_items
        WHERE project_id = r.project_id 
          AND name = r.name 
          AND (grade IS NOT DISTINCT FROM r.grade)
          AND id != winner_id;
    END LOOP;
END $$;

-- 2. ADD UNIQUE CONSTRAINT (Original name from 037)
ALTER TABLE public.stock_items
DROP CONSTRAINT IF EXISTS uq_stock_item_project_name_grade;

ALTER TABLE public.stock_items
ADD CONSTRAINT uq_stock_item_project_name_grade 
UNIQUE NULLS NOT DISTINCT (project_id, name, grade);

-- 3. CREATE VENDOR_MATERIALS TABLE
DROP TABLE IF EXISTS public.vendor_materials CASCADE;

CREATE TABLE public.vendor_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE CASCADE,
    material_name TEXT NOT NULL,
    grade TEXT,
    last_price NUMERIC,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE NULLS NOT DISTINCT (project_id, supplier_id, material_name, grade)
);

ALTER TABLE public.vendor_materials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view vendor materials"
ON public.vendor_materials FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can modify vendor materials"
ON public.vendor_materials FOR ALL TO authenticated USING (true);

-- Notify schema reload
NOTIFY pgrst, 'reload schema';


-- ============================================================
-- MIGRATION 038: ROBUST DUPLICATE CLEANUP & CONSTRAINT FIX
-- ============================================================

-- 1. Rename constraint to the correct name
ALTER TABLE public.stock_items 
DROP CONSTRAINT IF EXISTS uq_stock_item_project_name_grade;

ALTER TABLE public.stock_items 
DROP CONSTRAINT IF EXISTS uq_stock_item_grade_project_name;

ALTER TABLE public.stock_items
ADD CONSTRAINT uq_stock_item_grade_project_name 
UNIQUE NULLS NOT DISTINCT (project_id, name, grade);

-- 2. Recreate vendor_materials with named constraint
DROP TABLE IF EXISTS public.vendor_materials CASCADE;

CREATE TABLE public.vendor_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE CASCADE,
    material_name TEXT NOT NULL,
    grade TEXT,
    last_price NUMERIC,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_vendor_materials_unique 
    UNIQUE NULLS NOT DISTINCT (project_id, supplier_id, material_name, grade)
);

ALTER TABLE public.vendor_materials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view vendor materials"
ON public.vendor_materials FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can modify vendor materials"
ON public.vendor_materials FOR ALL TO authenticated USING (true);

-- 3. Create/Replace RPC function
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

    -- C. UPSERT VENDOR_MATERIALS
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


-- ============================================================
-- MIGRATION 039: FIX PAYMENT TYPE CONSTRAINT
-- ============================================================

ALTER TABLE public.material_logs 
DROP CONSTRAINT IF EXISTS material_logs_payment_type_check;

ALTER TABLE public.material_logs 
ADD CONSTRAINT material_logs_payment_type_check 
CHECK (payment_type IN (
    'Cash', 
    'Online', 
    'Cheque', 
    'Credit',
    'UPI', 
    'Bank Transfer',
    'cash', 
    'online', 
    'cheque', 
    'credit'
));

NOTIFY pgrst, 'reload schema';


-- ============================================================
-- MIGRATION 040: NORMALIZE GRADES & CLEANUP
-- ============================================================

-- 1. CLEANUP DUPLICATES IN MATERIAL_GRADES
WITH normalized_counts AS (
    SELECT 
        id,
        material_id, 
        lower(regexp_replace(trim(grade_name), '\s+', '', 'g')) as norm_key,
        created_at
    FROM public.material_grades
),
duplicates AS (
    SELECT 
        id,
        row_number() OVER (PARTITION BY material_id, norm_key ORDER BY created_at DESC) as rn
    FROM normalized_counts
)
DELETE FROM public.material_grades
WHERE id IN (
    SELECT id FROM duplicates WHERE rn > 1
);

-- 2. ADD GENERATED COLUMN
ALTER TABLE public.material_grades
ADD COLUMN IF NOT EXISTS grade_key text
GENERATED ALWAYS AS (lower(regexp_replace(trim(grade_name), '\s+', '', 'g'))) STORED;

-- 3. ENFORCE UNIQUENESS
ALTER TABLE public.material_grades
DROP CONSTRAINT IF EXISTS uq_material_grade_key;

ALTER TABLE public.material_grades
ADD CONSTRAINT uq_material_grade_key UNIQUE (material_id, grade_key);

-- 4. CLEANUP STOCK ITEMS
DROP TRIGGER IF EXISTS trigger_set_stock_item_keys ON public.stock_items;
ALTER TABLE public.stock_items DROP COLUMN IF EXISTS name_key;
ALTER TABLE public.stock_items DROP COLUMN IF EXISTS grade_key;

NOTIFY pgrst, 'reload schema';

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
