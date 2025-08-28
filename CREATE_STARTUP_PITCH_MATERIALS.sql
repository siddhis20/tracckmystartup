-- Create startup_pitch_materials table to store pitch materials for each startup
-- This allows startups to save their pitch deck and video URLs for reuse across applications

-- Create the table
CREATE TABLE IF NOT EXISTS public.startup_pitch_materials (
    id BIGSERIAL PRIMARY KEY,
    startup_id BIGINT NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    pitch_deck_url TEXT,
    pitch_video_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(startup_id)
);

-- Add comments
COMMENT ON TABLE public.startup_pitch_materials IS 'Stores pitch materials (deck and video URLs) for each startup';
COMMENT ON COLUMN public.startup_pitch_materials.startup_id IS 'Reference to the startup';
COMMENT ON COLUMN public.startup_pitch_materials.pitch_deck_url IS 'URL to the startup''s pitch deck (uploaded file or external link)';
COMMENT ON COLUMN public.startup_pitch_materials.pitch_video_url IS 'URL to the startup''s pitch video (YouTube, Vimeo, etc.)';

-- Enable RLS
ALTER TABLE public.startup_pitch_materials ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS pitch_materials_select_own ON public.startup_pitch_materials;
CREATE POLICY pitch_materials_select_own ON public.startup_pitch_materials
    FOR SELECT TO AUTHENTICATED USING (
        auth.uid() = (SELECT user_id FROM public.startups WHERE id = startup_id)
    );

DROP POLICY IF EXISTS pitch_materials_insert_own ON public.startup_pitch_materials;
CREATE POLICY pitch_materials_insert_own ON public.startup_pitch_materials
    FOR INSERT TO AUTHENTICATED WITH CHECK (
        auth.uid() = (SELECT user_id FROM public.startups WHERE id = startup_id)
    );

DROP POLICY IF EXISTS pitch_materials_update_own ON public.startup_pitch_materials;
CREATE POLICY pitch_materials_update_own ON public.startup_pitch_materials
    FOR UPDATE TO AUTHENTICATED USING (
        auth.uid() = (SELECT user_id FROM public.startups WHERE id = startup_id)
    );

DROP POLICY IF EXISTS pitch_materials_delete_own ON public.startup_pitch_materials;
CREATE POLICY pitch_materials_delete_own ON public.startup_pitch_materials
    FOR DELETE TO AUTHENTICATED USING (
        auth.uid() = (SELECT user_id FROM public.startups WHERE id = startup_id)
    );

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_startup_pitch_materials_startup_id ON public.startup_pitch_materials(startup_id);

-- Create storage bucket for pitch deck uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'startup-documents',
    'startup-documents',
    true,
    10485760, -- 10MB limit
    ARRAY['application/pdf', 'image/*']
) ON CONFLICT (id) DO NOTHING;

-- Create storage policies for the bucket
DROP POLICY IF EXISTS startup_documents_select ON storage.objects;
CREATE POLICY startup_documents_select ON storage.objects
    FOR SELECT TO AUTHENTICATED USING (
        bucket_id = 'startup-documents' AND 
        (auth.uid()::text = (storage.foldername(name))[1] OR 
         EXISTS (
             SELECT 1 FROM public.startups s 
             WHERE s.user_id = auth.uid() AND s.id::text = (storage.foldername(name))[1]
         ))
    );

DROP POLICY IF EXISTS startup_documents_insert ON storage.objects;
CREATE POLICY startup_documents_insert ON storage.objects
    FOR INSERT TO AUTHENTICATED WITH CHECK (
        bucket_id = 'startup-documents' AND 
        (auth.uid()::text = (storage.foldername(name))[1] OR 
         EXISTS (
             SELECT 1 FROM public.startups s 
             WHERE s.user_id = auth.uid() AND s.id::text = (storage.foldername(name))[1]
         ))
    );

DROP POLICY IF EXISTS startup_documents_update ON storage.objects;
CREATE POLICY startup_documents_update ON storage.objects
    FOR UPDATE TO AUTHENTICATED USING (
        bucket_id = 'startup-documents' AND 
        (auth.uid()::text = (storage.foldername(name))[1] OR 
         EXISTS (
             SELECT 1 FROM public.startups s 
             WHERE s.user_id = auth.uid() AND s.id::text = (storage.foldername(name))[1]
         ))
    );

DROP POLICY IF EXISTS startup_documents_delete ON storage.objects;
CREATE POLICY startup_documents_delete ON storage.objects
    FOR DELETE TO AUTHENTICATED USING (
        bucket_id = 'startup-documents' AND 
        (auth.uid()::text = (storage.foldername(name))[1] OR 
         EXISTS (
             SELECT 1 FROM public.startups s 
             WHERE s.user_id = auth.uid() AND s.id::text = (storage.foldername(name))[1]
         ))
    );

-- Verify the setup
SELECT 'startup_pitch_materials table created successfully' as status;
SELECT 'startup-documents storage bucket created successfully' as status;

-- Show table structure
\d public.startup_pitch_materials;
