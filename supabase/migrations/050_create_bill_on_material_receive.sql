-- ============================================================
-- Migration 050: Create Bill On Material Receive
-- ============================================================
-- Modifies the receive_material RPC to automatically create a bill
-- linked to the specific project and vendor.
-- ============================================================

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
    v_bill_id UUID;
    v_user_id UUID := auth.uid();
    v_grade TEXT := NULLIF(TRIM(p_grade), '');
    v_vendor_name TEXT;
    v_bill_title TEXT;
    v_bill_description TEXT;
BEGIN
    -- 0) Get Vendor Name
    SELECT name INTO v_vendor_name
    FROM public.suppliers
    WHERE id = p_supplier_id;

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

    -- 3) Create associated auto-bill
    IF v_grade IS NOT NULL THEN
        v_bill_title := 'Material Receive: ' || TRIM(p_material_name) || ' (' || v_grade || ')';
    ELSE
        v_bill_title := 'Material Receive: ' || TRIM(p_material_name);
    END IF;

    v_bill_description := 'Quantity: ' || p_quantity::TEXT || ' ' || p_unit || ', Vendor: ' || v_vendor_name;
    IF p_notes IS NOT NULL THEN
        v_bill_description := v_bill_description || ', Notes: ' || p_notes;
    END IF;

    -- Map Flutter payment types to DB constraint ('cash', 'upi', 'bank_transfer', 'cheque')
    DECLARE
        v_payment_type TEXT := LOWER(p_payment_type);
    BEGIN
        IF v_payment_type = 'online' THEN
            v_payment_type := 'bank_transfer';
        ELSIF v_payment_type NOT IN ('cash', 'upi', 'bank_transfer', 'cheque') THEN
            v_payment_type := 'cash'; -- default fallback
        END IF;

        INSERT INTO public.bills (
            project_id, 
            title, 
            description, 
            amount, 
            bill_type, 
            status, 
            bill_date, 
            created_by,
            raised_by,
            uploaded_by,
            payment_type,
            payment_status
        ) VALUES (
            p_project_id,
            v_bill_title,
            v_bill_description,
            p_bill_amount,
            'materials',  -- defined in enum/check constraint
            'pending',  
            CURRENT_DATE,
            v_user_id,
            v_user_id,
            v_user_id,
            v_payment_type,
            'need_to_pay'
        ) RETURNING id INTO v_bill_id;
    END;

    -- 4) Update vendor materials (unchanged)
    INSERT INTO public.vendor_materials (project_id, supplier_id, material_name, grade, last_used_at)
    VALUES (p_project_id, p_supplier_id, TRIM(p_material_name), v_grade, NOW())
    ON CONFLICT ON CONSTRAINT uq_vendor_materials_unique
    DO UPDATE SET last_used_at = NOW();

    -- 5) Also update price tracking since we have bill amount
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
