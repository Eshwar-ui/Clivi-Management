-- ============================================================
-- DEMO 03: SEED FULL DEMO DATA (ALL MODULES)
-- ============================================================
-- Seeds demo data for:
-- - Projects
-- - Site manager assignments
-- - Suppliers (vendors)
-- - Materials (stock + inward/outward logs)
-- - Machinery + machinery logs
-- - Labour + attendance + daily labour logs
-- - Bills
-- - Operation logs
--
-- Recommended execution order:
-- 1) DEMO_01_PREP_USERS.sql
-- 2) DEMO_02_RESET_DATA_KEEP_USERS.sql
-- 3) THIS FILE (DEMO_03_SEED_FULL_DEMO.sql)
-- 4) DEMO_04_VERIFY_DEMO.sql
-- ============================================================

DO $$
DECLARE
  v_admin_id UUID;
  v_site_manager_ids UUID[];
  v_sm1 UUID;
  v_sm2 UUID;

  v_project_alpha UUID;
  v_project_beta UUID;
  v_project_gamma UUID;

  v_supplier_aa_steel UUID;
  v_supplier_metro_steel UUID;
  v_supplier_ultratech UUID;
  v_supplier_shakti_steel UUID;
  v_supplier_prime_cement UUID;
  v_supplier_mr_earth UUID;
  v_supplier_delta_steel UUID;
  v_supplier_bharat_cement UUID;
  v_supplier_sri_aggregate UUID;

  v_item_alpha_steel18 UUID;
  v_item_alpha_steel24 UUID;
  v_item_alpha_cement_opc UUID;
  v_item_alpha_cement_ppc UUID;
  v_item_beta_steel20 UUID;
  v_item_beta_cement_opc UUID;
  v_item_beta_sand UUID;
  v_item_gamma_steel16 UUID;
  v_item_gamma_cement_ppc UUID;
  v_item_gamma_aggregate UUID;

  v_machine_excavator UUID;
  v_machine_mixer UUID;
  v_machine_crane UUID;
  v_machine_pump UUID;

  v_has_projects_client_name BOOLEAN;
  v_has_projects_project_type BOOLEAN;
  v_has_projects_progress BOOLEAN;

  v_has_bills_raised_by BOOLEAN;
  v_has_bills_payment_type BOOLEAN;
  v_has_bills_payment_status BOOLEAN;
  v_has_bills_approved_at BOOLEAN;
  v_has_bills_uploaded_by BOOLEAN;
  v_has_bills_vendor_name BOOLEAN;
  v_has_bills_receipt_url BOOLEAN;
  v_has_bills_image_url BOOLEAN;
  v_has_bills_image_path BOOLEAN;

  v_supports_extended_bill_type BOOLEAN := FALSE;
  v_bill_type_workers TEXT := 'expense';
  v_bill_type_materials TEXT := 'expense';
  v_bill_type_transport TEXT := 'expense';
  v_bill_type_equipment TEXT := 'expense';

  v_has_machinery_registration_no BOOLEAN;
  v_has_machinery_ownership_type BOOLEAN;
  v_has_machinery_total_hours BOOLEAN;

  v_has_mach_log_type BOOLEAN;
  v_has_mach_hours_used BOOLEAN;
  v_has_mach_log_date BOOLEAN;

  v_has_daily_labour_id BOOLEAN;
BEGIN
  -- ----------------------------------------------------------
  -- Preflight checks
  -- ----------------------------------------------------------
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'suppliers' AND column_name = 'project_id'
  ) THEN
    RAISE EXCEPTION 'Missing suppliers.project_id. Apply migration 036_fix_suppliers_project.sql first.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'stock_items' AND column_name = 'grade'
  ) THEN
    RAISE EXCEPTION 'Missing stock_items.grade. Apply migration 031_add_material_log_columns.sql first.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'material_logs' AND column_name = 'supplier_id'
  ) THEN
    RAISE EXCEPTION 'Missing material_logs.supplier_id. Apply migration 017_suppliers_table.sql first.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'machinery_logs' AND column_name = 'work_activity'
  ) OR NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'machinery_logs' AND column_name = 'start_reading'
  ) OR NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'machinery_logs' AND column_name = 'end_reading'
  ) THEN
    RAISE EXCEPTION 'Missing required machinery_logs columns. Apply migrations 035 and 046 first.';
  END IF;

  -- Detect optional columns / schema variants
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'projects' AND column_name = 'client_name'
  ) INTO v_has_projects_client_name;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'projects' AND column_name = 'project_type'
  ) INTO v_has_projects_project_type;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'projects' AND column_name = 'progress'
  ) INTO v_has_projects_progress;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bills' AND column_name = 'raised_by'
  ) INTO v_has_bills_raised_by;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bills' AND column_name = 'payment_type'
  ) INTO v_has_bills_payment_type;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bills' AND column_name = 'payment_status'
  ) INTO v_has_bills_payment_status;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bills' AND column_name = 'approved_at'
  ) INTO v_has_bills_approved_at;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bills' AND column_name = 'uploaded_by'
  ) INTO v_has_bills_uploaded_by;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bills' AND column_name = 'vendor_name'
  ) INTO v_has_bills_vendor_name;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bills' AND column_name = 'receipt_url'
  ) INTO v_has_bills_receipt_url;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bills' AND column_name = 'image_url'
  ) INTO v_has_bills_image_url;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bills' AND column_name = 'image_path'
  ) INTO v_has_bills_image_path;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'machinery' AND column_name = 'registration_no'
  ) INTO v_has_machinery_registration_no;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'machinery' AND column_name = 'ownership_type'
  ) INTO v_has_machinery_ownership_type;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'machinery' AND column_name = 'total_hours'
  ) INTO v_has_machinery_total_hours;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'machinery_logs' AND column_name = 'log_type'
  ) INTO v_has_mach_log_type;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'machinery_logs' AND column_name = 'hours_used'
  ) INTO v_has_mach_hours_used;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'machinery_logs' AND column_name = 'log_date'
  ) INTO v_has_mach_log_date;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'daily_labour_logs' AND column_name = 'labour_id'
  ) INTO v_has_daily_labour_id;

  -- Detect whether bills_bill_type_check supports new bill types
  SELECT COALESCE(
    POSITION('workers' IN LOWER(pg_get_constraintdef(c.oid))) > 0,
    FALSE
  )
  INTO v_supports_extended_bill_type
  FROM pg_constraint c
  WHERE c.conrelid = 'public.bills'::regclass
    AND c.conname = 'bills_bill_type_check'
  LIMIT 1;

  IF v_supports_extended_bill_type THEN
    v_bill_type_workers := 'workers';
    v_bill_type_materials := 'materials';
    v_bill_type_transport := 'transport';
    v_bill_type_equipment := 'equipment_rent';
  END IF;

  -- ----------------------------------------------------------
  -- Resolve users
  -- ----------------------------------------------------------
  SELECT up.id
  INTO v_admin_id
  FROM public.user_profiles up
  WHERE LOWER(COALESCE(up.email, '')) = LOWER('admin@gmail.com')
  LIMIT 1;

  IF v_admin_id IS NULL THEN
    SELECT up.id
    INTO v_admin_id
    FROM public.user_profiles up
    WHERE up.role IN ('admin', 'super_admin')
    ORDER BY up.created_at
    LIMIT 1;
  END IF;

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'No admin user found in user_profiles. Run DEMO_01_PREP_USERS.sql first.';
  END IF;

  SELECT ARRAY_AGG(up.id ORDER BY up.created_at)
  INTO v_site_manager_ids
  FROM public.user_profiles up
  WHERE up.role = 'site_manager';

  IF COALESCE(array_length(v_site_manager_ids, 1), 0) = 0 THEN
    RAISE EXCEPTION 'No site_manager user found in user_profiles. Create users and run DEMO_01_PREP_USERS.sql first.';
  END IF;

  v_sm1 := v_site_manager_ids[1];
  v_sm2 := v_site_manager_ids[2];

  -- ----------------------------------------------------------
  -- Projects
  -- ----------------------------------------------------------
  INSERT INTO public.projects (
    name, description, location, status,
    start_date, end_date, budget, created_by, created_at, updated_at
  ) VALUES (
    'Skyline Residency Phase 2',
    'Residential towers with basement parking and clubhouse.',
    'Hyderabad',
    'in_progress',
    CURRENT_DATE - 45,
    CURRENT_DATE + 120,
    95000000,
    v_admin_id,
    NOW() - INTERVAL '10 days',
    NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_project_alpha;

  INSERT INTO public.projects (
    name, description, location, status,
    start_date, end_date, budget, created_by, created_at, updated_at
  ) VALUES (
    'City Mall Expansion',
    'Commercial block expansion including parking and facade upgrade.',
    'Vijayawada',
    'in_progress',
    CURRENT_DATE - 30,
    CURRENT_DATE + 180,
    64000000,
    v_admin_id,
    NOW() - INTERVAL '9 days',
    NOW() - INTERVAL '2 days'
  ) RETURNING id INTO v_project_beta;

  INSERT INTO public.projects (
    name, description, location, status,
    start_date, end_date, budget, created_by, created_at, updated_at
  ) VALUES (
    'River Bridge Service Road',
    'Infrastructure package for retaining walls and service road.',
    'Warangal',
    'planning',
    CURRENT_DATE - 12,
    CURRENT_DATE + 210,
    123000000,
    v_admin_id,
    NOW() - INTERVAL '8 days',
    NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_project_gamma;

  IF v_has_projects_client_name THEN
    UPDATE public.projects
    SET client_name = 'Apex Infra Developers'
    WHERE id = v_project_alpha;

    UPDATE public.projects
    SET client_name = 'Urban Retail Pvt Ltd'
    WHERE id = v_project_beta;

    UPDATE public.projects
    SET client_name = 'State Infrastructure Board'
    WHERE id = v_project_gamma;
  END IF;

  IF v_has_projects_project_type THEN
    UPDATE public.projects
    SET project_type = 'Residential'
    WHERE id = v_project_alpha;

    UPDATE public.projects
    SET project_type = 'Commercial'
    WHERE id = v_project_beta;

    UPDATE public.projects
    SET project_type = 'Infrastructure'
    WHERE id = v_project_gamma;
  END IF;

  IF v_has_projects_progress THEN
    UPDATE public.projects
    SET progress = 58
    WHERE id = v_project_alpha;

    UPDATE public.projects
    SET progress = 34
    WHERE id = v_project_beta;

    UPDATE public.projects
    SET progress = 12
    WHERE id = v_project_gamma;
  END IF;

  -- ----------------------------------------------------------
  -- Project assignments (multi-manager on one project)
  -- ----------------------------------------------------------
  INSERT INTO public.project_assignments (
    project_id, user_id, assigned_role, assigned_by, assigned_at
  ) VALUES
    (v_project_alpha, v_sm1, 'manager', v_admin_id, NOW() - INTERVAL '9 days'),
    (v_project_beta,  v_sm1, 'manager', v_admin_id, NOW() - INTERVAL '9 days'),
    (v_project_gamma, v_sm1, 'manager', v_admin_id, NOW() - INTERVAL '8 days')
  ON CONFLICT (project_id, user_id) DO NOTHING;

  IF v_sm2 IS NOT NULL THEN
    INSERT INTO public.project_assignments (
      project_id, user_id, assigned_role, assigned_by, assigned_at
    ) VALUES
      (v_project_alpha, v_sm2, 'manager', v_admin_id, NOW() - INTERVAL '8 days'),
      (v_project_beta,  v_sm2, 'viewer',  v_admin_id, NOW() - INTERVAL '7 days')
    ON CONFLICT (project_id, user_id) DO NOTHING;
  END IF;

  -- ----------------------------------------------------------
  -- Suppliers / vendors
  -- ----------------------------------------------------------
  INSERT INTO public.suppliers (
    project_id, name, contact_person, phone, email, address,
    category, notes, is_active, created_by, created_at, updated_at
  ) VALUES (
    v_project_alpha,
    'AA Steel Traders', 'Arun Kumar', '9000001001', 'aa.steel@example.com', 'Kukatpally, Hyderabad',
    'Steel', 'Primary steel vendor for TMT and rebar.', TRUE,
    v_admin_id, NOW() - INTERVAL '9 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_supplier_aa_steel;

  INSERT INTO public.suppliers (
    project_id, name, contact_person, phone, email, address,
    category, notes, is_active, created_by, created_at, updated_at
  ) VALUES (
    v_project_alpha,
    'Metro Steel Depot', 'Prakash Rao', '9000001002', 'metro.steel@example.com', 'Balanagar, Hyderabad',
    'Steel', 'Secondary steel supplier for urgent lots.', TRUE,
    v_admin_id, NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_supplier_metro_steel;

  INSERT INTO public.suppliers (
    project_id, name, contact_person, phone, email, address,
    category, notes, is_active, created_by, created_at, updated_at
  ) VALUES (
    v_project_alpha,
    'UltraTech Cement Hub', 'Sanjay Reddy', '9000001003', 'ultratech.hub@example.com', 'Miyapur, Hyderabad',
    'Cement', 'OPC/PPC bulk supply.', TRUE,
    v_admin_id, NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_supplier_ultratech;

  INSERT INTO public.suppliers (
    project_id, name, contact_person, phone, email, address,
    category, notes, is_active, created_by, created_at, updated_at
  ) VALUES (
    v_project_beta,
    'Shakti Steel Agency', 'Deepak Jain', '9000001004', 'shakti.steel@example.com', 'Benz Circle, Vijayawada',
    'Steel', 'Steel supplier for mall expansion beams.', TRUE,
    v_admin_id, NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_supplier_shakti_steel;

  INSERT INTO public.suppliers (
    project_id, name, contact_person, phone, email, address,
    category, notes, is_active, created_by, created_at, updated_at
  ) VALUES (
    v_project_beta,
    'Prime Cement Mart', 'Hari Babu', '9000001005', 'prime.cement@example.com', 'Patamata, Vijayawada',
    'Cement', 'Cement for slab and plaster packages.', TRUE,
    v_admin_id, NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_supplier_prime_cement;

  INSERT INTO public.suppliers (
    project_id, name, contact_person, phone, email, address,
    category, notes, is_active, created_by, created_at, updated_at
  ) VALUES (
    v_project_beta,
    'Mr Earth Logistics', 'Nazeer Khan', '9000001006', 'earth.logistics@example.com', 'Gollapudi, Vijayawada',
    'Sand', 'River sand transport and unloading.', TRUE,
    v_admin_id, NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_supplier_mr_earth;

  INSERT INTO public.suppliers (
    project_id, name, contact_person, phone, email, address,
    category, notes, is_active, created_by, created_at, updated_at
  ) VALUES (
    v_project_gamma,
    'Delta Steel Works', 'Vikram Singh', '9000001007', 'delta.steel@example.com', 'Hanamkonda, Warangal',
    'Steel', 'Bridge support steel and rods.', TRUE,
    v_admin_id, NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_supplier_delta_steel;

  INSERT INTO public.suppliers (
    project_id, name, contact_person, phone, email, address,
    category, notes, is_active, created_by, created_at, updated_at
  ) VALUES (
    v_project_gamma,
    'Bharat Cement Agency', 'Mahesh Patel', '9000001008', 'bharat.cement@example.com', 'Kazipet, Warangal',
    'Cement', 'PPC cement for retaining walls.', TRUE,
    v_admin_id, NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_supplier_bharat_cement;

  INSERT INTO public.suppliers (
    project_id, name, contact_person, phone, email, address,
    category, notes, is_active, created_by, created_at, updated_at
  ) VALUES (
    v_project_gamma,
    'Sri Aggregate & Co', 'Lokesh Yadav', '9000001009', 'sri.aggregate@example.com', 'Narsampet Road, Warangal',
    'Aggregate', 'Aggregate and metal supply.', TRUE,
    v_admin_id, NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_supplier_sri_aggregate;

  -- ----------------------------------------------------------
  -- Stock items (materials)
  -- ----------------------------------------------------------
  INSERT INTO public.stock_items (
    project_id, name, description, category, grade, unit,
    quantity, min_quantity, low_stock_threshold, unit_price,
    created_by, created_at, updated_at
  ) VALUES (
    v_project_alpha, 'Steel 18mm', 'TMT bars for columns', 'Steel', 'Fe500', 'Tons',
    0, 5, 8, 50000,
    v_admin_id, NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_item_alpha_steel18;

  INSERT INTO public.stock_items (
    project_id, name, description, category, grade, unit,
    quantity, min_quantity, low_stock_threshold, unit_price,
    created_by, created_at, updated_at
  ) VALUES (
    v_project_alpha, 'Steel 24mm', 'Heavy reinforcement bars', 'Steel', 'Fe500D', 'Tons',
    0, 4, 6, 52000,
    v_admin_id, NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_item_alpha_steel24;

  INSERT INTO public.stock_items (
    project_id, name, description, category, grade, unit,
    quantity, min_quantity, low_stock_threshold, unit_price,
    created_by, created_at, updated_at
  ) VALUES (
    v_project_alpha, 'Cement OPC 53', 'High grade OPC cement', 'Cement', 'OPC 53', 'Bags',
    0, 150, 180, 450,
    v_admin_id, NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_item_alpha_cement_opc;

  INSERT INTO public.stock_items (
    project_id, name, description, category, grade, unit,
    quantity, min_quantity, low_stock_threshold, unit_price,
    created_by, created_at, updated_at
  ) VALUES (
    v_project_alpha, 'Cement PPC', 'General structural cement', 'Cement', 'PPC', 'Bags',
    0, 120, 160, 420,
    v_admin_id, NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_item_alpha_cement_ppc;

  INSERT INTO public.stock_items (
    project_id, name, description, category, grade, unit,
    quantity, min_quantity, low_stock_threshold, unit_price,
    created_by, created_at, updated_at
  ) VALUES (
    v_project_beta, 'Steel 20mm', 'Beam reinforcement steel', 'Steel', 'Fe500', 'Tons',
    0, 4, 7, 51000,
    v_admin_id, NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_item_beta_steel20;

  INSERT INTO public.stock_items (
    project_id, name, description, category, grade, unit,
    quantity, min_quantity, low_stock_threshold, unit_price,
    created_by, created_at, updated_at
  ) VALUES (
    v_project_beta, 'Cement OPC 53', 'Structural cement stock', 'Cement', 'OPC 53', 'Bags',
    0, 110, 140, 460,
    v_admin_id, NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_item_beta_cement_opc;

  INSERT INTO public.stock_items (
    project_id, name, description, category, grade, unit,
    quantity, min_quantity, low_stock_threshold, unit_price,
    created_by, created_at, updated_at
  ) VALUES (
    v_project_beta, 'River Sand', 'Plaster and concrete sand', 'Sand', NULL, 'Cum',
    0, 20, 25, 800,
    v_admin_id, NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_item_beta_sand;

  INSERT INTO public.stock_items (
    project_id, name, description, category, grade, unit,
    quantity, min_quantity, low_stock_threshold, unit_price,
    created_by, created_at, updated_at
  ) VALUES (
    v_project_gamma, 'Steel 16mm', 'Road retaining wall steel', 'Steel', 'Fe500', 'Tons',
    0, 3, 5, 49500,
    v_admin_id, NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_item_gamma_steel16;

  INSERT INTO public.stock_items (
    project_id, name, description, category, grade, unit,
    quantity, min_quantity, low_stock_threshold, unit_price,
    created_by, created_at, updated_at
  ) VALUES (
    v_project_gamma, 'Cement PPC', 'Retaining wall cement', 'Cement', 'PPC', 'Bags',
    0, 140, 170, 410,
    v_admin_id, NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_item_gamma_cement_ppc;

  INSERT INTO public.stock_items (
    project_id, name, description, category, grade, unit,
    quantity, min_quantity, low_stock_threshold, unit_price,
    created_by, created_at, updated_at
  ) VALUES (
    v_project_gamma, 'Aggregate 20mm', 'Road base aggregate', 'Aggregate', NULL, 'Cum',
    0, 15, 20, 750,
    v_admin_id, NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_item_gamma_aggregate;

  -- ----------------------------------------------------------
  -- Material logs (inward + outward)
  -- ----------------------------------------------------------
  INSERT INTO public.material_logs (
    project_id, item_id, log_type, quantity, activity,
    notes, logged_by, supplier_id, payment_type, bill_amount, grade, logged_at, created_at
  ) VALUES
  -- Project Alpha - Steel
  (v_project_alpha, v_item_alpha_steel18, 'inward', 45, 'Material Received',
   'Lot A-18 delivered', COALESCE(v_sm1, v_admin_id), v_supplier_aa_steel, 'Cash', 450000, 'Fe500', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  (v_project_alpha, v_item_alpha_steel18, 'inward', 20, 'Material Received',
   'Lot B-18 delivered', COALESCE(v_sm1, v_admin_id), v_supplier_aa_steel, 'UPI', 205000, 'Fe500', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  (v_project_alpha, v_item_alpha_steel18, 'outward', 18, 'Column Reinforcement',
   'Consumed for Block A columns', COALESCE(v_sm1, v_admin_id), NULL, NULL, NULL, 'Fe500', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  (v_project_alpha, v_item_alpha_steel24, 'inward', 32, 'Material Received',
   'Heavy steel delivery', COALESCE(v_sm1, v_admin_id), v_supplier_metro_steel, 'Bank Transfer', 400000, 'Fe500D', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  (v_project_alpha, v_item_alpha_steel24, 'outward', 8, 'Beam Reinforcement',
   'Consumed for podium beam', COALESCE(v_sm1, v_admin_id), NULL, NULL, NULL, 'Fe500D', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

  -- Project Alpha - Cement
  (v_project_alpha, v_item_alpha_cement_opc, 'inward', 900, 'Material Received',
   'OPC bulk received', COALESCE(v_sm1, v_admin_id), v_supplier_ultratech, 'Cheque', 405000, 'OPC 53', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
  (v_project_alpha, v_item_alpha_cement_opc, 'outward', 350, 'Slab Casting',
   'Used for slab and column work', COALESCE(v_sm1, v_admin_id), NULL, NULL, NULL, 'OPC 53', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  (v_project_alpha, v_item_alpha_cement_ppc, 'inward', 500, 'Material Received',
   'PPC lot for masonry', COALESCE(v_sm1, v_admin_id), v_supplier_ultratech, 'Cash', 210000, 'PPC', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  (v_project_alpha, v_item_alpha_cement_ppc, 'outward', 140, 'Masonry Work',
   'Consumed for block wall', COALESCE(v_sm1, v_admin_id), NULL, NULL, NULL, 'PPC', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

  -- Project Beta
  (v_project_beta, v_item_beta_steel20, 'inward', 28, 'Material Received',
   'Main steel lot', COALESCE(v_sm2, v_sm1, v_admin_id), v_supplier_shakti_steel, 'Online', 308000, 'Fe500', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  (v_project_beta, v_item_beta_steel20, 'outward', 9, 'Beam Cage Work',
   'Used in expansion block', COALESCE(v_sm2, v_sm1, v_admin_id), NULL, NULL, NULL, 'Fe500', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  (v_project_beta, v_item_beta_cement_opc, 'inward', 700, 'Material Received',
   'Cement for commercial slab', COALESCE(v_sm2, v_sm1, v_admin_id), v_supplier_prime_cement, 'Bank Transfer', 322000, 'OPC 53', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  (v_project_beta, v_item_beta_cement_opc, 'outward', 260, 'Plaster Work',
   'Plastering and patch repairs', COALESCE(v_sm2, v_sm1, v_admin_id), NULL, NULL, NULL, 'OPC 53', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  (v_project_beta, v_item_beta_sand, 'inward', 120, 'Material Received',
   'River sand truck unload', COALESCE(v_sm2, v_sm1, v_admin_id), v_supplier_mr_earth, 'Cash', 96000, NULL, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  (v_project_beta, v_item_beta_sand, 'outward', 40, 'Concrete Mix',
   'Consumed for RCC mix', COALESCE(v_sm2, v_sm1, v_admin_id), NULL, NULL, NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

  -- Project Gamma
  (v_project_gamma, v_item_gamma_steel16, 'inward', 30, 'Material Received',
   'Bridge retaining steel', COALESCE(v_sm1, v_admin_id), v_supplier_delta_steel, 'Credit', 285000, 'Fe500', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  (v_project_gamma, v_item_gamma_steel16, 'outward', 12, 'Retaining Wall',
   'Used for retaining wall work', COALESCE(v_sm1, v_admin_id), NULL, NULL, NULL, 'Fe500', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  (v_project_gamma, v_item_gamma_cement_ppc, 'inward', 650, 'Material Received',
   'PPC bulk for road package', COALESCE(v_sm1, v_admin_id), v_supplier_bharat_cement, 'Cash', 266500, 'PPC', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  (v_project_gamma, v_item_gamma_cement_ppc, 'outward', 220, 'Retaining Wall',
   'Consumed for wall and base', COALESCE(v_sm1, v_admin_id), NULL, NULL, NULL, 'PPC', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  (v_project_gamma, v_item_gamma_aggregate, 'inward', 90, 'Material Received',
   'Aggregate supply from quarry', COALESCE(v_sm1, v_admin_id), v_supplier_sri_aggregate, 'UPI', 67500, NULL, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  (v_project_gamma, v_item_gamma_aggregate, 'outward', 20, 'Road Base Preparation',
   'Consumed in road base layers', COALESCE(v_sm1, v_admin_id), NULL, NULL, NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

  -- Force quantity sync from logs (works whether trigger exists or not)
  UPDATE public.stock_items si
  SET quantity = COALESCE(calc.qty, 0),
      updated_at = NOW()
  FROM (
    SELECT
      ml.item_id,
      SUM(CASE WHEN ml.log_type = 'inward' THEN ml.quantity ELSE -ml.quantity END) AS qty
    FROM public.material_logs ml
    GROUP BY ml.item_id
  ) calc
  WHERE si.id = calc.item_id;

  -- ----------------------------------------------------------
  -- Material master + grades (reference data, if tables exist)
  -- ----------------------------------------------------------
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'material_master'
  ) THEN
    INSERT INTO public.material_master (name, is_active, created_at)
    SELECT DISTINCT si.name, TRUE, NOW() - INTERVAL '5 days'
    FROM public.stock_items si
    WHERE si.project_id IN (v_project_alpha, v_project_beta, v_project_gamma)
    ON CONFLICT (name) DO NOTHING;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'material_grades'
  ) AND EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'material_master'
  ) THEN
    INSERT INTO public.material_grades (material_id, grade_name, created_at)
    SELECT DISTINCT mm.id, si.grade, NOW() - INTERVAL '5 days'
    FROM public.stock_items si
    JOIN public.material_master mm ON mm.name = si.name
    WHERE si.project_id IN (v_project_alpha, v_project_beta, v_project_gamma)
      AND si.grade IS NOT NULL
      AND btrim(si.grade) <> ''
    ON CONFLICT DO NOTHING;
  END IF;

  -- Vendor material lookup (if table exists)
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'vendor_materials'
  ) THEN
    DELETE FROM public.vendor_materials
    WHERE project_id IN (v_project_alpha, v_project_beta, v_project_gamma);

    INSERT INTO public.vendor_materials (
      project_id, supplier_id, material_name, grade, last_price, last_used_at
    )
    SELECT
      ml.project_id,
      ml.supplier_id,
      si.name,
      COALESCE(ml.grade, si.grade) AS grade,
      CASE
        WHEN SUM(ml.quantity) = 0 THEN NULL
        ELSE SUM(COALESCE(ml.bill_amount, 0)) / NULLIF(SUM(ml.quantity), 0)
      END AS last_price,
      MAX(ml.logged_at) AS last_used_at
    FROM public.material_logs ml
    JOIN public.stock_items si ON si.id = ml.item_id
    WHERE ml.log_type = 'inward'
      AND ml.supplier_id IS NOT NULL
      AND ml.project_id IN (v_project_alpha, v_project_beta, v_project_gamma)
    GROUP BY ml.project_id, ml.supplier_id, si.name, COALESCE(ml.grade, si.grade);
  END IF;

  -- ----------------------------------------------------------
  -- Machinery + logs
  -- ----------------------------------------------------------
  INSERT INTO public.machinery (
    name, type, current_project_id, created_by, created_at, updated_at
  ) VALUES (
    'CAT Excavator 320D', 'Excavator', v_project_alpha, v_admin_id,
    NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_machine_excavator;

  INSERT INTO public.machinery (
    name, type, current_project_id, created_by, created_at, updated_at
  ) VALUES (
    'Ajax Concrete Mixer', 'Mixer', v_project_alpha, v_admin_id,
    NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_machine_mixer;

  INSERT INTO public.machinery (
    name, type, current_project_id, created_by, created_at, updated_at
  ) VALUES (
    'Tadano Mobile Crane', 'Crane', v_project_beta, v_admin_id,
    NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_machine_crane;

  INSERT INTO public.machinery (
    name, type, current_project_id, created_by, created_at, updated_at
  ) VALUES (
    'Schwing Concrete Pump', 'Pump', v_project_gamma, v_admin_id,
    NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'
  ) RETURNING id INTO v_machine_pump;

  IF v_has_machinery_registration_no THEN
    UPDATE public.machinery SET registration_no = 'TS09EX320D' WHERE id = v_machine_excavator;
    UPDATE public.machinery SET registration_no = 'TS09MXR5541' WHERE id = v_machine_mixer;
    UPDATE public.machinery SET registration_no = 'AP16CRN1122' WHERE id = v_machine_crane;
    UPDATE public.machinery SET registration_no = 'TS11PMP7878' WHERE id = v_machine_pump;
  END IF;

  IF v_has_machinery_ownership_type THEN
    UPDATE public.machinery SET ownership_type = 'Own' WHERE id IN (v_machine_excavator, v_machine_mixer);
    UPDATE public.machinery SET ownership_type = 'Rental' WHERE id IN (v_machine_crane, v_machine_pump);
  END IF;

  INSERT INTO public.machinery_logs (
    project_id, machinery_id, work_activity,
    start_reading, end_reading,
    notes, logged_by, logged_at, created_at
  ) VALUES
    (v_project_alpha, v_machine_excavator, 'Earth excavation for basement',
     1100, 1108.5,
     'Basement cut work', COALESCE(v_sm1, v_admin_id), NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
    (v_project_alpha, v_machine_mixer, 'RCC batching and mixing',
     420, 427,
     'Slab concrete batch', COALESCE(v_sm1, v_admin_id), NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
    (v_project_beta, v_machine_crane, 'Steel girder lifting',
     800, 805.5,
     'Mall canopy lift', COALESCE(v_sm2, v_sm1, v_admin_id), NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
    (v_project_beta, v_machine_crane, 'Facade panel handling',
     805.5, 810,
     'Facade package support', COALESCE(v_sm2, v_sm1, v_admin_id), NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
    (v_project_gamma, v_machine_pump, 'Retaining wall pour',
     210, 216,
     'Continuous pour cycle', COALESCE(v_sm1, v_admin_id), NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
    (v_project_gamma, v_machine_excavator, 'Service road trenching',
     1108.5, 1113.0,
     'Road-side trenching', COALESCE(v_sm1, v_admin_id), NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

  IF v_has_mach_log_type THEN
    UPDATE public.machinery_logs
    SET log_type = 'usage'
    WHERE project_id IN (v_project_alpha, v_project_beta, v_project_gamma);
  END IF;

  IF v_has_mach_hours_used THEN
    UPDATE public.machinery_logs
    SET hours_used = COALESCE(end_reading, 0) - COALESCE(start_reading, 0)
    WHERE project_id IN (v_project_alpha, v_project_beta, v_project_gamma);
  END IF;

  IF v_has_mach_log_date THEN
    UPDATE public.machinery_logs
    SET log_date = (logged_at AT TIME ZONE 'UTC')::date
    WHERE project_id IN (v_project_alpha, v_project_beta, v_project_gamma);
  END IF;

  IF v_has_machinery_total_hours THEN
    IF v_has_mach_hours_used THEN
      UPDATE public.machinery m
      SET total_hours = COALESCE(src.total_used, 0)
      FROM (
        SELECT machinery_id, SUM(COALESCE(hours_used, 0)) AS total_used
        FROM public.machinery_logs
        GROUP BY machinery_id
      ) src
      WHERE m.id = src.machinery_id;
    ELSE
      UPDATE public.machinery m
      SET total_hours = COALESCE(src.total_used, 0)
      FROM (
        SELECT machinery_id, SUM(COALESCE(end_reading, 0) - COALESCE(start_reading, 0)) AS total_used
        FROM public.machinery_logs
        GROUP BY machinery_id
      ) src
      WHERE m.id = src.machinery_id;
    END IF;
  END IF;

  -- ----------------------------------------------------------
  -- Labour + attendance + daily logs
  -- ----------------------------------------------------------
  INSERT INTO public.labour (
    name, phone, skill_type, daily_wage, project_id,
    status, created_by, created_at, updated_at
  ) VALUES
    ('Raju Mason', '9000002001', 'Mason', 950, v_project_alpha, 'active', COALESCE(v_sm1, v_admin_id), NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'),
    ('Mani Helper', '9000002002', 'Helper', 600, v_project_alpha, 'active', COALESCE(v_sm1, v_admin_id), NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'),
    ('Anil Carpenter', '9000002003', 'Carpenter', 1050, v_project_alpha, 'active', COALESCE(v_sm1, v_admin_id), NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'),
    ('Siva Electrician', '9000002004', 'Electrician', 1200, v_project_beta, 'active', COALESCE(v_sm2, v_sm1, v_admin_id), NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'),
    ('Rahul Welder', '9000002005', 'Welder', 1100, v_project_beta, 'active', COALESCE(v_sm2, v_sm1, v_admin_id), NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'),
    ('Kiran Plumber', '9000002006', 'Plumber', 1000, v_project_beta, 'active', COALESCE(v_sm2, v_sm1, v_admin_id), NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'),
    ('Balu Supervisor', '9000002007', 'Supervisor', 1500, v_project_gamma, 'active', COALESCE(v_sm1, v_admin_id), NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'),
    ('Naveen Driver', '9000002008', 'Driver', 900, v_project_gamma, 'active', COALESCE(v_sm1, v_admin_id), NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day');

  -- Attendance for last 3 days (upsert-safe)
  INSERT INTO public.labour_attendance (
    labour_id, project_id, date, status, hours_worked, notes, recorded_by, created_at
  )
  SELECT
    l.id,
    l.project_id,
    a.att_date,
    a.att_status,
    a.hours_worked,
    a.notes,
    a.recorded_by,
    NOW()
  FROM public.labour l
  JOIN (
    VALUES
      ('Raju Mason',  CURRENT_DATE - 2, 'present', 8.0::numeric, 'Foundation zone', COALESCE(v_sm1, v_admin_id)),
      ('Raju Mason',  CURRENT_DATE - 1, 'present', 8.5::numeric, 'Column grid', COALESCE(v_sm1, v_admin_id)),
      ('Raju Mason',  CURRENT_DATE,     'half_day', 4.0::numeric, 'Medical leave', COALESCE(v_sm1, v_admin_id)),

      ('Mani Helper', CURRENT_DATE - 2, 'present', 8.0::numeric, 'Material shifting', COALESCE(v_sm1, v_admin_id)),
      ('Mani Helper', CURRENT_DATE - 1, 'absent', 0.0::numeric, 'Absent', COALESCE(v_sm1, v_admin_id)),
      ('Mani Helper', CURRENT_DATE,     'present', 8.0::numeric, 'General help', COALESCE(v_sm1, v_admin_id)),

      ('Anil Carpenter', CURRENT_DATE - 2, 'present', 8.0::numeric, 'Shuttering', COALESCE(v_sm1, v_admin_id)),
      ('Anil Carpenter', CURRENT_DATE - 1, 'present', 8.0::numeric, 'Formwork correction', COALESCE(v_sm1, v_admin_id)),
      ('Anil Carpenter', CURRENT_DATE,     'present', 8.0::numeric, 'Decking', COALESCE(v_sm1, v_admin_id)),

      ('Siva Electrician', CURRENT_DATE - 2, 'present', 8.0::numeric, 'Cable routing', COALESCE(v_sm2, v_sm1, v_admin_id)),
      ('Siva Electrician', CURRENT_DATE - 1, 'present', 8.0::numeric, 'Panel install', COALESCE(v_sm2, v_sm1, v_admin_id)),
      ('Siva Electrician', CURRENT_DATE,     'half_day', 4.0::numeric, 'Testing', COALESCE(v_sm2, v_sm1, v_admin_id)),

      ('Rahul Welder', CURRENT_DATE - 2, 'present', 8.0::numeric, 'Metal frame weld', COALESCE(v_sm2, v_sm1, v_admin_id)),
      ('Rahul Welder', CURRENT_DATE - 1, 'present', 8.0::numeric, 'Joint welding', COALESCE(v_sm2, v_sm1, v_admin_id)),
      ('Rahul Welder', CURRENT_DATE,     'present', 7.5::numeric, 'Touch-up welding', COALESCE(v_sm2, v_sm1, v_admin_id)),

      ('Kiran Plumber', CURRENT_DATE - 2, 'present', 8.0::numeric, 'Pipeline marking', COALESCE(v_sm2, v_sm1, v_admin_id)),
      ('Kiran Plumber', CURRENT_DATE - 1, 'present', 8.0::numeric, 'Pipe laying', COALESCE(v_sm2, v_sm1, v_admin_id)),
      ('Kiran Plumber', CURRENT_DATE,     'absent', 0.0::numeric, 'Leave', COALESCE(v_sm2, v_sm1, v_admin_id)),

      ('Balu Supervisor', CURRENT_DATE - 2, 'present', 8.0::numeric, 'Site supervision', COALESCE(v_sm1, v_admin_id)),
      ('Balu Supervisor', CURRENT_DATE - 1, 'present', 8.0::numeric, 'Quality review', COALESCE(v_sm1, v_admin_id)),
      ('Balu Supervisor', CURRENT_DATE,     'present', 8.0::numeric, 'Progress tracking', COALESCE(v_sm1, v_admin_id)),

      ('Naveen Driver', CURRENT_DATE - 2, 'present', 8.0::numeric, 'Material transport', COALESCE(v_sm1, v_admin_id)),
      ('Naveen Driver', CURRENT_DATE - 1, 'half_day', 4.0::numeric, 'Fuel maintenance', COALESCE(v_sm1, v_admin_id)),
      ('Naveen Driver', CURRENT_DATE,     'present', 8.0::numeric, 'Trip execution', COALESCE(v_sm1, v_admin_id))
  ) AS a(name, att_date, att_status, hours_worked, notes, recorded_by)
    ON l.name = a.name
  ON CONFLICT (labour_id, date)
  DO UPDATE SET
    status = EXCLUDED.status,
    hours_worked = EXCLUDED.hours_worked,
    notes = EXCLUDED.notes,
    recorded_by = EXCLUDED.recorded_by;

  IF v_has_daily_labour_id THEN
    INSERT INTO public.daily_labour_logs (
      project_id, labour_id, contractor_name, skilled_count, unskilled_count,
      log_date, notes, created_by, created_at
    )
    VALUES
      (
        v_project_alpha,
        (SELECT id FROM public.labour WHERE project_id = v_project_alpha AND name = 'Raju Mason' LIMIT 1),
        'Ramesh Contractor',
        12,
        18,
        CURRENT_DATE - 1,
        'Concrete and shuttering manpower deployed',
        COALESCE(v_sm1, v_admin_id),
        NOW() - INTERVAL '1 day'
      ),
      (
        v_project_beta,
        (SELECT id FROM public.labour WHERE project_id = v_project_beta AND name = 'Rahul Welder' LIMIT 1),
        'Kiran Works',
        8,
        11,
        CURRENT_DATE,
        'Façade and welding teams active',
        COALESCE(v_sm2, v_sm1, v_admin_id),
        NOW()
      ),
      (
        v_project_gamma,
        (SELECT id FROM public.labour WHERE project_id = v_project_gamma AND name = 'Balu Supervisor' LIMIT 1),
        'BridgeCrew Infra',
        10,
        14,
        CURRENT_DATE,
        'Retaining wall and aggregate laying',
        COALESCE(v_sm1, v_admin_id),
        NOW()
      );
  ELSE
    INSERT INTO public.daily_labour_logs (
      project_id, contractor_name, skilled_count, unskilled_count,
      log_date, notes, created_by, created_at
    )
    VALUES
      (
        v_project_alpha,
        'Ramesh Contractor',
        12,
        18,
        CURRENT_DATE - 1,
        'Concrete and shuttering manpower deployed',
        COALESCE(v_sm1, v_admin_id),
        NOW() - INTERVAL '1 day'
      ),
      (
        v_project_beta,
        'Kiran Works',
        8,
        11,
        CURRENT_DATE,
        'Façade and welding teams active',
        COALESCE(v_sm2, v_sm1, v_admin_id),
        NOW()
      ),
      (
        v_project_gamma,
        'BridgeCrew Infra',
        10,
        14,
        CURRENT_DATE,
        'Retaining wall and aggregate laying',
        COALESCE(v_sm1, v_admin_id),
        NOW()
      );
  END IF;

  -- ----------------------------------------------------------
  -- Bills
  -- ----------------------------------------------------------
  IF v_has_bills_uploaded_by THEN
    INSERT INTO public.bills (
      project_id, title, description, amount, bill_type, status,
      bill_date, due_date,
      created_by, approved_by, uploaded_by, created_at, updated_at
    ) VALUES
      (
        v_project_alpha,
        'Workers Payment - Week 1',
        'Weekly payout for civil crew',
        45000,
        v_bill_type_workers,
        'pending',
        CURRENT_DATE - 3,
        CURRENT_DATE + 4,
        COALESCE(v_sm1, v_admin_id),
        NULL,
        COALESCE(v_sm1, v_admin_id),
        NOW() - INTERVAL '3 days',
        NOW() - INTERVAL '3 days'
      ),
      (
        v_project_alpha,
        'Material (Cement) Payment',
        'OPC/PPC lot settlement',
        185000,
        v_bill_type_materials,
        'paid',
        CURRENT_DATE - 5,
        CURRENT_DATE - 1,
        COALESCE(v_sm1, v_admin_id),
        v_admin_id,
        COALESCE(v_sm1, v_admin_id),
        NOW() - INTERVAL '5 days',
        NOW() - INTERVAL '1 day'
      ),
      (
        v_project_beta,
        'Steel Supply Advance',
        'Advance transfer for steel lot',
        120000,
        v_bill_type_materials,
        'approved',
        CURRENT_DATE - 2,
        CURRENT_DATE + 6,
        COALESCE(v_sm2, v_sm1, v_admin_id),
        v_admin_id,
        COALESCE(v_sm2, v_sm1, v_admin_id),
        NOW() - INTERVAL '2 days',
        NOW() - INTERVAL '1 day'
      ),
      (
        v_project_beta,
        'Transport Diesel Bill',
        'Loader and truck diesel charges',
        28000,
        v_bill_type_transport,
        'pending',
        CURRENT_DATE - 1,
        CURRENT_DATE + 8,
        COALESCE(v_sm2, v_sm1, v_admin_id),
        NULL,
        COALESCE(v_sm2, v_sm1, v_admin_id),
        NOW() - INTERVAL '1 day',
        NOW() - INTERVAL '1 day'
      ),
      (
        v_project_gamma,
        'Concrete Pump Rental',
        'Pump usage and operator charge',
        56000,
        v_bill_type_equipment,
        'paid',
        CURRENT_DATE - 4,
        CURRENT_DATE - 2,
        COALESCE(v_sm1, v_admin_id),
        v_admin_id,
        COALESCE(v_sm1, v_admin_id),
        NOW() - INTERVAL '4 days',
        NOW() - INTERVAL '2 days'
      ),
      (
        v_project_gamma,
        'Aggregate Supply Bill',
        'Aggregate batch partial payment',
        34000,
        v_bill_type_materials,
        'pending',
        CURRENT_DATE - 1,
        CURRENT_DATE + 7,
        COALESCE(v_sm1, v_admin_id),
        NULL,
        COALESCE(v_sm1, v_admin_id),
        NOW() - INTERVAL '1 day',
        NOW() - INTERVAL '1 day'
      ),
      (
        v_project_alpha,
        'Temporary Scaffold Expense',
        'Scaffold extra rental correction',
        18000,
        v_bill_type_equipment,
        'rejected',
        CURRENT_DATE - 2,
        CURRENT_DATE + 3,
        COALESCE(v_sm1, v_admin_id),
        v_admin_id,
        COALESCE(v_sm1, v_admin_id),
        NOW() - INTERVAL '2 days',
        NOW() - INTERVAL '1 day'
      );
  ELSE
    INSERT INTO public.bills (
      project_id, title, description, amount, bill_type, status,
      bill_date, due_date,
      created_by, approved_by, created_at, updated_at
    ) VALUES
      (
        v_project_alpha,
        'Workers Payment - Week 1',
        'Weekly payout for civil crew',
        45000,
        v_bill_type_workers,
        'pending',
        CURRENT_DATE - 3,
        CURRENT_DATE + 4,
        COALESCE(v_sm1, v_admin_id),
        NULL,
        NOW() - INTERVAL '3 days',
        NOW() - INTERVAL '3 days'
      ),
      (
        v_project_alpha,
        'Material (Cement) Payment',
        'OPC/PPC lot settlement',
        185000,
        v_bill_type_materials,
        'paid',
        CURRENT_DATE - 5,
        CURRENT_DATE - 1,
        COALESCE(v_sm1, v_admin_id),
        v_admin_id,
        NOW() - INTERVAL '5 days',
        NOW() - INTERVAL '1 day'
      ),
      (
        v_project_beta,
        'Steel Supply Advance',
        'Advance transfer for steel lot',
        120000,
        v_bill_type_materials,
        'approved',
        CURRENT_DATE - 2,
        CURRENT_DATE + 6,
        COALESCE(v_sm2, v_sm1, v_admin_id),
        v_admin_id,
        NOW() - INTERVAL '2 days',
        NOW() - INTERVAL '1 day'
      ),
      (
        v_project_beta,
        'Transport Diesel Bill',
        'Loader and truck diesel charges',
        28000,
        v_bill_type_transport,
        'pending',
        CURRENT_DATE - 1,
        CURRENT_DATE + 8,
        COALESCE(v_sm2, v_sm1, v_admin_id),
        NULL,
        NOW() - INTERVAL '1 day',
        NOW() - INTERVAL '1 day'
      ),
      (
        v_project_gamma,
        'Concrete Pump Rental',
        'Pump usage and operator charge',
        56000,
        v_bill_type_equipment,
        'paid',
        CURRENT_DATE - 4,
        CURRENT_DATE - 2,
        COALESCE(v_sm1, v_admin_id),
        v_admin_id,
        NOW() - INTERVAL '4 days',
        NOW() - INTERVAL '2 days'
      ),
      (
        v_project_gamma,
        'Aggregate Supply Bill',
        'Aggregate batch partial payment',
        34000,
        v_bill_type_materials,
        'pending',
        CURRENT_DATE - 1,
        CURRENT_DATE + 7,
        COALESCE(v_sm1, v_admin_id),
        NULL,
        NOW() - INTERVAL '1 day',
        NOW() - INTERVAL '1 day'
      ),
      (
        v_project_alpha,
        'Temporary Scaffold Expense',
        'Scaffold extra rental correction',
        18000,
        v_bill_type_equipment,
        'rejected',
        CURRENT_DATE - 2,
        CURRENT_DATE + 3,
        COALESCE(v_sm1, v_admin_id),
        v_admin_id,
        NOW() - INTERVAL '2 days',
        NOW() - INTERVAL '1 day'
      );
  END IF;

  IF v_has_bills_vendor_name THEN
    UPDATE public.bills b
    SET vendor_name = src.vendor_name
    FROM (
      VALUES
        (v_project_alpha, 'Workers Payment - Week 1', 'Ramesh Contractor'),
        (v_project_alpha, 'Material (Cement) Payment', 'UltraTech Cement Hub'),
        (v_project_beta, 'Steel Supply Advance', 'Shakti Steel Agency'),
        (v_project_beta, 'Transport Diesel Bill', 'Mr Earth Logistics'),
        (v_project_gamma, 'Concrete Pump Rental', 'Schwing Rentals'),
        (v_project_gamma, 'Aggregate Supply Bill', 'Sri Aggregate & Co'),
        (v_project_alpha, 'Temporary Scaffold Expense', 'Metro Steel Depot')
    ) AS src(project_id, title, vendor_name)
    WHERE b.project_id = src.project_id
      AND b.title = src.title;
  END IF;

  IF v_has_bills_receipt_url THEN
    UPDATE public.bills b
    SET receipt_url = src.receipt_path
    FROM (
      VALUES
        (v_project_alpha, 'Workers Payment - Week 1', 'demo/receipts/workers_alpha_w1.pdf'),
        (v_project_alpha, 'Material (Cement) Payment', 'demo/receipts/cement_alpha_paid.pdf'),
        (v_project_beta, 'Steel Supply Advance', 'demo/receipts/steel_beta_advance.pdf'),
        (v_project_beta, 'Transport Diesel Bill', 'demo/receipts/transport_beta_pending.pdf'),
        (v_project_gamma, 'Concrete Pump Rental', 'demo/receipts/pump_gamma_paid.pdf'),
        (v_project_gamma, 'Aggregate Supply Bill', 'demo/receipts/aggregate_gamma_pending.pdf'),
        (v_project_alpha, 'Temporary Scaffold Expense', 'demo/receipts/scaffold_alpha_rejected.pdf')
    ) AS src(project_id, title, receipt_path)
    WHERE b.project_id = src.project_id
      AND b.title = src.title;
  END IF;

  IF v_has_bills_image_url THEN
    UPDATE public.bills b
    SET image_url = src.receipt_path
    FROM (
      VALUES
        (v_project_alpha, 'Workers Payment - Week 1', 'demo/receipts/workers_alpha_w1.pdf'),
        (v_project_alpha, 'Material (Cement) Payment', 'demo/receipts/cement_alpha_paid.pdf'),
        (v_project_beta, 'Steel Supply Advance', 'demo/receipts/steel_beta_advance.pdf'),
        (v_project_beta, 'Transport Diesel Bill', 'demo/receipts/transport_beta_pending.pdf'),
        (v_project_gamma, 'Concrete Pump Rental', 'demo/receipts/pump_gamma_paid.pdf'),
        (v_project_gamma, 'Aggregate Supply Bill', 'demo/receipts/aggregate_gamma_pending.pdf'),
        (v_project_alpha, 'Temporary Scaffold Expense', 'demo/receipts/scaffold_alpha_rejected.pdf')
    ) AS src(project_id, title, receipt_path)
    WHERE b.project_id = src.project_id
      AND b.title = src.title;
  END IF;

  IF v_has_bills_image_path THEN
    UPDATE public.bills b
    SET image_path = src.receipt_path
    FROM (
      VALUES
        (v_project_alpha, 'Workers Payment - Week 1', 'demo/receipts/workers_alpha_w1.pdf'),
        (v_project_alpha, 'Material (Cement) Payment', 'demo/receipts/cement_alpha_paid.pdf'),
        (v_project_beta, 'Steel Supply Advance', 'demo/receipts/steel_beta_advance.pdf'),
        (v_project_beta, 'Transport Diesel Bill', 'demo/receipts/transport_beta_pending.pdf'),
        (v_project_gamma, 'Concrete Pump Rental', 'demo/receipts/pump_gamma_paid.pdf'),
        (v_project_gamma, 'Aggregate Supply Bill', 'demo/receipts/aggregate_gamma_pending.pdf'),
        (v_project_alpha, 'Temporary Scaffold Expense', 'demo/receipts/scaffold_alpha_rejected.pdf')
    ) AS src(project_id, title, receipt_path)
    WHERE b.project_id = src.project_id
      AND b.title = src.title;
  END IF;

  IF v_has_bills_raised_by THEN
    UPDATE public.bills
    SET raised_by = created_by
    WHERE project_id IN (v_project_alpha, v_project_beta, v_project_gamma)
      AND raised_by IS NULL;
  END IF;

  IF v_has_bills_payment_type THEN
    UPDATE public.bills
    SET payment_type = CASE
      WHEN title ILIKE '%Workers%' THEN 'cash'
      WHEN title ILIKE '%Transport%' THEN 'upi'
      WHEN title ILIKE '%Rental%' OR title ILIKE '%Pump%' THEN 'cheque'
      ELSE 'bank_transfer'
    END
    WHERE project_id IN (v_project_alpha, v_project_beta, v_project_gamma);
  END IF;

  IF v_has_bills_payment_status THEN
    UPDATE public.bills
    SET payment_status = CASE
      WHEN status = 'paid' THEN 'full_paid'
      WHEN status = 'approved' THEN 'half_paid'
      WHEN status = 'pending' THEN 'advance'
      WHEN status = 'rejected' THEN 'need_to_pay'
      ELSE 'need_to_pay'
    END
    WHERE project_id IN (v_project_alpha, v_project_beta, v_project_gamma);
  END IF;

  IF v_has_bills_approved_at THEN
    UPDATE public.bills
    SET approved_at = CASE
      WHEN status IN ('approved', 'paid', 'rejected') THEN updated_at
      ELSE NULL
    END
    WHERE project_id IN (v_project_alpha, v_project_beta, v_project_gamma);
  END IF;

  -- ----------------------------------------------------------
  -- Operation logs (activity feed)
  -- ----------------------------------------------------------
  INSERT INTO public.operation_logs (
    user_id, project_id, operation_type, entity_type,
    entity_id, title, description, metadata, created_at
  ) VALUES
    (v_admin_id, v_project_alpha, 'create', 'project', v_project_alpha,
      'Project created: Skyline Residency Phase 2',
      'Admin created residential project',
      '{"source":"demo_seed"}'::jsonb,
      NOW() - INTERVAL '9 days'),

    (COALESCE(v_sm1, v_admin_id), v_project_alpha, 'create', 'stock', v_item_alpha_steel18,
      'Material inward: Steel 18mm',
      '45 Tons received from AA Steel Traders',
      '{"log_type":"inward","quantity":45}'::jsonb,
      NOW() - INTERVAL '6 days'),

    (COALESCE(v_sm1, v_admin_id), v_project_alpha, 'update', 'stock', v_item_alpha_cement_opc,
      'Material outward: Cement OPC 53',
      '350 bags consumed for slab casting',
      '{"log_type":"outward","quantity":350}'::jsonb,
      NOW() - INTERVAL '4 days'),

    (COALESCE(v_sm2, v_sm1, v_admin_id), v_project_beta, 'create', 'machinery', v_machine_crane,
      'Machinery usage logged',
      'Crane used for steel girder lifting',
      '{"hours":5.5}'::jsonb,
      NOW() - INTERVAL '5 days'),

    (COALESCE(v_sm2, v_sm1, v_admin_id), v_project_beta, 'status_change', 'project', v_project_beta,
      'Project status updated',
      'Project moved to in_progress',
      '{"from":"planning","to":"in_progress"}'::jsonb,
      NOW() - INTERVAL '4 days'),

    (COALESCE(v_sm1, v_admin_id), v_project_gamma, 'create', 'labour',
      (SELECT id FROM public.labour WHERE project_id = v_project_gamma ORDER BY created_at LIMIT 1),
      'Labour team onboarded',
      'Initial labour team added for service road package',
      '{"team_size":2}'::jsonb,
      NOW() - INTERVAL '3 days'),

    (COALESCE(v_sm1, v_admin_id), v_project_gamma, 'update', 'attendance',
      (SELECT id FROM public.labour_attendance WHERE project_id = v_project_gamma ORDER BY created_at DESC LIMIT 1),
      'Attendance marked',
      'Daily labour attendance updated',
      '{"date":"today"}'::jsonb,
      NOW() - INTERVAL '1 day'),

    (v_admin_id, v_project_alpha, 'upload', 'report', NULL,
      'Weekly report uploaded',
      'Admin uploaded consolidated weekly report',
      '{"period":"weekly"}'::jsonb,
      NOW() - INTERVAL '12 hours');

  RAISE NOTICE 'Demo seed complete: projects=3, suppliers=9, stock_items=10, material_logs=21, bills=7.';
END $$;

-- Quick post-seed summary
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
UNION ALL SELECT 'operation_logs', COUNT(*)::bigint FROM public.operation_logs;
