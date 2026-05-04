-- Ensure bills realtime uses full row data
ALTER TABLE public.bills REPLICA IDENTITY FULL;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
