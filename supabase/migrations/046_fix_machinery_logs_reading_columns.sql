-- Migration 046: Fix Machinery Logs Schema
-- Ensures reading columns exist and refreshes schema cache

-- Ensure start_reading and end_reading exist
ALTER TABLE public.machinery_logs 
ADD COLUMN IF NOT EXISTS start_reading DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS end_reading DECIMAL(10, 2);

-- Ensure execution_hours exists (calculated field)
ALTER TABLE public.machinery_logs 
ADD COLUMN IF NOT EXISTS execution_hours DECIMAL(10, 2);

-- Force schema cache reload
NOTIFY pgrst, 'reload schema';
