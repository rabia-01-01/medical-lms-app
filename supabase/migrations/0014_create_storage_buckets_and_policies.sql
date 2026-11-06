-- 14. PRIVATE STORAGE BUCKETS & STORAGE RLS POLICIES (Section 8.2)
-- ----------------------------------------------------------------------------

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('resources', 'resources', false, 104857600, ARRAY['application/pdf', 'video/mp4', 'image/jpeg', 'image/png', 'image/webp', 'text/plain']),
    ('documents', 'documents', false, 20971520, ARRAY['application/pdf', 'image/jpeg', 'image/png']),
    ('questions', 'questions', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'])
ON CONFLICT (id) DO UPDATE SET
    public = false;

CREATE POLICY "Storage: Authenticated read authorized resources"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'resources'
        AND auth.role() = 'authenticated'
    );

CREATE POLICY "Storage: Authenticated upload verification documents"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'documents'
        AND auth.role() = 'authenticated'
    );

-- ----------------------------------------------------------------------------
