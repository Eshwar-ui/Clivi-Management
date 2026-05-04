-- ============================================================
-- MIGRATION 017: SUPPLIERS TABLE
-- Vendor management for material procurement
-- ============================================================

-- ============================================================
-- PART 1: CREATE SUPPLIERS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    category TEXT CHECK (category IN ('Cement', 'Steel', 'Sand', 'Aggregate', 'Bricks', 'Electrical', 'Plumbing', 'Hardware', 'Other')),
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PART 2: RLS POLICIES FOR SUPPLIERS
-- ============================================================

-- Admins can do everything
CREATE POLICY "Admins can manage suppliers"
ON public.suppliers FOR ALL
TO authenticated
USING (public.is_admin_or_super())
WITH CHECK (public.is_admin_or_super());

-- Site managers can view suppliers
CREATE POLICY "Site managers can view suppliers"
ON public.suppliers FOR SELECT
TO authenticated
USING (
    public.get_my_role() = 'site_manager'
    AND is_active = true
);

-- Site managers can add suppliers
CREATE POLICY "Site managers can add suppliers"
ON public.suppliers FOR INSERT
TO authenticated
WITH CHECK (public.get_my_role() = 'site_manager');

-- ============================================================
-- PART 3: ADD SUPPLIER_ID TO MATERIAL_LOGS
-- ============================================================

ALTER TABLE public.material_logs 
ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL;

-- Create index for supplier lookup
CREATE INDEX IF NOT EXISTS idx_material_logs_supplier 
ON public.material_logs(supplier_id);

-- ============================================================
-- PART 4: INDEXES FOR SUPPLIERS
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_suppliers_name ON public.suppliers(name);
CREATE INDEX IF NOT EXISTS idx_suppliers_category ON public.suppliers(category);
CREATE INDEX IF NOT EXISTS idx_suppliers_is_active ON public.suppliers(is_active);

-- ============================================================
-- PART 5: UPDATED_AT TRIGGER
-- ============================================================

DROP TRIGGER IF EXISTS update_suppliers_updated_at ON public.suppliers;
CREATE TRIGGER update_suppliers_updated_at
    BEFORE UPDATE ON public.suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- MIGRATION COMPLETE
-- Run in Supabase SQL Editor
-- ============================================================
