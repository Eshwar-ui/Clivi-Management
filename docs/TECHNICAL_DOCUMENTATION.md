# Civil Management App - Technical Documentation

> **Version:** 1.0 | **Last Updated:** February 2026  
> **Stack:** Flutter + Supabase (PostgreSQL + Auth + Storage)

---

## 1️⃣ System Overview

### Purpose
Civil Management is a mobile application for **construction site management** enabling:
- Project tracking and progress monitoring
- Labour/workforce management and attendance
- Material/stock inventory control
- Blueprint document management
- Daily operational logging

### Roles
| Role | Description |
|------|-------------|
| **Super Admin** | Full system access, can manage admins |
| **Admin** | Manages projects, assigns site managers, views all data |
| **Site Manager** | Manages assigned projects only, logs daily operations |

### Application Flow
```
Login → Dashboard → Select Project → Daily Operations → Reports
           ↓
     • Materials (Stock)
     • Labour (Attendance)
     • Blueprints
     • Daily Logs
```

### Flutter ↔ Supabase Communication
- **Authentication:** `supabase.auth` for login/session
- **Database:** `supabase.from('table_name')` with RLS enforcement
- **Storage:** `supabase.storage` for file uploads
- **RPC Functions:** `supabase.rpc()` for dashboard stats

---

## 2️⃣ Authentication Architecture

### 2.1 Supabase Auth Flow
```
User Signs Up → auth.users record created
                     ↓
              Trigger: on_auth_user_created
                     ↓
              user_profiles row auto-created (role: site_manager)
```

**Flutter Implementation:**
```dart
// Sign In
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

// Get current session
final session = supabase.auth.currentSession;

// Listen to auth changes
supabase.auth.onAuthStateChange.listen((event) {
  // Handle login/logout
});
```

### 2.2 user_profiles Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | References auth.users(id) |
| `role` | TEXT | 'super_admin', 'admin', 'site_manager' |
| `full_name` | TEXT | Display name |
| `phone` | TEXT | Contact number |
| `email` | TEXT | Email (from auth.users) |
| `company_id` | TEXT | Company identifier |
| `avatar_url` | TEXT | Profile image URL |
| `created_at` | TIMESTAMPTZ | Account creation time |

**Why Separate from auth.users?**
- RLS can't be applied to auth.users
- Custom fields (role, phone) not in auth schema
- Allows role-based access control

---

## 3️⃣ Role & Permission Model

### Super Admin
| Area | Permissions |
|------|-------------|
| Users | Create/Edit/Delete all users |
| Projects | Full CRUD on all projects |
| Data | View all operational data |
| Reports | Access all analytics |

### Admin
| Area | Permissions |
|------|-------------|
| Users | Create Site Managers only |
| Projects | Create/Edit/Delete projects, assign managers |
| Data | View all projects and operations |
| Blueprints | Upload/Delete for any project |

### Site Manager
| Area | Permissions |
|------|-------------|
| Projects | View assigned projects only |
| Labour | Add/Edit workers, mark attendance |
| Stock | Log material inward/outward |
| Blueprints | Upload/View for assigned projects |
| Reports | Submit daily logs |

### RLS Enforcement Pattern
```sql
-- Helper function used in all RLS policies
CREATE FUNCTION is_assigned_to_project(p_project_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM project_assignments
    WHERE user_id = auth.uid() AND project_id = p_project_id
  )
$$ LANGUAGE sql SECURITY DEFINER;
```

---

## 4️⃣ Database Schema

### Complete Table List

| Table | Purpose | Status |
|-------|---------|--------|
| `user_profiles` | User data & roles | ✅ Working |
| `projects` | Construction projects | ✅ Working |
| `project_assignments` | Manager↔Project links | ✅ Working |
| `stock_items` | Material inventory | ✅ Working |
| `material_logs` | Stock inward/outward | ✅ Working |
| `labour` | Worker profiles | ✅ Working |
| `labour_attendance` | Daily attendance | ✅ Working |
| `machinery` | Equipment registry | ✅ Schema exists |
| `blueprints` | Project documents | ✅ Working |
| `bills` | Expenses/invoices | ✅ Schema exists |
| `daily_reports` | Daily site logs | ✅ Schema exists |
| `operation_logs` | Activity feed | ✅ Working |

---

## 5️⃣ Core Tables - Detailed

### 5.1 projects

| Column | Type | Description | Flutter Screen |
|--------|------|-------------|----------------|
| `id` | UUID | Primary key | All project screens |
| `name` | TEXT | Project name | List, Detail |
| `client_name` | TEXT | Client/owner name | Detail, Create |
| `project_type` | TEXT | Residential/Commercial/etc | List, Detail |
| `description` | TEXT | Details | Detail |
| `location` | TEXT | Site address | List, Detail |
| `status` | TEXT | planning/in_progress/completed | Filter, Dashboard |
| `progress` | INT | 0-100 percentage | Progress bar |
| `start_date` | DATE | Project start | Timeline |
| `end_date` | DATE | Expected end | Timeline |
| `budget` | DECIMAL | Total budget | Detail |
| `deleted_at` | TIMESTAMPTZ | Soft delete | Hidden if set |
| `created_by` | UUID | Creator user | Audit |
| `created_at` | TIMESTAMPTZ | Creation time | - |

**RLS Summary:**
- Admins: View all (where `deleted_at IS NULL`)
- Site Managers: View assigned only via `project_assignments`

### 5.2 project_assignments

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `project_id` | UUID | FK → projects |
| `user_id` | UUID | FK → user_profiles |
| `assigned_role` | TEXT | 'manager', 'member', 'viewer' |
| `assigned_at` | TIMESTAMPTZ | When assigned |
| `assigned_by` | UUID | Who assigned |

**Unique Constraint:** `(project_id, user_id)`

### 5.3 stock_items

| Column | Type | Description | Flutter Screen |
|--------|------|-------------|----------------|
| `id` | UUID | Primary key | - |
| `name` | TEXT | Material name | Stock List |
| `category` | TEXT | Grouping | Filter |
| `unit` | TEXT | kg/bags/pieces | All |
| `quantity` | DECIMAL | Current stock | Stock Card |
| `low_stock_threshold` | DECIMAL | Alert level | Dashboard |
| `unit_price` | DECIMAL | Cost per unit | Reports |
| `project_id` | UUID | FK → projects | Scoped |

### 5.4 material_logs

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `project_id` | UUID | FK → projects |
| `item_id` | UUID | FK → stock_items |
| `log_type` | TEXT | 'inward' or 'outward' |
| `quantity` | DECIMAL | Amount moved |
| `activity` | TEXT | What material was used for |
| `challan_url` | TEXT | Receipt image URL |
| `logged_by` | UUID | Recording user |
| `logged_at` | TIMESTAMPTZ | When logged |
| `notes` | TEXT | Additional info |

### 5.5 labour

| Column | Type | Description | Flutter Screen |
|--------|------|-------------|----------------|
| `id` | UUID | Primary key | - |
| `name` | TEXT | Worker name | Roster |
| `phone` | TEXT | Contact | Detail |
| `skill_type` | TEXT | Mason/Helper/etc | Filter |
| `daily_wage` | DECIMAL | Wage rate | Cost calc |
| `project_id` | UUID | FK → projects | Scoped |
| `status` | TEXT | 'active' or 'inactive' | Filter |

### 5.6 labour_attendance

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `labour_id` | UUID | FK → labour |
| `project_id` | UUID | FK → projects |
| `date` | DATE | Attendance date |
| `status` | TEXT | 'present', 'absent', 'half_day' |
| `hours_worked` | DECIMAL | Hours logged |
| `notes` | TEXT | Remarks |
| `recorded_by` | UUID | Who marked |

**Unique Constraint:** `(labour_id, date)`

### 5.7 blueprints

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `project_id` | UUID | FK → projects |
| `title` | TEXT | File name |
| `folder_name` | TEXT | Grouping folder |
| `file_url` | TEXT | Storage URL |
| `file_type` | TEXT | pdf/jpg/png |
| `file_size` | INTEGER | Bytes |
| `version` | TEXT | Version number |
| `uploaded_by` | UUID | Uploader |

### 5.8 operation_logs

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Who performed |
| `project_id` | UUID | Related project |
| `operation_type` | TEXT | create/update/delete/upload |
| `entity_type` | TEXT | project/stock/labour/etc |
| `entity_id` | UUID | Affected record |
| `title` | TEXT | Log title |
| `description` | TEXT | Details |
| `created_at` | TIMESTAMPTZ | When occurred |

---

## 6️⃣ Project Lifecycle

### 6.1 Admin Creates Project

**Flutter Form Fields:**
```dart
// Required
String name         // min 3 chars
String location     // Site address
DateTime startDate  // Cannot be in past
String status       // Default: 'planning'

// Optional
String clientName
String projectType  // Residential/Commercial/etc
String description
DateTime endDate    // Must be after startDate
double budget       // > 0
```

**Database Insert:**
```dart
await supabase.from('projects').insert({
  'name': name,
  'client_name': clientName,
  'project_type': projectType,
  'location': location,
  'status': 'planning',
  'start_date': startDate.toIso8601String().split('T').first,
  'end_date': endDate?.toIso8601String().split('T').first,
  'budget': budget,
  'created_by': currentUserId,
});
```

### 6.2 Assign Site Manager

**Process:**
1. Admin opens project → Assign Managers sheet
2. Fetches all users with `role = 'site_manager'`
3. Toggles selection
4. Saves to `project_assignments`

```dart
// Add assignment
await supabase.from('project_assignments').insert({
  'project_id': projectId,
  'user_id': managerId,
  'assigned_role': 'manager',
  'assigned_by': currentUserId,
});
```

**Common Failures:**
- Duplicate assignment → Caught by unique constraint
- User not site_manager → UI should filter

### 6.3 Site Manager Project Access

**What Flutter Shows:**
```dart
// Fetch only assigned projects
final response = await supabase
  .from('projects')
  .select('*, project_assignments!inner(*)')
  .eq('project_assignments.user_id', currentUserId);
```

**Backend Enforcement:**
RLS policy automatically filters - manager cannot query unassigned projects.

---

## 7️⃣ Stock Management Module

### 7.1 Stock Master (Admin)
- Define materials for each project
- Set unit, category, low stock threshold
- View aggregated stock across projects

### 7.2 Daily Stock Logs (Site Manager)
- Log **Inward** (received materials with challan)
- Log **Outward** (consumed materials with activity)
- Each log updates `stock_items.quantity`

### 7.3 Balance Calculation
```sql
-- Current balance = Sum(inward) - Sum(outward)
SELECT 
  SUM(CASE WHEN log_type = 'inward' THEN quantity ELSE -quantity END)
FROM material_logs 
WHERE item_id = ?
```

### 7.4 Flutter UI

| Screen | Features |
|--------|----------|
| Stock List | Cards with quantity, low stock warning |
| Add Stock | Material selection, quantity, vendor |
| Log Material | Inward/Outward toggle, activity field |
| Material History | Chronological log entries |

### 7.5 ⚠️ Missing Schema Items
- `entry_type` column needed on `stock_items` for received/consumed tracking per RPC
- Vendor table for supplier management

---

## 8️⃣ Labour Management Module

### 8.1 Labour Profile Creation
```dart
await supabase.from('labour').insert({
  'name': name,
  'phone': phone,
  'skill_type': 'mason', // mason/helper/supervisor
  'daily_wage': 800.00,
  'project_id': projectId,
  'status': 'active',
  'created_by': currentUserId,
});
```

### 8.2 Daily Attendance Logging
- Site Manager marks attendance for project workers
- Status: present / absent / half_day
- Can add hours worked and notes

```dart
await supabase.from('labour_attendance').upsert({
  'labour_id': labourId,
  'project_id': projectId,
  'date': DateTime.now().toIso8601String().split('T').first,
  'status': 'present',
  'hours_worked': 8,
  'recorded_by': currentUserId,
});
```

### 8.3 Wage Calculation
```dart
// Daily cost = workers present × daily_wage
final totalCost = workers
  .where((w) => w.status == 'present')
  .fold(0.0, (sum, w) => sum + w.dailyWage);
```

### 8.4 Flutter Validation
- Name: Required, min 2 chars
- Phone: Optional, 10 digits
- Daily wage: Required, ≥ 0
- Attendance date: Cannot be future

---

## 9️⃣ Daily Logs & Media

### Daily Reports Table
```sql
daily_reports (
  project_id, report_date, weather,
  work_summary, issues, tomorrow_plan,
  labour_count, created_by
)
```

### Photo/Document Uploads
- Stored in Supabase Storage buckets: `blueprints`, `receipts`
- File path: `{bucket}/{project_id}/{folder}/{filename}`

### Edit Restrictions
- Site Managers can only edit current day logs
- Past logs become read-only

---

## 🔐 10. Row Level Security Deep Dive

### Why RLS is Critical
- Enforces multi-tenancy at database level
- Prevents data leaks even if Flutter code is compromised
- Project-scoped access for site managers

### RLS Patterns Used

**Pattern 1: Admin Full Access**
```sql
CREATE POLICY "Admins can manage all"
ON table FOR ALL
USING (is_admin_or_super());
```

**Pattern 2: Project-Scoped Access**
```sql
CREATE POLICY "Site managers view assigned"
ON table FOR SELECT
USING (is_assigned_to_project(project_id));
```

### Common Mistakes
| Mistake | Impact | Fix |
|---------|--------|-----|
| Missing WITH CHECK | Can insert to wrong project | Add WITH CHECK clause |
| Using OR instead of separate policies | Permission escalation | Use separate policies |
| Forgetting SECURITY DEFINER | Function runs as user | Add SECURITY DEFINER |

### Flutter Error Signatures
| Error | Cause |
|-------|-------|
| `"new row violates RLS"` | Insert blocked by policy |
| `"permission denied for table"` | RLS enabled, no matching policy |
| Empty result set | SELECT filtered by RLS |

---

## ⚠️ 11. Issues & Improvements

### 🔴 Critical Issues

| Issue | Impact | Fix |
|-------|--------|-----|
| `projects` missing soft delete filter in some queries | Deleted projects may appear | Apply `deleted_at IS NULL` everywhere |
| No `vendors` table | Can't track suppliers | Create vendors table |
| No optimistic locking | Concurrent edit conflicts | Add `version` column |

### 🟡 Performance Issues

| Issue | Impact | Fix |
|-------|--------|-----|
| N+1 queries in project list | Slow loading | Use JOIN for assignments |
| No pagination | Memory issues | Implement cursor pagination |
| No caching | Repeated API calls | Implement Hive cache |

### 🟢 Schema Improvements Needed

| Table | Missing | Purpose |
|-------|---------|---------|
| `projects` | `client_name`, `project_type`, `progress` | Project metadata |
| `stock_items` | `entry_type` | Track received vs consumed |
| `vendors` | New table | Supplier management |
| `machinery_logs` | New table | Equipment usage tracking |

---

## 🧩 12. Entity Relationship Diagram

```
┌─────────────────┐
│   auth.users    │
└────────┬────────┘
         │ 1:1
         ▼
┌─────────────────┐        ┌─────────────────┐
│  user_profiles  │◄──────►│    projects     │
└────────┬────────┘  N:M   └────────┬────────┘
         │                          │ 1:N
         │                          ▼
         │                 ┌─────────────────┐
         ├────────────────►│project_assignments│
         │                 └─────────────────┘
         │                          │
         │                          ▼
    ┌────┴────┬────────────────────┬────────────────┐
    ▼         ▼                    ▼                ▼
┌───────┐ ┌───────────┐    ┌──────────────┐  ┌───────────┐
│labour │ │stock_items│    │  blueprints  │  │daily_reports│
└───┬───┘ └─────┬─────┘    └──────────────┘  └───────────┘
    │           │
    ▼           ▼
┌──────────┐ ┌─────────────┐
│attendance│ │material_logs│
└──────────┘ └─────────────┘
```

---

## 🚀 13. Flutter Development Guidelines

### Repository Pattern
```dart
class ProjectRepository {
  final SupabaseClient _client;
  
  Future<List<Project>> getProjects() async {
    final response = await _client
      .from('projects')
      .select('*, project_assignments(*, user_profiles(*))')
      .order('created_at', ascending: false);
    return response.map(Project.fromJson).toList();
  }
}
```

### Error Handling
```dart
try {
  await repository.createProject(project);
} on PostgrestException catch (e) {
  if (e.code == '42501') {
    // RLS violation
    showError('Permission denied');
  } else if (e.code == '23505') {
    // Unique violation
    showError('Already exists');
  }
}
```

### Security Best Practices
| Do ✅ | Don't ❌ |
|-------|---------|
| Trust RLS for access control | Implement access control in Flutter only |
| Use service role key server-side only | Expose service role key in Flutter |
| Validate input before API call | Trust backend to catch all errors |
| Use parameterized queries | Build SQL strings manually |

---

## 📎 14. Appendix

### Naming Conventions
| Entity | Convention | Example |
|--------|------------|---------|
| Tables | snake_case, plural | `stock_items` |
| Columns | snake_case | `created_at` |
| Functions | snake_case | `get_dashboard_stats` |
| Flutter Models | PascalCase | `ProjectModel` |

### Required Indexes
```sql
-- Already created
idx_projects_deleted_at
idx_labour_project
idx_stock_project
idx_material_logs_project
idx_operation_logs_created
```

### Migration Order (Apply in Supabase)
1. `001_initial_schema.sql` - Core tables
2. `003_add_blueprints.sql` - Blueprint enhancements
3. `006_fix_signup_trigger.sql` - Auth trigger fix
4. `011_material_logs.sql` - Material tracking
5. `013_fix_labour_stock_rls.sql` - RLS policies
6. `014_add_user_profile_columns.sql` - Profile fields
7. `015_dashboard_schema.sql` - Dashboard RPCs
8. `016_update_projects.sql` - Soft delete + project stats

### Storage Buckets
| Bucket | Purpose | Public |
|--------|---------|--------|
| `avatars` | Profile images | Yes |
| `blueprints` | Project documents | No |
| `receipts` | Material challans | No |

---

## 📋 Quick Reference Card

### Common Queries

**Get assigned projects (Site Manager):**
```dart
supabase.from('projects').select('*').eq('deleted_at', null)
```

**Log material inward:**
```dart
supabase.from('material_logs').insert({
  'project_id': projectId,
  'item_id': itemId,
  'log_type': 'inward',
  'quantity': 100,
  'logged_by': userId,
})
```

**Mark attendance:**
```dart
supabase.from('labour_attendance').upsert({
  'labour_id': labourId,
  'project_id': projectId,
  'date': today,
  'status': 'present',
})
```

**Get dashboard stats:**
```dart
supabase.rpc('get_dashboard_stats')
```

---

*Document maintained by development team. Update when schema changes.*
