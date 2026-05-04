-- ============================================================
-- HELPER FUNCTIONS FOR ATOMIC OPERATIONS
-- ============================================================

-- Function to update stock quantity atomically
CREATE OR REPLACE FUNCTION update_stock_quantity(
    p_item_id UUID,
    p_quantity DECIMAL,
    p_operation TEXT -- 'add' or 'subtract'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF p_operation = 'add' THEN
        UPDATE stock_items 
        SET quantity = quantity + p_quantity,
            updated_at = NOW()
        WHERE id = p_item_id;
    ELSIF p_operation = 'subtract' THEN
        UPDATE stock_items 
        SET quantity = GREATEST(0, quantity - p_quantity),
            updated_at = NOW()
        WHERE id = p_item_id;
    END IF;
END;
$$;

-- Function to increment machinery hours
CREATE OR REPLACE FUNCTION increment_machinery_hours(
    p_machinery_id UUID,
    p_hours DECIMAL
)
RETURNS DECIMAL
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_total DECIMAL;
BEGIN
    UPDATE machinery 
    SET total_hours = total_hours + p_hours,
        updated_at = NOW()
    WHERE id = p_machinery_id
    RETURNING total_hours INTO new_total;
    
    RETURN new_total;
END;
$$;

-- Function to get project-specific stats
CREATE OR REPLACE FUNCTION get_project_stats(p_project_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_stock_items', (SELECT COUNT(*) FROM stock_items WHERE project_id = p_project_id),
        'total_labour', (SELECT COUNT(*) FROM labour WHERE project_id = p_project_id AND status = 'active'),
        'material_inward', (
            SELECT COALESCE(SUM(quantity), 0) 
            FROM material_logs 
            WHERE project_id = p_project_id AND log_type = 'inward'
        ),
        'material_outward', (
            SELECT COALESCE(SUM(quantity), 0) 
            FROM material_logs 
            WHERE project_id = p_project_id AND log_type = 'outward'
        ),
        'pending_bills', (SELECT COUNT(*) FROM bills WHERE project_id = p_project_id AND status = 'pending'),
        'total_bill_amount', (
            SELECT COALESCE(SUM(amount), 0) 
            FROM bills 
            WHERE project_id = p_project_id AND status IN ('approved', 'paid')
        )
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION update_stock_quantity TO authenticated;
GRANT EXECUTE ON FUNCTION increment_machinery_hours TO authenticated;
GRANT EXECUTE ON FUNCTION get_project_stats TO authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
