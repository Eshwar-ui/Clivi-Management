-- ============================================================
-- MIGRATION 007: DATABASE INDEXES & SOFT DELETES
-- Performance improvements and data recovery support
-- ============================================================

-- ============================================================
-- PART 1: PERFORMANCE INDEXES
-- ============================================================

-- Projects table indexes
CREATE INDEX IF NOT EXISTS idx_projects_status 
ON projects(status);

CREATE INDEX IF NOT EXISTS idx_projects_created_at 
ON projects(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_projects_created_by 
ON projects(created_by);

-- Project assignments indexes (critical for JOIN performance)
CREATE INDEX IF NOT EXISTS idx_project_assignments_user_id 
ON project_assignments(user_id);

CREATE INDEX IF NOT EXISTS idx_project_assignments_project_id 
ON project_assignments(project_id);

-- Composite index for common query pattern
CREATE INDEX IF NOT EXISTS idx_project_assignments_composite 
ON project_assignments(user_id, project_id);

-- Blueprints indexes
CREATE INDEX IF NOT EXISTS idx_blueprints_project_id 
ON blueprints(project_id);

CREATE INDEX IF NOT EXISTS idx_blueprints_folder 
ON blueprints(project_id, folder_name);

-- User profiles indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_role 
ON user_profiles(role);

-- ============================================================
-- PART 2: SOFT DELETES
-- ============================================================

-- Add deleted_at columns
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE blueprints 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- Create partial indexes for efficient queries on non-deleted records
CREATE INDEX IF NOT EXISTS idx_projects_not_deleted 
ON projects(id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_blueprints_not_deleted 
ON blueprints(id) WHERE deleted_at IS NULL;

-- ============================================================
-- PART 3: SOFT DELETE FUNCTIONS
-- ============================================================

-- Soft delete a project
CREATE OR REPLACE FUNCTION soft_delete_project(p_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE projects 
  SET deleted_at = NOW(), 
      updated_at = NOW()
  WHERE id = p_id AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Restore a soft-deleted project
CREATE OR REPLACE FUNCTION restore_project(p_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE projects 
  SET deleted_at = NULL, 
      updated_at = NOW()
  WHERE id = p_id AND deleted_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Soft delete a blueprint
CREATE OR REPLACE FUNCTION soft_delete_blueprint(b_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE blueprints 
  SET deleted_at = NOW()
  WHERE id = b_id AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- PART 4: ENABLE REALTIME
-- ============================================================

-- Enable realtime for projects table
ALTER PUBLICATION supabase_realtime ADD TABLE projects;

-- Enable realtime for project_assignments table  
ALTER PUBLICATION supabase_realtime ADD TABLE project_assignments;

-- ============================================================
-- PART 5: UPDATED_AT TRIGGER (if not exists)
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to projects if not exists
DROP TRIGGER IF EXISTS update_projects_updated_at ON projects;
CREATE TRIGGER update_projects_updated_at
    BEFORE UPDATE ON projects
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- MIGRATION COMPLETE
-- Run: supabase db push
-- ============================================================
