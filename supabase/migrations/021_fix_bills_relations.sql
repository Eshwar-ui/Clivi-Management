-- ============================================================
-- FIX BILLS TABLE RELATIONSHIPS AND RLS
-- ============================================================

-- Step 1: Ensure bills table has correct foreign keys
DO $$
BEGIN
    -- Drop existing constraints if they exist (to recreate properly)
    ALTER TABLE public.bills DROP CONSTRAINT IF EXISTS bills_created_by_fkey;
    ALTER TABLE public.bills DROP CONSTRAINT IF EXISTS bills_created_by_fkey1;
    ALTER TABLE public.bills DROP CONSTRAINT IF EXISTS bills_approved_by_fkey;
    ALTER TABLE public.bills DROP CONSTRAINT IF EXISTS bills_approved_by_fkey1;
    ALTER TABLE public.bills DROP CONSTRAINT IF EXISTS bills_project_id_fkey;
    
    -- Recreate with proper references
    ALTER TABLE public.bills 
        ADD CONSTRAINT bills_project_id_fkey 
        FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;
    
    ALTER TABLE public.bills 
        ADD CONSTRAINT bills_created_by_fkey 
        FOREIGN KEY (created_by) REFERENCES public.user_profiles(id) ON DELETE SET NULL;
    
    ALTER TABLE public.bills 
        ADD CONSTRAINT bills_approved_by_fkey 
        FOREIGN KEY (approved_by) REFERENCES public.user_profiles(id) ON DELETE SET NULL;
        
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error updating constraints: %', SQLERRM;
END $$;

-- Step 2: Add missing columns if they don't exist
DO $$
BEGIN
    -- Add raised_by column (maps to created_by conceptually)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bills' AND column_name = 'raised_by'
    ) THEN
        ALTER TABLE public.bills ADD COLUMN raised_by UUID REFERENCES public.user_profiles(id);
    END IF;
    
    -- Add bill_type variations needed by the app
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bills' AND column_name = 'payment_type'
    ) THEN
        ALTER TABLE public.bills ADD COLUMN payment_type TEXT 
            CHECK (payment_type IN ('cash', 'upi', 'bank_transfer', 'cheque'));
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bills' AND column_name = 'payment_status'
    ) THEN
        ALTER TABLE public.bills ADD COLUMN payment_status TEXT DEFAULT 'need_to_pay'
            CHECK (payment_status IN ('need_to_pay', 'advance', 'half_paid', 'full_paid'));
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bills' AND column_name = 'approved_at'
    ) THEN
        ALTER TABLE public.bills ADD COLUMN approved_at TIMESTAMPTZ;
    END IF;
END $$;

-- Step 3: Update bill_type constraint to match app requirements
ALTER TABLE public.bills DROP CONSTRAINT IF EXISTS bills_bill_type_check;
ALTER TABLE public.bills ADD CONSTRAINT bills_bill_type_check 
    CHECK (bill_type IN ('workers', 'materials', 'transport', 'equipment_rent', 'expense', 'income', 'invoice'));

-- Step 4: Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_bills_project_id ON public.bills(project_id);
CREATE INDEX IF NOT EXISTS idx_bills_created_by ON public.bills(created_by);
CREATE INDEX IF NOT EXISTS idx_bills_status ON public.bills(status);
CREATE INDEX IF NOT EXISTS idx_bills_created_at ON public.bills(created_at DESC);

-- Step 5: Fix RLS Policies for Bills
ALTER TABLE public.bills ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage bills" ON public.bills;
DROP POLICY IF EXISTS "Site managers can manage project bills" ON public.bills;
DROP POLICY IF EXISTS "Strict Project Isolation for Bills" ON public.bills;

-- Admins can do everything
CREATE POLICY "Admins can manage all bills"
    ON public.bills FOR ALL
    USING (public.is_admin_or_super())
    WITH CHECK (public.is_admin_or_super());

-- Site managers can view bills for their assigned projects
CREATE POLICY "Site managers can view project bills"
    ON public.bills FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = bills.project_id AND user_id = auth.uid()
        )
    );

-- Site managers can create bills for their assigned projects
CREATE POLICY "Site managers can create project bills"
    ON public.bills FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = bills.project_id AND user_id = auth.uid()
        )
    );

-- Site managers can update their own pending bills
CREATE POLICY "Site managers can update own pending bills"
    ON public.bills FOR UPDATE
    USING (
        status = 'pending' AND
        created_by = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = bills.project_id AND user_id = auth.uid()
        )
    );

-- Step 6: IMPORTANT - Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
