-- ============================================================
-- MIGRATION 031: ADD MISSING COLUMNS
-- Adds missing columns to material_logs and stock_items
-- to support material operations code.
-- ============================================================

-- 1. MATERIAL LOGS MISSING COLUMNS
ALTER TABLE public.material_logs 
ADD COLUMN IF NOT EXISTS payment_type TEXT,
ADD COLUMN IF NOT EXISTS bill_amount DECIMAL(15, 2),
ADD COLUMN IF NOT EXISTS grade TEXT;

-- 2. STOCK ITEMS MISSING COLUMNS
-- 'grade' is used in get_or_create_stock_item RPC and Dart code
ALTER TABLE public.stock_items
ADD COLUMN IF NOT EXISTS grade TEXT;

-- 3. FIX PAYMENT TYPE VALUES (To match App Dropdown: Cash, Online, Cheque)
-- If there was a constraint (implicit or explicit), we normalize it.
-- We add a flexible constraint to allow both casing just in case, or match App.
ALTER TABLE public.material_logs DROP CONSTRAINT IF EXISTS material_logs_payment_type_check;

ALTER TABLE public.material_logs 
ADD CONSTRAINT material_logs_payment_type_check 
CHECK (payment_type IN ('Cash', 'Online', 'Cheque', 'cash', 'online', 'cheque', 'UPI', 'Bank Transfer'));

-- Notify schema reload
NOTIFY pgrst, 'reload schema';
