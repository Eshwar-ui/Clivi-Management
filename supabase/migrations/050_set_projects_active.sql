-- Migration: Set all existing 'planning' projects to 'in_progress' (active)
-- New projects will also default to 'in_progress' via the Flutter app model

UPDATE projects
SET status = 'in_progress',
    updated_at = NOW()
WHERE status = 'planning'
  AND deleted_at IS NULL;
