-- ============================================================
-- Migration 042: Fix Material Grades Duplicate Key Error
-- ============================================================
-- Date: 2026-02-06
-- Description: Fixes duplicate key error in material_grades when
--   adding materials with different grade name formats (e.g., "18 MM" vs "18MM")
--   that normalize to the same grade_key
-- ============================================================

-- Problem:
-- The sync_material_master() function used ON CONFLICT (material_id, grade_name)
-- but the unique constraint that matters is uq_material_grade_key on (material_id, grade_key).
-- Since grade_key is GENERATED ALWAYS AS (lower(regexp_replace(trim(grade_name), '\s+', '', 'g'))),
-- both "18MM" and "18 MM" normalize to "18mm", causing duplicate key violations.

-- Solution:
-- Update the function to use ON CONFLICT ON CONSTRAINT uq_material_grade_key

CREATE OR REPLACE FUNCTION public.sync_material_master()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_material_id UUID;
BEGIN
  -- 1. Sync Material Name
  INSERT INTO public.material_master (name)
  VALUES (NEW.name)
  ON CONFLICT (name) DO NOTHING;
  
  SELECT id INTO v_material_id FROM public.material_master WHERE name = NEW.name;

  -- 2. Sync Grade if present
  IF NEW.grade IS NOT NULL THEN
    -- FIXED: Use uq_material_grade_key constraint instead of (material_id, grade_name)
    -- This prevents duplicates when "18MM" and "18 MM" both normalize to grade_key "18mm"
    INSERT INTO public.material_grades (material_id, grade_name)
    VALUES (v_material_id, NEW.grade)
    ON CONFLICT ON CONSTRAINT uq_material_grade_key DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';

-- ============================================================
-- VERIFICATION
-- ============================================================
-- Test adding same material with different grade formats:
-- Both should succeed and reference the same material_grades entry

-- SELECT receive_material(
--   p_project_id := 'your-project-id'::uuid,
--   p_material_name := 'Steel',
--   p_grade := '18 MM',  -- With space
--   p_unit := 'Ton',
--   p_quantity := 10,
--   p_supplier_id := 'supplier-id'::uuid,
--   p_bill_amount := 100000
-- );

-- SELECT receive_material(
--   p_project_id := 'your-project-id'::uuid,
--   p_material_name := 'Steel',
--   p_grade := '18MM',  -- Without space
--   p_unit := 'Ton',
--   p_quantity := 10,
--   p_supplier_id := 'supplier-id'::uuid,
--   p_bill_amount := 100000
-- );

-- Verify only one material_grades entry exists:
-- SELECT grade_name, grade_key FROM material_grades
-- WHERE material_id = (SELECT id FROM material_master WHERE name = 'Steel')
--   AND grade_key = '18mm';
-- ============================================================
