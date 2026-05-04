-- ============================================================
-- MIGRATION 039: FIX PAYMENT TYPE CONSTRAINT
-- ============================================================

-- The previous constraint missed 'Credit', which is used in the UI.
-- We drop and recreate the constraint with the correct values.

ALTER TABLE public.material_logs 
DROP CONSTRAINT IF EXISTS material_logs_payment_type_check;

ALTER TABLE public.material_logs 
ADD CONSTRAINT material_logs_payment_type_check 
CHECK (payment_type IN (
    'Cash', 
    'Online', 
    'Cheque', 
    'Credit',       -- Added
    'UPI', 
    'Bank Transfer',
    'cash', 
    'online', 
    'cheque', 
    'credit'        -- Added lowercase just in case
));

-- Notify schema reload
NOTIFY pgrst, 'reload schema';
