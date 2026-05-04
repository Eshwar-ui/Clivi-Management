# Supabase Database Schema Documentation

> **Last Updated:** February 2026 | **Total Migrations:** 16

---

## Quick Reference - Migration Files

| # | File | Purpose | Status |
|---|------|---------|--------|
| 001 | `001_initial_schema.sql` | Core tables: users, projects, stock, labour, machinery, bills, blueprints | ✅ Applied |
| 002 | `002_fix_rls_policies.sql` | Fix RLS infinite recursion with SECURITY DEFINER functions | ✅ Applied |
| 003 | `003_add_blueprints.sql` | Blueprint folder structure + storage policies | ✅ Applied |
| 004 | `004_fix_table_name.sql` | Rename `profiles` → `user_profiles` | ✅ Applied |
| 005 | `005_add_missing_columns.sql` | Add budget, dates, location to projects | ✅ Applied |
| 006 | `006_fix_signup_trigger.sql` | Fix "Database error saving new user" | ✅ Applied |
| 007 | `007_indexes_soft_deletes_realtime.sql` | Performance indexes, realtime | ✅ Applied |
| 008 | `008_production_indexes.sql` | Cursor pagination indexes | ✅ Applied |
| 009 | `009_fix_admin_user_management.sql` | Allow admins to create site managers | ✅ Applied |
| 010 | `010_storage_policies.sql` | Blueprints/bills bucket policies | ✅ Applied |
| 011 | `011_material_logs.sql` | Stock tracking + material_logs table | ✅ Applied |
| 012 | `012_seed_admin_users.sql` | Create admin/super_admin users | Manual |
| 013 | `013_fix_labour_stock_rls.sql` | Fixed RLS for labour, stock, logs | ✅ Applied |
| 014 | `014_add_user_profile_columns.sql` | Add email, company_id to profiles | ✅ Applied |
| 015 | `015_dashboard_schema.sql` | operation_logs + dashboard RPCs | ✅ Applied |
| 016 | `016_update_projects.sql` | Soft delete + project RPCs | ⏳ Pending |

---

## Database Tables

### Core Tables

```
┌───────────────────────────────────────────────────────────────┐
│                        auth.users                              │
│  (Supabase managed - email, password, metadata)               │
└───────────────────────┬───────────────────────────────────────┘
                        │ 1:1 (via trigger)
                        ▼
┌───────────────────────────────────────────────────────────────┐
│                     user_profiles                              │
│  id, role, full_name, email, phone, avatar_url, company_id    │
└───────────────────────────────────────────────────────────────┘
```

### Project Ecosystem

```
┌─────────────────┐       ┌─────────────────────────┐
│    projects     │◄──────│  project_assignments    │
│                 │  1:N  │  (project_id, user_id)  │
└────────┬────────┘       └─────────────────────────┘
         │ 1:N
         ├──────────────────────────────────────────┐
         │                                          │
         ▼                                          ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   stock_items   │  │     labour      │  │   blueprints    │
└────────┬────────┘  └────────┬────────┘  └─────────────────┘
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌─────────────────────┐
│  material_logs  │  │  labour_attendance  │
└─────────────────┘  └─────────────────────┘
```

---

## Table Schemas

### 1. user_profiles

```sql
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    role TEXT NOT NULL DEFAULT 'site_manager' 
         CHECK (role IN ('super_admin', 'admin', 'site_manager')),
    full_name TEXT,
    email TEXT,
    phone TEXT,
    avatar_url TEXT,
    company_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Auto-creation:** Trigger `on_auth_user_created` → `handle_new_user()` creates profile on signup.

---

### 2. projects

```sql
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    client_name TEXT,                    -- Added in 016
    project_type TEXT CHECK (project_type IN 
        ('Residential', 'Commercial', 'Infrastructure', 'Industrial')),
    description TEXT,
    location TEXT,
    status TEXT DEFAULT 'planning' CHECK (status IN 
        ('planning', 'in_progress', 'on_hold', 'completed', 'cancelled')),
    progress INT DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(15, 2),
    created_by UUID REFERENCES user_profiles(id),
    deleted_at TIMESTAMPTZ,              -- Soft delete
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 3. project_assignments

```sql
CREATE TABLE project_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    assigned_role TEXT DEFAULT 'manager' 
         CHECK (assigned_role IN ('manager', 'member', 'viewer')),
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    assigned_by UUID REFERENCES user_profiles(id),
    UNIQUE(project_id, user_id)
);
```

---

### 4. stock_items

```sql
CREATE TABLE stock_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    unit TEXT DEFAULT 'units',
    quantity DECIMAL(15, 2) DEFAULT 0,
    min_quantity DECIMAL(15, 2) DEFAULT 0,
    low_stock_threshold DECIMAL DEFAULT 10,
    unit_price DECIMAL(15, 2),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 5. material_logs

```sql
CREATE TABLE material_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES stock_items(id) ON DELETE CASCADE,
    log_type TEXT NOT NULL CHECK (log_type IN ('inward', 'outward')),
    quantity DECIMAL NOT NULL CHECK (quantity > 0),
    activity TEXT,
    challan_url TEXT,
    logged_by UUID REFERENCES auth.users(id),
    logged_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 6. labour

```sql
CREATE TABLE labour (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    skill_type TEXT,
    daily_wage DECIMAL(10, 2),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 7. labour_attendance

```sql
CREATE TABLE labour_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    labour_id UUID NOT NULL REFERENCES labour(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status TEXT DEFAULT 'present' CHECK (status IN ('present', 'absent', 'half_day')),
    hours_worked DECIMAL(4, 2),
    notes TEXT,
    recorded_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(labour_id, date)
);
```

---

### 8. blueprints

```sql
CREATE TABLE blueprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    folder_name TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL UNIQUE,
    is_admin_only BOOLEAN DEFAULT false,
    uploader_id UUID REFERENCES auth.users(id),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 9. operation_logs

```sql
CREATE TABLE operation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    operation_type TEXT NOT NULL CHECK (operation_type IN 
        ('create', 'update', 'delete', 'upload', 'status_change')),
    entity_type TEXT NOT NULL CHECK (entity_type IN 
        ('project', 'stock', 'labour', 'blueprint', 'machinery', 'attendance', 'report')),
    entity_id UUID,
    title TEXT NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### Other Tables

| Table | Purpose | Reference |
|-------|---------|-----------|
| `machinery` | Equipment registry | 001 |
| `bills` | Expenses/invoices | 001 |
| `daily_reports` | Daily site reports | 001 |

---

## Helper Functions

### Role Checking Functions

```sql
-- Check if current user is admin/super_admin
get_my_role() RETURNS TEXT
is_admin_or_super() RETURNS BOOLEAN
is_super_admin() RETURNS BOOLEAN
is_assigned_to_project(project_id UUID) RETURNS BOOLEAN
```

### Dashboard RPC Functions

```sql
-- Get dashboard statistics
get_dashboard_stats(user_id UUID) RETURNS JSON
-- Returns: active_projects, total_projects, total_workers, low_stock_items, etc.

-- Get recent activity feed  
get_recent_activity(limit INT, offset INT, project_id UUID) RETURNS JSON

-- Get active projects summary
get_active_projects_summary(limit INT) RETURNS JSON

-- Log operation (for activity tracking)
log_operation(type, entity_type, entity_id, title, desc, project_id) RETURNS UUID
```

### Project RPC Functions

```sql
-- Get project statistics
get_project_stats(project_id UUID) RETURNS JSON
-- Returns: material_received, material_consumed, labor_count, etc.

-- Get material breakdown by type
get_project_material_breakdown(project_id UUID) RETURNS JSON

-- Soft delete a project
soft_delete_project(project_id UUID) RETURNS BOOLEAN

-- Update progress with auto status transition
update_project_progress(project_id UUID, progress INT) RETURNS BOOLEAN
```

---

## RLS Policies Summary

### user_profiles
| Operation | Who | Policy |
|-----------|-----|--------|
| SELECT | Self | `auth.uid() = id` |
| SELECT | Admin | `is_admin_or_super()` |
| INSERT | Self/Admin | `auth.uid() = id OR is_admin_or_super()` |
| UPDATE | Self/Admin | `auth.uid() = id OR is_admin_or_super()` |
| DELETE | Super Admin | `is_super_admin()` |

### projects
| Operation | Who | Policy |
|-----------|-----|--------|
| SELECT | Admin | `deleted_at IS NULL AND is_admin_or_super()` |
| SELECT | Manager | `deleted_at IS NULL AND assigned via project_assignments` |
| INSERT | Admin | `is_admin_or_super()` |
| UPDATE | Admin | `is_admin_or_super()` |
| DELETE | Super Admin | `is_super_admin()` |

### stock_items / labour / material_logs / attendance
| Operation | Who | Policy |
|-----------|-----|--------|
| ALL | Admin | `is_admin_or_super()` |
| SELECT | Manager | `is_assigned_to_project(project_id)` |
| INSERT | Manager | `is_assigned_to_project(project_id)` |
| UPDATE | Manager | `is_assigned_to_project(project_id)` |
| DELETE | Manager | `is_assigned_to_project(project_id)` |

---

## Storage Buckets

| Bucket | Public | Purpose |
|--------|--------|---------|
| `avatars` | ✅ | Profile images |
| `blueprints` | ❌ | Project documents |
| `bills` | ❌ | Receipt images |
| `receipts` | ❌ | Material challans |

### Storage Path Format
```
blueprints/{project_id}/{folder_name}/{file_name}
bills/{project_id}/{bill_id}/{file_name}
```

---

## Indexes Created

### Performance Indexes
```sql
idx_projects_status
idx_projects_created_at
idx_projects_cursor (created_at DESC, id DESC)
idx_project_assignments_user_id
idx_project_assignments_composite (user_id, project_id)
idx_blueprints_project_folder
idx_user_profiles_role
idx_labour_project
idx_stock_project
idx_material_logs_project
idx_operation_logs_created
```

---

## Triggers

| Trigger | Table | Function | Purpose |
|---------|-------|----------|---------|
| `on_auth_user_created` | auth.users | `handle_new_user()` | Auto-create profile on signup |
| `update_*_updated_at` | Multiple | `update_updated_at_column()` | Auto-update timestamp |
| `trigger_log_project_changes` | projects | `log_project_changes()` | Log project operations |
| `trigger_log_blueprint_upload` | blueprints | `log_blueprint_upload()` | Log uploads |

---

## Known Issues & Fixes

| Issue | Migration | Status |
|-------|-----------|--------|
| RLS infinite recursion | 002, 004 | ✅ Fixed |
| "Database error saving new user" | 006 | ✅ Fixed |
| Admins can't create site managers | 009 | ✅ Fixed |
| Missing `entry_type` in stock_items | 016 RPC | ⚠️ Needs fix |

---

## Migration Application Order

```bash
# Apply in order (skip if already applied)
001_initial_schema.sql
002_fix_rls_policies.sql  
003_add_blueprints.sql
004_fix_table_name.sql
005_add_missing_columns.sql
006_fix_signup_trigger.sql
007_indexes_soft_deletes_realtime.sql
008_production_indexes.sql
009_fix_admin_user_management.sql
010_storage_policies.sql
011_material_logs.sql
012_seed_admin_users.sql  # Manual: create users first in Auth
013_fix_labour_stock_rls.sql
014_add_user_profile_columns.sql
015_dashboard_schema.sql
016_update_projects.sql  # ⏳ PENDING - Apply this next
```

---

*Apply migrations in Supabase SQL Editor: Dashboard → SQL Editor → New Query*
