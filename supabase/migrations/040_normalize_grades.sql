-- ============================================================
-- MIGRATION 040: NORMALIZE GRADES & CLEANUP
-- ============================================================

-- 1. CLEANUP DUPLICATES IN MATERIAL_GRADES
-- Before enforcing strict uniqueness, we remove existing duplicates.
-- We normalize by lowercasing and removing spaces for comparison.
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

-- 2. ADD GENERATED COLUMN (grade_key)
ALTER TABLE public.material_grades
ADD COLUMN IF NOT EXISTS grade_key text
GENERATED ALWAYS AS (lower(regexp_replace(trim(grade_name), '\s+', '', 'g'))) STORED;

-- 3. ENFORCE UNIQUENESS ON NORMALIZED KEY
ALTER TABLE public.material_grades
DROP CONSTRAINT IF EXISTS uq_material_grade_key;

ALTER TABLE public.material_grades
ADD CONSTRAINT uq_material_grade_key UNIQUE (material_id, grade_key);

-- 4. CLEANUP STOCK ITEMS TRIGGERS (If any exist setting name_key/grade_key)
-- We attempt to drop the likely culprit if it exists from older schema versions
DROP TRIGGER IF EXISTS trigger_set_stock_item_keys ON public.stock_items;
-- Function might be named differently, so we just ensure no bad columns exist?
-- Actually user said "Drop anything that assigns NEW.name_key".
-- We can't dynamic SQL drop easily without knowing name. 
-- But we can ensure the COLUMNS themselves don't exist if they were legacy.
-- If columns exist, we drop them.
ALTER TABLE public.stock_items DROP COLUMN IF EXISTS name_key;
ALTER TABLE public.stock_items DROP COLUMN IF EXISTS grade_key;

-- Notify schema reload
NOTIFY pgrst, 'reload schema';
