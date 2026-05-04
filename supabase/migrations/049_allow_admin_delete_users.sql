-- ============================================================
-- ALLOW ADMINS TO DELETE USER PROFILES
-- ============================================================

-- Drop the old policy that only allows super admins
DROP POLICY IF EXISTS "Super admins can delete profiles" ON public.user_profiles;
DROP POLICY IF EXISTS " Adminscan delete profiles" ON public.user_profiles;

-- Create the new policy allowing admins (and super admins) to delete profiles
CREATE POLICY "Admins can delete profiles"
    ON public.user_profiles FOR DELETE
    USING (public.is_admin_or_super());
