-- Add position and address columns to user_profiles table
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS "position" text,
ADD COLUMN IF NOT EXISTS address text;

-- Update the handle_new_user function to include these fields if they are passed in metadata
-- Note: The trigger function usually copies from raw_user_meta_data, so ensuring those are passed in signUp is key.
-- But we can also rely on the explicit update we do in the repository after creation.
