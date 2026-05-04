-- ============================================================
-- MIGRATION 036: FIX SUPPLIERS PROJECT ISOLATION & CONSTRAINTS
-- ============================================================

-- 1. Add project_id to suppliers table
ALTER TABLE public.suppliers 
ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE;

-- 2. Add Unique Constraint to material_grades (Material + Grade Name)
ALTER TABLE public.material_grades
ADD CONSTRAINT uq_material_grade UNIQUE (material_id, grade_name);

-- 3. Update RLS Policies for Suppliers
-- First, drop existing policies that might conflict or be too broad
DROP POLICY IF EXISTS "Admins can manage suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Site managers can view suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Site managers can add suppliers" ON public.suppliers;

-- Re-create policies with strict project isolation
CREATE POLICY "Admins can manage suppliers"
ON public.suppliers FOR ALL
TO authenticated
USING (public.is_admin_or_super());

CREATE POLICY "Site managers can view project suppliers"
ON public.suppliers FOR SELECT
TO authenticated
USING (
    public.is_assigned_to_project(project_id)
    AND is_active = true
);

CREATE POLICY "Site managers can add project suppliers"
ON public.suppliers FOR INSERT
TO authenticated
WITH CHECK (
    public.is_assigned_to_project(project_id)
);

CREATE POLICY "Site managers can update project suppliers"
ON public.suppliers FOR UPDATE
TO authenticated
USING (public.is_assigned_to_project(project_id));

-- 4. Create Helper View for Material Dropdown (Optional but requested)
CREATE OR REPLACE VIEW public.v_project_material_dropdown AS
SELECT 
    s.id, 
    s.project_id, 
    s.name, 
    s.grade, 
    s.unit,
    s.quantity -- Current tracked quantity
FROM public.stock_items s
ORDER BY s.name;

GRANT SELECT ON public.v_project_material_dropdown TO authenticated;

-- 5. Create Helper View for Project Suppliers (Optional)
CREATE OR REPLACE VIEW public.v_project_suppliers_dropdown AS
SELECT
    id,
    project_id,
    name,
    category
FROM public.suppliers
WHERE is_active = true
ORDER BY name;

GRANT SELECT ON public.v_project_suppliers_dropdown TO authenticated;

-- Notify schema reload
NOTIFY pgrst, 'reload schema';
