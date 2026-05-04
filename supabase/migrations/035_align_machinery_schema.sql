-- Migration 035: Align Machinery Logs Schema
-- User requires 'hours_used' and 'log_type' for usage logging.

-- 1. Add log_type
ALTER TABLE public.machinery_logs 
ADD COLUMN IF NOT EXISTS log_type TEXT DEFAULT 'usage';

-- 2. Add hours_used (User prefers this over total_hours for the log entry)
ALTER TABLE public.machinery_logs 
ADD COLUMN IF NOT EXISTS hours_used DECIMAL(10, 2);

-- 3. Ensure work_activity exists (It should from 023, but checking)
ALTER TABLE public.machinery_logs 
ADD COLUMN IF NOT EXISTS work_activity TEXT;

-- 4. Ensure total_hours exists on MACHINERY table (not logs) for the aggregate
-- (It should from 023/034)

NOTIFY pgrst, 'reload schema';
