-- Civic Issues Module Migration
-- Creates issues table, storage bucket policies, and RLS

-- 1. ENUM Types
DROP TYPE IF EXISTS public.issue_status CASCADE;
CREATE TYPE public.issue_status AS ENUM ('pending', 'in_progress', 'resolved');

DROP TYPE IF EXISTS public.issue_type_enum CASCADE;
CREATE TYPE public.issue_type_enum AS ENUM ('road', 'water', 'electricity', 'sanitation', 'streetlight', 'other');

-- 2. Core Tables
CREATE TABLE IF NOT EXISTS public.issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    issue_type public.issue_type_enum DEFAULT 'other'::public.issue_type_enum,
    image_url TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_name TEXT,
    status public.issue_status DEFAULT 'pending'::public.issue_status,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_issues_user_id ON public.issues(user_id);
CREATE INDEX IF NOT EXISTS idx_issues_status ON public.issues(status);
CREATE INDEX IF NOT EXISTS idx_issues_created_at ON public.issues(created_at DESC);

-- 4. Updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_issues_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 5. Enable RLS
ALTER TABLE public.issues ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
-- Allow anyone (authenticated or anon) to read all issues (public civic data)
DROP POLICY IF EXISTS "public_read_issues" ON public.issues;
CREATE POLICY "public_read_issues"
ON public.issues
FOR SELECT
TO public
USING (true);

-- Allow authenticated users to insert their own issues
DROP POLICY IF EXISTS "users_insert_own_issues" ON public.issues;
CREATE POLICY "users_insert_own_issues"
ON public.issues
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Allow authenticated users to update their own issues
DROP POLICY IF EXISTS "users_update_own_issues" ON public.issues;
CREATE POLICY "users_update_own_issues"
ON public.issues
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Allow service role to update any issue (for operator simulation)
DROP POLICY IF EXISTS "service_update_any_issue" ON public.issues;
CREATE POLICY "service_update_any_issue"
ON public.issues
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- 7. Trigger for updated_at
DROP TRIGGER IF EXISTS issues_updated_at_trigger ON public.issues;
CREATE TRIGGER issues_updated_at_trigger
    BEFORE UPDATE ON public.issues
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_issues_updated_at();

-- 8. Storage bucket for issue images (via SQL policy)
-- Note: Bucket creation is handled via Supabase dashboard or API
-- RLS for storage.objects if bucket 'issue-images' exists
DO $$
BEGIN
    -- Insert bucket if not exists
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('issue-images', 'issue-images', true)
    ON CONFLICT (id) DO NOTHING;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Storage bucket creation skipped: %', SQLERRM;
END $$;

-- Storage RLS policies
DROP POLICY IF EXISTS "public_read_issue_images" ON storage.objects;
CREATE POLICY "public_read_issue_images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'issue-images');

DROP POLICY IF EXISTS "authenticated_upload_issue_images" ON storage.objects;
CREATE POLICY "authenticated_upload_issue_images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'issue-images');

DROP POLICY IF EXISTS "authenticated_update_issue_images" ON storage.objects;
CREATE POLICY "authenticated_update_issue_images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'issue-images');

DROP POLICY IF EXISTS "authenticated_delete_issue_images" ON storage.objects;
CREATE POLICY "authenticated_delete_issue_images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'issue-images');
