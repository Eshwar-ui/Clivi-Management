-- Migration 034: Fix Machinery Schema
-- It appears 'registration_no' is missing from the table, likely because the table 
-- existed before migration 023 was applied, causing the IF NOT EXISTS to skip creation.

ALTER TABLE public.machinery 
ADD COLUMN IF NOT EXISTS registration_no TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS type TEXT;

-- Verify ownership_type is there too (was added in 032, but good to be safe)
ALTER TABLE public.machinery 
ADD COLUMN IF NOT EXISTS ownership_type TEXT CHECK (ownership_type IN ('Own', 'Rental', 'own', 'rental'));

-- Reload schema cache ensuring Supabase picks up the changes
NOTIFY pgrst, 'reload schema';
