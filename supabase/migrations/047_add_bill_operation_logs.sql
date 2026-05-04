-- Extend operation_logs entity_type to support bills and notifications
ALTER TABLE public.operation_logs
  DROP CONSTRAINT IF EXISTS operation_logs_entity_type_check;

ALTER TABLE public.operation_logs
  ADD CONSTRAINT operation_logs_entity_type_check
  CHECK (entity_type IN ('project', 'stock', 'labour', 'blueprint', 'machinery', 'attendance', 'report', 'bill'));

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
