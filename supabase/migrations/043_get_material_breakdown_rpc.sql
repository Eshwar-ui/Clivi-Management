-- Create RPC function to get material breakdown (Received, Consumed, Remaining)
-- This aggregates data from stock_items and material_logs

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
            s.unit,
            s.quantity as current_quantity
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
        SUM(sa.current_quantity) as remaining,
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
