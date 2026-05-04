-- ============================================================
-- Migration 045: Fix Material Quantity Sync Issues
-- ============================================================
-- Date: 2026-02-07
-- Description: Reconciles stock_items.quantity with material_logs
--   to fix mismatches where outward logs didn't update stock.
-- ============================================================

-- PART 1: DATA RECONCILIATION
-- ============================================================

-- Step 1: Recalculate all stock quantities from material_logs
-- This is the source of truth for actual inventory
UPDATE stock_items si
SET quantity = (
  SELECT COALESCE(SUM(CASE WHEN ml.log_type = 'inward' THEN ml.quantity ELSE 0 END), 0) -
         COALESCE(SUM(CASE WHEN ml.log_type = 'outward' THEN ml.quantity ELSE 0 END), 0)
  FROM material_logs ml
  WHERE ml.item_id = si.id
)
WHERE EXISTS (SELECT 1 FROM material_logs WHERE item_id = si.id);

-- Step 2: Delete orphaned stock items (no logs and zero quantity)
DELETE FROM stock_items
WHERE quantity = 0
  AND NOT EXISTS (SELECT 1 FROM material_logs WHERE item_id = stock_items.id);

-- Step 3: Add validation constraint to prevent negative stock
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'chk_stock_quantity_non_negative'
  ) THEN
    ALTER TABLE stock_items
    ADD CONSTRAINT chk_stock_quantity_non_negative
    CHECK (quantity >= 0);
  END IF;
END $$;

-- ============================================================
-- PART 2: FIX get_project_material_breakdown RPC
-- ============================================================

-- Drop and recreate with corrected logic
DROP FUNCTION IF EXISTS get_project_material_breakdown(UUID);

CREATE OR REPLACE FUNCTION get_project_material_breakdown(p_project_id UUID)
RETURNS TABLE (
    name TEXT,
    received NUMERIC,
    consumed NUMERIC,
    remaining NUMERIC,
    unit TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH stock_aggregates AS (
        -- Get all stock items for the project
        SELECT 
            s.id,
            s.name,
            s.unit
        FROM stock_items s
        WHERE s.project_id = p_project_id
    ),
    log_aggregates AS (
        -- Aggregate logs by item_id
        SELECT 
            ml.item_id,
            COALESCE(SUM(CASE WHEN ml.log_type = 'inward' THEN ml.quantity ELSE 0 END), 0) as received,
            COALESCE(SUM(CASE WHEN ml.log_type = 'outward' THEN ml.quantity ELSE 0 END), 0) as consumed
        FROM material_logs ml
        WHERE ml.project_id = p_project_id
        GROUP BY ml.item_id
    )
    SELECT 
        sa.name,
        -- Sum up stats for all items sharing the same name (e.g. diff grades of Steel)
        SUM(COALESCE(la.received, 0)) as received,
        SUM(COALESCE(la.consumed, 0)) as consumed,
        -- FIXED: Calculate remaining from logs (source of truth)
        SUM(COALESCE(la.received, 0)) - SUM(COALESCE(la.consumed, 0)) as remaining,
        sa.unit
    FROM stock_aggregates sa
    LEFT JOIN log_aggregates la ON sa.id = la.item_id
    GROUP BY sa.name, sa.unit
    ORDER BY sa.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_project_material_breakdown(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_project_material_breakdown(UUID) TO service_role;

-- ============================================================
-- PART 3: VERIFICATION QUERIES
-- ============================================================

-- Query 1: Check for any remaining mismatches
DO $$
DECLARE
  v_mismatch_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_mismatch_count
  FROM stock_items si
  LEFT JOIN (
    SELECT item_id,
      COALESCE(SUM(CASE WHEN log_type = 'inward' THEN quantity ELSE 0 END), 0) -
      COALESCE(SUM(CASE WHEN log_type = 'outward' THEN quantity ELSE 0 END), 0) as calc_qty
    FROM material_logs
    GROUP BY item_id
  ) ml ON si.id = ml.item_id
  WHERE si.quantity != COALESCE(ml.calc_qty, 0);
  
  RAISE NOTICE 'Mismatches remaining: %', v_mismatch_count;
  
  IF v_mismatch_count > 0 THEN
    RAISE WARNING 'Still have % mismatches after reconciliation!', v_mismatch_count;
  ELSE
    RAISE NOTICE 'SUCCESS: All stock quantities are now in sync with logs!';
  END IF;
END $$;

-- Query 2: Check for orphaned stock items
DO $$
DECLARE
  v_orphaned_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_orphaned_count
  FROM stock_items
  WHERE quantity = 0
    AND NOT EXISTS (SELECT 1 FROM material_logs WHERE item_id = stock_items.id);
  
  RAISE NOTICE 'Orphaned stock items: %', v_orphaned_count;
  
  IF v_orphaned_count > 0 THEN
    RAISE WARNING 'Still have % orphaned stock items!', v_orphaned_count;
  END IF;
END $$;

-- Query 3: Display reconciliation summary
DO $$
DECLARE
  v_record RECORD;
BEGIN
  RAISE NOTICE '=== RECONCILIATION SUMMARY ===';
  
  FOR v_record IN
    SELECT 
      name,
      grade,
      unit,
      quantity as current_stock,
      (SELECT SUM(CASE WHEN log_type = 'inward' THEN quantity ELSE 0 END) -
              SUM(CASE WHEN log_type = 'outward' THEN quantity ELSE 0 END)
       FROM material_logs WHERE item_id = stock_items.id) as calculated_stock
    FROM stock_items
    WHERE (name ILIKE '%steel%' OR name ILIKE '%cement%')
    ORDER BY name, grade
  LOOP
    RAISE NOTICE '% (%) [%]: Stock=%, Calculated=%', 
      v_record.name, 
      COALESCE(v_record.grade, 'NULL'), 
      v_record.unit,
      v_record.current_stock,
      v_record.calculated_stock;
  END LOOP;
END $$;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
