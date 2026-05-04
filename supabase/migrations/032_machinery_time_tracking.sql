-- ============================================================
-- MIGRATION 032: MACHINERY TIME TRACKING & UPDATES
-- Adds support for time-based logging and ownership type
-- ============================================================

-- 1. Update machinery_logs table
-- We make reading columns nullable because new logs might only use time
ALTER TABLE public.machinery_logs
ALTER COLUMN start_reading DROP NOT NULL,
ALTER COLUMN end_reading DROP NOT NULL;

-- Add new columns for time-based tracking
ALTER TABLE public.machinery_logs
ADD COLUMN IF NOT EXISTS log_date DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS start_time TIME,
ADD COLUMN IF NOT EXISTS end_time TIME,
ADD COLUMN IF NOT EXISTS total_hours DECIMAL(10, 2);

-- 2. Update machinery table
-- Add ownership_type as requested
ALTER TABLE public.machinery
ADD COLUMN IF NOT EXISTS ownership_type TEXT CHECK (ownership_type IN ('Own', 'Rental', 'own', 'rental'));

-- 3. Indexes for new columns
CREATE INDEX IF NOT EXISTS idx_machinery_logs_date ON public.machinery_logs(log_date);

-- 4. Validation Trigger (Start Time < End Time)
CREATE OR REPLACE FUNCTION public.validate_machinery_time()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.start_time IS NOT NULL AND NEW.end_time IS NOT NULL THEN
    IF NEW.end_time <= NEW.start_time THEN
      RAISE EXCEPTION 'End Time must be after Start Time';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validate_machinery_time ON public.machinery_logs;
CREATE TRIGGER trigger_validate_machinery_time
  BEFORE INSERT OR UPDATE ON public.machinery_logs
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_machinery_time();

-- 5. Helper RPC to increment machinery total hours
CREATE OR REPLACE FUNCTION public.increment_machinery_hours(
  p_machinery_id UUID,
  p_hours DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
  v_new_total DECIMAL;
  v_current_total DECIMAL;
BEGIN
  SELECT total_hours INTO v_current_total FROM public.machinery WHERE id = p_machinery_id;
  
  v_new_total := COALESCE(v_current_total, 0) + p_hours;
  
  UPDATE public.machinery
  SET total_hours = v_new_total
  WHERE id = p_machinery_id;
  
  RETURN v_new_total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Notify schema reload
NOTIFY pgrst, 'reload schema';
