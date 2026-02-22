# Database Changes Log

## Migration 042: Fix Material Grades Duplicate Key Error (2026-02-06)

### Problem
Adding materials with different grade name formats (e.g., "18 MM" vs "18MM") caused duplicate key violations on `uq_material_grade_key` constraint.

### Root Cause
- `material_grades.grade_key` is a GENERATED column: `lower(regexp_replace(trim(grade_name), '\s+', '', 'g'))`
- Both "18MM" and "18 MM" normalize to the same `grade_key = "18mm"`
- The `sync_material_master()` function used `ON CONFLICT (material_id, grade_name)` which doesn't match the actual unique constraint

### Changes Applied

#### Function Fixed
- **Function**: `sync_material_master()`
- **Change**: Updated to use `ON CONFLICT ON CONSTRAINT uq_material_grade_key`
- **Impact**: Materials with different spacing in grades (e.g., "18MM" vs "18 MM") now correctly reference the same grade entry

### Testing Results
✅ Adding Steel with "18 MM" now succeeds  
✅ No duplicate entries created in `material_grades`  
✅ UPSERT correctly handles grade normalization

### Impact
- **Breaking**: None (backward compatible)
- **Security**: Improved (added search_path protection)
- **Data Integrity**: Improved (prevents duplicate grades)

### Deployment
- **Date**: 2026-02-06 15:05 UTC
- **Applied To**: Production (fhochkjwsmwuiiqqdupa)
- **Migration File**: `042_fix_material_grades_upsert.sql`

---

## Migration 041: Fix Material Addition Issues (2026-02-06)

### Problem
Users were unable to add materials to projects, receiving 400 Bad Request errors when calling the `receive_material` RPC function.

### Root Causes
1. **RPC Function**: Used manual IF/ELSE logic prone to race conditions
2. **Trigger Function**: `update_vendor_materials()` referenced wrong constraint (missing `project_id`)
3. **Schema**: `stock_items.grade` had NOT NULL constraint preventing materials without grades

### Changes Applied

#### 1. Schema Change
```sql
ALTER TABLE public.stock_items ALTER COLUMN grade DROP NOT NULL;
```
**Reason**: Materials like Sand, Gravel don't have grades, so NULL must be allowed.

#### 2. RPC Function Replaced
- **Function**: `receive_material()`
- **Change**: Replaced manual IF/ELSE with atomic UPSERT using `ON CONFLICT`
- **Added**: `SET search_path = public, pg_temp` security fix
- **Added**: Empty string to NULL conversion for grades

#### 3. Trigger Function Fixed
- **Function**: `update_vendor_materials()`
- **Change**: Added missing `project_id` column in vendor_materials UPSERT
- **Fixed**: Constraint reference to use `uq_vendor_materials_unique`
- **Added**: `SET search_path = public, pg_temp` security fix

### Testing Results
✅ All tests passed:
- New material addition with grade
- Quantity accumulation for existing materials (100 + 50 = 150)
- NULL grade handling

### Impact
- **Breaking**: None (backward compatible)
- **Security**: Improved (added search_path protection)
- **Performance**: Improved (atomic operations vs manual IF/ELSE)

### Deployment
- **Date**: 2026-02-06 14:38 UTC
- **Applied To**: Production (fhochkjwsmwuiiqqdupa)
- **Migration File**: `041_fix_material_addition.sql`

---

## Previous Migrations

See individual migration files in `/migrations` directory (001-040).
