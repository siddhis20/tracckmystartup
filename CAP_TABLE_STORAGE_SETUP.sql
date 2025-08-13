-- =====================================================
-- CAP TABLE STORAGE SETUP
-- =====================================================

-- Create storage bucket for cap table documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'cap-table-documents',
    'cap-table-documents',
    true,
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'image/jpeg', 'image/png', 'image/gif', 'video/mp4', 'video/quicktime']
) ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STORAGE POLICIES
-- =====================================================

-- Allow authenticated users to upload cap table documents
DROP POLICY IF EXISTS "Allow authenticated users to upload cap table documents" ON storage.objects;
CREATE POLICY "Allow authenticated users to upload cap table documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'cap-table-documents' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1]::integer IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Allow users to view their own cap table documents
DROP POLICY IF EXISTS "Allow users to view their own cap table documents" ON storage.objects;
CREATE POLICY "Allow users to view their own cap table documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'cap-table-documents' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1]::integer IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Allow users to update their own cap table documents
DROP POLICY IF EXISTS "Allow users to update their own cap table documents" ON storage.objects;
CREATE POLICY "Allow users to update their own cap table documents" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'cap-table-documents' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1]::integer IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Allow users to delete their own cap table documents
DROP POLICY IF EXISTS "Allow users to delete their own cap table documents" ON storage.objects;
CREATE POLICY "Allow users to delete their own cap table documents" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'cap-table-documents' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1]::integer IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT 'Cap Table storage setup completed successfully!' as status;
