-- ============================================================
-- MIGRATION 008: PRODUCTION PERFORMANCE INDEXES
-- Cursor pagination and RLS optimization
-- ============================================================

-- ============================================================
-- PART 1: CURSOR PAGINATION INDEXES
-- ============================================================

-- Projects: cursor pagination index (for infinite scroll)
CREATE INDEX IF NOT EXISTS idx_projects_cursor 
ON projects(created_at DESC, id DESC) 
WHERE deleted_at IS NULL;

-- Blueprints: cursor pagination within project
CREATE INDEX IF NOT EXISTS idx_blueprints_cursor
ON blueprints(project_id, created_at DESC, id DESC)
WHERE deleted_at IS NULL;

-- ============================================================
-- PART 2: RLS PERFORMANCE INDEXES
-- ============================================================

-- Project assignments: composite for RLS checks
CREATE INDEX IF NOT EXISTS idx_assignments_user_project_role
ON project_assignments(user_id, project_id, assigned_role);

-- User profiles: role lookup with created_at for listing
CREATE INDEX IF NOT EXISTS idx_user_profiles_role_created
ON user_profiles(role, created_at DESC);

-- ============================================================
-- PART 3: QUERY OPTIMIZATION INDEXES
-- ============================================================

-- Projects: status + created for filtered lists
CREATE INDEX IF NOT EXISTS idx_projects_status_created
ON projects(status, created_at DESC)
WHERE deleted_at IS NULL;

-- Blueprints: folder listing within project
CREATE INDEX IF NOT EXISTS idx_blueprints_project_folder_created
ON blueprints(project_id, folder_name, created_at DESC)
WHERE deleted_at IS NULL;

-- ============================================================
-- MIGRATION COMPLETE
-- Run: supabase db push
-- ============================================================
