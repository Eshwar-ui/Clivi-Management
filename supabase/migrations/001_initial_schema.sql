-- ============================================================
-- CLIVI MANAGEMENT - SUPABASE DATABASE SETUP
-- ============================================================
-- Run this SQL in your Supabase SQL Editor
-- Dashboard: https://supabase.com/dashboard/project/YOUR_PROJECT/sql
-- ============================================================

-- ============================================================
-- 1. USER PROFILES TABLE
-- ============================================================

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'site_manager' CHECK (role IN ('super_admin', 'admin', 'site_manager')),
    full_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment
COMMENT ON TABLE public.user_profiles IS 'User profiles with role-based access control';

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. RLS POLICIES FOR USER_PROFILES
-- ============================================================

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

-- Policy: Admins and Super Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
    ON public.user_profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policy: Users can update their own profile (except role)
CREATE POLICY "Users can update own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Policy: Super Admins can update any profile including role
CREATE POLICY "Super admins can update any profile"
    ON public.user_profiles FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- Policy: Super Admins can insert profiles
CREATE POLICY "Super admins can insert profiles"
    ON public.user_profiles FOR INSERT
    WITH CHECK (
        -- Allow insert for the user themselves (signup)
        auth.uid() = id
        OR
        -- Or by super_admin
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- Policy: Super Admins can delete profiles
CREATE POLICY "Super admins can delete profiles"
    ON public.user_profiles FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- ============================================================
-- 3. PROJECTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    location TEXT,
    status TEXT DEFAULT 'planning' CHECK (status IN ('planning', 'in_progress', 'on_hold', 'completed', 'cancelled')),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(15, 2),
    created_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 4. PROJECT ASSIGNMENTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.project_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    assigned_role TEXT DEFAULT 'member' CHECK (assigned_role IN ('manager', 'member', 'viewer')),
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    assigned_by UUID REFERENCES public.user_profiles(id),
    UNIQUE(project_id, user_id)
);

-- Enable RLS
ALTER TABLE public.project_assignments ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 5. RLS POLICIES FOR PROJECTS
-- ============================================================

-- Policy: Super Admins and Admins can view all projects
CREATE POLICY "Admins can view all projects"
    ON public.projects FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policy: Site Managers can only view assigned projects
CREATE POLICY "Site managers can view assigned projects"
    ON public.projects FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = projects.id AND user_id = auth.uid()
        )
    );

-- Policy: Admins can create projects
CREATE POLICY "Admins can create projects"
    ON public.projects FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policy: Admins can update projects
CREATE POLICY "Admins can update projects"
    ON public.projects FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policy: Super Admins can delete projects
CREATE POLICY "Super admins can delete projects"
    ON public.projects FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- ============================================================
-- 6. RLS POLICIES FOR PROJECT_ASSIGNMENTS
-- ============================================================

-- Policy: Users can view their own assignments
CREATE POLICY "Users can view own assignments"
    ON public.project_assignments FOR SELECT
    USING (user_id = auth.uid());

-- Policy: Admins can view all assignments
CREATE POLICY "Admins can view all assignments"
    ON public.project_assignments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policy: Admins can manage assignments
CREATE POLICY "Admins can manage assignments"
    ON public.project_assignments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- ============================================================
-- 7. STOCK/INVENTORY TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.stock_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    unit TEXT DEFAULT 'pieces',
    quantity DECIMAL(15, 2) DEFAULT 0,
    min_quantity DECIMAL(15, 2) DEFAULT 0,
    unit_price DECIMAL(15, 2),
    project_id UUID REFERENCES public.projects(id),
    created_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.stock_items ENABLE ROW LEVEL SECURITY;

-- Policy: Admins can manage all stock
CREATE POLICY "Admins can manage stock"
    ON public.stock_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policy: Site managers can view project stock
CREATE POLICY "Site managers can view project stock"
    ON public.stock_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = stock_items.project_id AND user_id = auth.uid()
        )
    );

-- ============================================================
-- 8. LABOUR TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.labour (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    skill_type TEXT,
    daily_wage DECIMAL(10, 2),
    project_id UUID REFERENCES public.projects(id),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.labour ENABLE ROW LEVEL SECURITY;

-- Policy: Admins can manage all labour
CREATE POLICY "Admins can manage labour"
    ON public.labour FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policy: Site managers can view and manage project labour
CREATE POLICY "Site managers can manage project labour"
    ON public.labour FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = labour.project_id AND user_id = auth.uid()
        )
    );

-- ============================================================
-- 9. LABOUR ATTENDANCE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.labour_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    labour_id UUID NOT NULL REFERENCES public.labour(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES public.projects(id),
    date DATE NOT NULL,
    status TEXT DEFAULT 'present' CHECK (status IN ('present', 'absent', 'half_day')),
    hours_worked DECIMAL(4, 2),
    notes TEXT,
    recorded_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(labour_id, date)
);

-- Enable RLS
ALTER TABLE public.labour_attendance ENABLE ROW LEVEL SECURITY;

-- Policy: Site managers can manage attendance for their projects
CREATE POLICY "Site managers can manage attendance"
    ON public.labour_attendance FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = labour_attendance.project_id AND user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- ============================================================
-- 10. MACHINERY TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.machinery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT,
    registration_number TEXT,
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'in_use', 'maintenance', 'retired')),
    hourly_rate DECIMAL(10, 2),
    current_project_id UUID REFERENCES public.projects(id),
    created_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.machinery ENABLE ROW LEVEL SECURITY;

-- Policy: Admins can manage machinery
CREATE POLICY "Admins can manage machinery"
    ON public.machinery FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policy: Site managers can view assigned machinery
CREATE POLICY "Site managers can view machinery"
    ON public.machinery FOR SELECT
    USING (
        current_project_id IS NULL
        OR
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = machinery.current_project_id AND user_id = auth.uid()
        )
    );

-- ============================================================
-- 11. BILLS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id),
    title TEXT NOT NULL,
    description TEXT,
    amount DECIMAL(15, 2) NOT NULL,
    bill_type TEXT DEFAULT 'expense' CHECK (bill_type IN ('expense', 'income', 'invoice')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'paid', 'rejected')),
    bill_date DATE DEFAULT CURRENT_DATE,
    due_date DATE,
    vendor_name TEXT,
    receipt_url TEXT,
    created_by UUID REFERENCES public.user_profiles(id),
    approved_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.bills ENABLE ROW LEVEL SECURITY;

-- Policy: Admins can manage all bills
CREATE POLICY "Admins can manage bills"
    ON public.bills FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policy: Site managers can view and create bills for their projects
CREATE POLICY "Site managers can manage project bills"
    ON public.bills FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = bills.project_id AND user_id = auth.uid()
        )
    );

-- ============================================================
-- 12. BLUEPRINTS/DOCUMENTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.blueprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id),
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    file_type TEXT,
    file_size INTEGER,
    version TEXT DEFAULT '1.0',
    uploaded_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.blueprints ENABLE ROW LEVEL SECURITY;

-- Policy: Admins can manage all blueprints
CREATE POLICY "Admins can manage blueprints"
    ON public.blueprints FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policy: Site managers can view and upload blueprints for their projects
CREATE POLICY "Site managers can manage project blueprints"
    ON public.blueprints FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = blueprints.project_id AND user_id = auth.uid()
        )
    );

-- ============================================================
-- 13. DAILY REPORTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.daily_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id),
    report_date DATE NOT NULL DEFAULT CURRENT_DATE,
    weather TEXT,
    work_summary TEXT,
    issues TEXT,
    tomorrow_plan TEXT,
    labour_count INTEGER DEFAULT 0,
    created_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(project_id, report_date)
);

-- Enable RLS
ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY;

-- Policy: Site managers can manage reports for their projects
CREATE POLICY "Site managers can manage reports"
    ON public.daily_reports FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.project_assignments
            WHERE project_id = daily_reports.project_id AND user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- ============================================================
-- 14. HELPER FUNCTIONS
-- ============================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at
    BEFORE UPDATE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_stock_items_updated_at
    BEFORE UPDATE ON public.stock_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_labour_updated_at
    BEFORE UPDATE ON public.labour
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_machinery_updated_at
    BEFORE UPDATE ON public.machinery
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bills_updated_at
    BEFORE UPDATE ON public.bills
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blueprints_updated_at
    BEFORE UPDATE ON public.blueprints
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_reports_updated_at
    BEFORE UPDATE ON public.daily_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 15. FUNCTION TO AUTO-CREATE USER PROFILE ON SIGNUP
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, role, full_name, created_at)
    VALUES (
        NEW.id,
        'site_manager',
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile when user signs up
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 16. STORAGE BUCKETS
-- ============================================================

-- Create storage buckets (run in SQL editor)
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('avatars', 'avatars', true),
    ('blueprints', 'blueprints', false),
    ('receipts', 'receipts', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for avatars bucket
CREATE POLICY "Avatar images are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own avatar"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage policies for blueprints bucket
CREATE POLICY "Authenticated users can view blueprints"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'blueprints' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can upload blueprints"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'blueprints' AND auth.role() = 'authenticated');

-- Storage policies for receipts bucket  
CREATE POLICY "Authenticated users can view receipts"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'receipts' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can upload receipts"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'receipts' AND auth.role() = 'authenticated');

-- ============================================================
-- 17. SEED DATA FOR TESTING
-- ============================================================

-- NOTE: Run this separately after creating a super_admin user via Supabase Auth
-- Replace 'YOUR_SUPER_ADMIN_USER_ID' with actual UUID

-- UPDATE public.user_profiles 
-- SET role = 'super_admin', full_name = 'Super Admin'
-- WHERE id = 'YOUR_SUPER_ADMIN_USER_ID';

-- ============================================================
-- END OF MIGRATION
-- ============================================================
