-- ============================================================
-- SEED ADMIN USERS FOR CLIVI MANAGEMENT
-- ============================================================
-- This script creates Super Admin and Admin users
-- 
-- IMPORTANT: Run these steps in order:
-- 1. First, create the users in Supabase Auth Dashboard OR via API
-- 2. Then run the user_profiles INSERT below
-- ============================================================

-- ============================================================
-- OPTION 1: Create Users via Supabase Dashboard
-- ============================================================
-- Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/auth/users
-- Click "Add user" -> "Create new user"
-- 
-- USER 1 (Super Admin):
--   Email: admin@gmail.com
--   Password: Admin12345
--   Email Confirm: ON (toggle to confirm automatically)
--
-- USER 2 (Admin):
--   Email: admin@gmail.com  (same email - create a second account with different email)
--   OR create a different admin like: admin2@gmail.com / Admin12345
-- ============================================================

-- ============================================================
-- OPTION 2: Create Users via Supabase SQL (Service Role Required)
-- ============================================================
-- NOTE: This requires running with service_role key privileges
-- These will NOT work in client-side code - only in Supabase SQL Editor
-- with proper permissions or via Supabase Admin API

-- For creating users programmatically, use Supabase Admin API:
/*
-- Using Supabase JavaScript Admin Client:

const { createClient } = require('@supabase/supabase-js');

const supabaseAdmin = createClient(
  'YOUR_SUPABASE_URL',
  'YOUR_SERVICE_ROLE_KEY' // NOT the anon key
);

// Create Super Admin
const { data: superAdmin, error: superAdminError } = await supabaseAdmin.auth.admin.createUser({
  email: 'superadmin@gmail.com',
  password: 'Admin12345',
  email_confirm: true,
  user_metadata: {
    full_name: 'Super Admin'
  }
});

// Create Admin
const { data: admin, error: adminError } = await supabaseAdmin.auth.admin.createUser({
  email: 'admin@gmail.com', 
  password: 'Admin12345',
  email_confirm: true,
  user_metadata: {
    full_name: 'Admin User'
  }
});

console.log('Super Admin ID:', superAdmin.user.id);
console.log('Admin ID:', admin.user.id);
*/

-- ============================================================
-- STEP 2: Update User Profiles (After Users Exist in Auth)
-- ============================================================
-- Replace the UUIDs below with the actual UUIDs from auth.users
-- You can find them in Supabase Dashboard -> Authentication -> Users

-- Get user IDs from auth.users table
-- SELECT id, email FROM auth.users WHERE email IN ('superadmin@gmail.com', 'admin@gmail.com');

-- Update Super Admin role
UPDATE public.user_profiles 
SET 
    role = 'super_admin',
    full_name = 'Super Admin',
    updated_at = NOW()
WHERE id = (SELECT id FROM auth.users WHERE email = 'superadmin@gmail.com' LIMIT 1);

-- Update Admin role
UPDATE public.user_profiles 
SET 
    role = 'admin',
    full_name = 'Admin User',
    updated_at = NOW()
WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@gmail.com' LIMIT 1);

-- ============================================================
-- ALTERNATIVE: Direct Insert (if user_profile not auto-created)
-- ============================================================
-- If the trigger didn't create the profile, insert manually:

-- INSERT INTO public.user_profiles (id, role, full_name, created_at)
-- SELECT id, 'super_admin', 'Super Admin', NOW()
-- FROM auth.users WHERE email = 'superadmin@gmail.com'
-- ON CONFLICT (id) DO UPDATE SET role = 'super_admin', full_name = 'Super Admin';

-- INSERT INTO public.user_profiles (id, role, full_name, created_at)
-- SELECT id, 'admin', 'Admin User', NOW()
-- FROM auth.users WHERE email = 'admin@gmail.com'
-- ON CONFLICT (id) DO UPDATE SET role = 'admin', full_name = 'Admin User';

-- ============================================================
-- VERIFICATION QUERY
-- ============================================================
-- Run this to verify the users were created correctly:
-- SELECT up.id, u.email, up.role, up.full_name 
-- FROM public.user_profiles up
-- JOIN auth.users u ON u.id = up.id
-- WHERE up.role IN ('super_admin', 'admin');

-- ============================================================
-- END OF MIGRATION
-- ============================================================
