-- ============================================================
-- DEMO 04: VERIFY DEMO DATA
-- ============================================================
-- Run after DEMO_03_SEED_FULL_DEMO.sql
-- ============================================================

-- ------------------------------------------------------------
-- 1) Core row counts
-- ------------------------------------------------------------
SELECT 'projects' AS section, COUNT(*)::bigint AS total FROM public.projects
UNION ALL SELECT 'project_assignments', COUNT(*)::bigint FROM public.project_assignments
UNION ALL SELECT 'suppliers', COUNT(*)::bigint FROM public.suppliers
UNION ALL SELECT 'stock_items', COUNT(*)::bigint FROM public.stock_items
UNION ALL SELECT 'material_logs', COUNT(*)::bigint FROM public.material_logs
UNION ALL SELECT 'machinery', COUNT(*)::bigint FROM public.machinery
UNION ALL SELECT 'machinery_logs', COUNT(*)::bigint FROM public.machinery_logs
UNION ALL SELECT 'labour', COUNT(*)::bigint FROM public.labour
UNION ALL SELECT 'labour_attendance', COUNT(*)::bigint FROM public.labour_attendance
UNION ALL SELECT 'daily_labour_logs', COUNT(*)::bigint FROM public.daily_labour_logs
UNION ALL SELECT 'bills', COUNT(*)::bigint FROM public.bills
UNION ALL SELECT 'operation_logs', COUNT(*)::bigint FROM public.operation_logs
ORDER BY section;

-- ------------------------------------------------------------
-- 2) Projects + assigned site managers
-- ------------------------------------------------------------
SELECT
  p.name AS project_name,
  p.status,
  COALESCE((to_jsonb(p)->>'progress')::int, 0) AS progress,
  COUNT(pa.user_id)::int AS assigned_managers,
  STRING_AGG(COALESCE(up.full_name, up.email, pa.user_id::text), ', ' ORDER BY up.full_name) AS manager_names
FROM public.projects p
LEFT JOIN public.project_assignments pa ON pa.project_id = p.id
LEFT JOIN public.user_profiles up ON up.id = pa.user_id
GROUP BY p.id, p.name, p.status
ORDER BY p.created_at;

-- ------------------------------------------------------------
-- 3) Vendor coverage (Steel/Cement tabs sanity)
-- ------------------------------------------------------------
SELECT
  LOWER(COALESCE(si.category, 'unknown')) AS material_category,
  LOWER(COALESCE(s.category, 'unknown')) AS supplier_category,
  s.name AS vendor_name,
  COUNT(*)::int AS inward_entries,
  ROUND(SUM(COALESCE(ml.quantity, 0))::numeric, 2) AS total_quantity,
  ROUND(SUM(COALESCE(ml.bill_amount, 0))::numeric, 2) AS total_amount
FROM public.material_logs ml
JOIN public.stock_items si ON si.id = ml.item_id
LEFT JOIN public.suppliers s ON s.id = ml.supplier_id
WHERE ml.log_type = 'inward'
GROUP BY LOWER(COALESCE(si.category, 'unknown')), LOWER(COALESCE(s.category, 'unknown')), s.name
ORDER BY material_category, total_amount DESC;

-- ------------------------------------------------------------
-- 4) Material stock vs inward/outward summary
-- ------------------------------------------------------------
SELECT
  p.name AS project_name,
  si.name AS material_name,
  COALESCE(si.grade, '-') AS grade,
  si.unit,
  ROUND(COALESCE(inward.total_inward, 0)::numeric, 2) AS inward_qty,
  ROUND(COALESCE(outward.total_outward, 0)::numeric, 2) AS outward_qty,
  ROUND(COALESCE(si.quantity, 0)::numeric, 2) AS current_stock
FROM public.stock_items si
JOIN public.projects p ON p.id = si.project_id
LEFT JOIN (
  SELECT item_id, SUM(quantity) AS total_inward
  FROM public.material_logs
  WHERE log_type = 'inward'
  GROUP BY item_id
) inward ON inward.item_id = si.id
LEFT JOIN (
  SELECT item_id, SUM(quantity) AS total_outward
  FROM public.material_logs
  WHERE log_type = 'outward'
  GROUP BY item_id
) outward ON outward.item_id = si.id
ORDER BY p.name, si.name, si.grade;

-- ------------------------------------------------------------
-- 5) Machinery utilisation by project
-- ------------------------------------------------------------
SELECT
  p.name AS project_name,
  m.name AS machine_name,
  m.type,
  COUNT(ml.id)::int AS log_count,
  ROUND(
    SUM(
      COALESCE(
        (to_jsonb(ml)->>'hours_used')::numeric,
        COALESCE((to_jsonb(ml)->>'end_reading')::numeric, 0) - COALESCE((to_jsonb(ml)->>'start_reading')::numeric, 0)
      )
    )::numeric,
    2
  ) AS total_hours
FROM public.machinery_logs ml
JOIN public.machinery m ON m.id = ml.machinery_id
JOIN public.projects p ON p.id = ml.project_id
GROUP BY p.name, m.name, m.type
ORDER BY p.name, total_hours DESC;

-- ------------------------------------------------------------
-- 6) Labour + attendance summary (last 7 days)
-- ------------------------------------------------------------
SELECT
  p.name AS project_name,
  COUNT(DISTINCT l.id)::int AS total_labour,
  COUNT(DISTINCT CASE WHEN l.status = 'active' THEN l.id END)::int AS active_labour,
  COUNT(CASE WHEN la.status = 'present' THEN 1 END)::int AS present_marks,
  COUNT(CASE WHEN la.status = 'half_day' THEN 1 END)::int AS half_day_marks,
  COUNT(CASE WHEN la.status = 'absent' THEN 1 END)::int AS absent_marks
FROM public.projects p
LEFT JOIN public.labour l ON l.project_id = p.id
LEFT JOIN public.labour_attendance la
  ON la.project_id = p.id
 AND la.date >= CURRENT_DATE - 7
GROUP BY p.name
ORDER BY p.name;

-- ------------------------------------------------------------
-- 7) Daily labour logs
-- ------------------------------------------------------------
SELECT
  p.name AS project_name,
  dll.log_date,
  dll.contractor_name,
  dll.skilled_count,
  dll.unskilled_count,
  dll.notes
FROM public.daily_labour_logs dll
JOIN public.projects p ON p.id = dll.project_id
ORDER BY dll.log_date DESC, p.name;

-- ------------------------------------------------------------
-- 8) Bills summary
-- ------------------------------------------------------------
SELECT
  p.name AS project_name,
  b.status,
  COUNT(*)::int AS bills_count,
  ROUND(SUM(b.amount)::numeric, 2) AS total_amount,
  ROUND(SUM(CASE WHEN b.status = 'paid' THEN b.amount ELSE 0 END)::numeric, 2) AS paid_amount,
  ROUND(SUM(CASE WHEN b.status = 'pending' THEN b.amount ELSE 0 END)::numeric, 2) AS pending_amount
FROM public.bills b
JOIN public.projects p ON p.id = b.project_id
GROUP BY p.name, b.status
ORDER BY p.name, b.status;

-- Optional detail check if payment columns exist
SELECT
  b.title,
  b.status,
  to_jsonb(b)->>'payment_type' AS payment_type,
  to_jsonb(b)->>'payment_status' AS payment_status,
  b.amount,
  p.name AS project_name
FROM public.bills b
JOIN public.projects p ON p.id = b.project_id
ORDER BY b.created_at DESC;

-- ------------------------------------------------------------
-- 9) Recent operation logs
-- ------------------------------------------------------------
SELECT
  ol.created_at,
  ol.operation_type,
  ol.entity_type,
  ol.title,
  COALESCE(p.name, '-') AS project_name,
  COALESCE(up.full_name, up.email, '-') AS actor
FROM public.operation_logs ol
LEFT JOIN public.projects p ON p.id = ol.project_id
LEFT JOIN public.user_profiles up ON up.id = ol.user_id
ORDER BY ol.created_at DESC
LIMIT 30;
