-- Migration: Reports Schema
-- Description: Adds views and functions for the Insights/Reports module

-- ============================================================
-- 1. Financial Summary View
-- Aggregates approved expenses by month and project
-- ============================================================

CREATE OR REPLACE VIEW public.v_financial_summary AS
SELECT
    DATE_TRUNC('month', created_at)::DATE AS period,
    project_id,
    bill_type,
    SUM(amount) AS total_amount
FROM
    public.bills
WHERE
    status IN ('approved', 'paid')
GROUP BY
    1, 2, 3;

-- ============================================================
-- 2. Resource Usage View
-- Aggregates costs by resource type (Labor, Material, Machinery)
-- ============================================================

CREATE OR REPLACE VIEW public.v_resource_usage AS
SELECT
    project_id,
    bill_type AS resource_type,
    SUM(amount) AS total_cost
FROM
    public.bills
WHERE
    status IN ('approved', 'paid')
GROUP BY
    1, 2;

-- ============================================================
-- 3. Get Financial Metrics RPC
-- Returns aggregated stats for charts and cards
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_financial_metrics(
    p_period TEXT DEFAULT 'monthly', -- 'monthly', 'quarterly', 'yearly'
    p_project_id_text TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_project_id UUID := NULL;
    v_start_date DATE;
    v_prev_start_date DATE;
    v_end_date DATE := CURRENT_DATE;
    
    v_total_expenses DECIMAL := 0;
    v_prev_total_expenses DECIMAL := 0;
    v_growth_rate DECIMAL := 0;
    
    v_labor_cost DECIMAL := 0;
    v_material_cost DECIMAL := 0;
    v_machinery_cost DECIMAL := 0;
    v_other_cost DECIMAL := 0;
    
    v_chart_data JSON;
BEGIN
    -- Cast project_id from text to UUID if provided
    IF p_project_id_text IS NOT NULL THEN
        p_project_id := p_project_id_text::UUID;
    END IF;

    -- Determine date range based on period
    CASE p_period
        WHEN 'yearly' THEN
            v_start_date := DATE_TRUNC('year', CURRENT_DATE);
            v_prev_start_date := DATE_TRUNC('year', CURRENT_DATE - INTERVAL '1 year');
        WHEN 'quarterly' THEN
            v_start_date := DATE_TRUNC('quarter', CURRENT_DATE);
            v_prev_start_date := DATE_TRUNC('quarter', CURRENT_DATE - INTERVAL '3 months');
        ELSE -- monthly
            v_start_date := DATE_TRUNC('month', CURRENT_DATE);
            v_prev_start_date := DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month');
    END CASE;

    -- Calculate Totals
    SELECT COALESCE(SUM(amount), 0) INTO v_total_expenses
    FROM public.bills
    WHERE status IN ('approved', 'paid')
    AND created_at >= v_start_date
    AND (p_project_id IS NULL OR project_id = p_project_id);

    -- Calculate Previous Period Totals (for Growth %)
    SELECT COALESCE(SUM(amount), 0) INTO v_prev_total_expenses
    FROM public.bills
    WHERE status IN ('approved', 'paid')
    AND created_at >= v_prev_start_date
    AND created_at < v_start_date
    AND (p_project_id IS NULL OR project_id = p_project_id);

    -- Calculate Growth %
    IF v_prev_total_expenses > 0 THEN
        v_growth_rate := ((v_total_expenses - v_prev_total_expenses) / v_prev_total_expenses) * 100;
    ELSE
        v_growth_rate := 0;
    END IF;

    -- Calculate Resource Split
    SELECT 
        COALESCE(SUM(CASE WHEN bill_type = 'labour' THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN bill_type = 'material' THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN bill_type = 'machinery' THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN bill_type NOT IN ('labour', 'material', 'machinery') THEN amount ELSE 0 END), 0)
    INTO v_labor_cost, v_material_cost, v_machinery_cost, v_other_cost
    FROM public.bills
    WHERE status IN ('approved', 'paid')
    AND (p_project_id IS NULL OR project_id = p_project_id);

    -- Get Chart Data (Expenses over time)
    -- Grouping depends on selected period
    WITH chart_series AS (
        SELECT
            TO_CHAR(created_at, CASE 
                WHEN p_period = 'yearly' THEN 'Mon' 
                ELSE 'DD Mon' 
            END) AS label,
            SUM(amount) as value,
            MIN(created_at) as sort_date
        FROM public.bills
        WHERE status IN ('approved', 'paid')
        AND created_at >= CASE 
            WHEN p_period = 'yearly' THEN DATE_TRUNC('year', CURRENT_DATE)
            ELSE DATE_TRUNC('month', CURRENT_DATE - INTERVAL '6 months') -- Show last 6 months trend for monthly view
        END
        AND (p_project_id IS NULL OR project_id = p_project_id)
        GROUP BY 1
        ORDER BY MIN(created_at)
    )
    SELECT json_agg(row_to_json(chart_series)) INTO v_chart_data FROM chart_series;

    -- Return Result
    RETURN json_build_object(
        'total_expenses', v_total_expenses,
        'growth_percentage', ROUND(v_growth_rate, 1),
        'labor_cost', v_labor_cost,
        'material_cost', v_material_cost,
        'machinery_cost', v_machinery_cost,
        'other_cost', v_other_cost,
        'chart_data', COALESCE(v_chart_data, '[]'::json)
    );
END;
$$;
