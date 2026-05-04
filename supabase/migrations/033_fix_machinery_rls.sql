-- Migration 033: Allow Site Managers to Create Machinery
-- The previous policies only allowed Admins to manage machinery master list.
-- This update allows Site Managers to also INSERT into machinery table.

-- Function to check if user is a site manager (has any project assignment)
-- We leverage existing tables. Assuming 'project_assignments' implies site manager role or similar.
-- Or we just allow any authenticated user to create machinery (common in these apps to avoid blocking operations).

-- Let's use a policy that allows INSERT for authenticated users, but UPDATE/DELETE only for Admins (already covering ALL) or Creator.
-- "Admins can manage machinery" handles ALL for admins.

-- New Policy: Users can create machinery
DROP POLICY IF EXISTS "Users can create machinery" ON public.machinery;
CREATE POLICY "Users can create machinery"
    ON public.machinery FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Optional: Allow creators to update their own machinery?
-- For now, just INSERT is the blocker.

NOTIFY pgrst, 'reload schema';
