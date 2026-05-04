-- Fix log_blueprint_upload trigger function to use correct columns
-- Previously referenced 'title' and 'version' which were dropped

CREATE OR REPLACE FUNCTION public.log_blueprint_upload()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    PERFORM public.log_operation(
        'upload', 'blueprint', NEW.id,
        'Blueprint uploaded: ' || NEW.file_name,
        'Folder: ' || COALESCE(NEW.folder_name, 'General'),
        NEW.project_id
    );
    RETURN NEW;
END;
$$;
