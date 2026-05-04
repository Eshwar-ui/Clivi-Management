-- Add optional labour_id to daily_labour_logs for linking master labour
ALTER TABLE public.daily_labour_logs
ADD COLUMN IF NOT EXISTS labour_id UUID REFERENCES public.labour(id);

-- Index for lookups by labour/project
CREATE INDEX IF NOT EXISTS idx_daily_labour_logs_labour ON public.daily_labour_logs(labour_id);
CREATE INDEX IF NOT EXISTS idx_daily_labour_logs_project ON public.daily_labour_logs(project_id);
