-- =====================================================
-- FINANCIALS STORAGE SETUP
-- =====================================================

-- Create storage bucket for financial attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'financial-attachments',
    'financial-attachments',
    false,
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
) ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STORAGE POLICIES
-- =====================================================

-- Policy: Users can upload attachments for their own startups
CREATE POLICY "Users can upload financial attachments" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'financial-attachments' AND
        (storage.foldername(name))[1]::integer IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can view attachments for their own startups
CREATE POLICY "Users can view financial attachments" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'financial-attachments' AND
        (storage.foldername(name))[1]::integer IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can update attachments for their own startups
CREATE POLICY "Users can update financial attachments" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'financial-attachments' AND
        (storage.foldername(name))[1]::integer IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can delete attachments for their own startups
CREATE POLICY "Users can delete financial attachments" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'financial-attachments' AND
        (storage.foldername(name))[1]::integer IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Admin can view all attachments
CREATE POLICY "Admins can view all financial attachments" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'financial-attachments' AND
        EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role = 'Admin'
        )
    );

-- CA can view all attachments for compliance
CREATE POLICY "CA can view all financial attachments" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'financial-attachments' AND
        EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role = 'CA'
        )
    );

-- CS can view all attachments for compliance
CREATE POLICY "CS can view all financial attachments" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'financial-attachments' AND
        EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role = 'CS'
        )
    );

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Verify storage bucket creation
SELECT 'Financial attachments storage bucket created successfully' as status;

-- List all storage buckets
SELECT id, name, public FROM storage.buckets WHERE id = 'financial-attachments';
