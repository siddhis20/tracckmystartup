-- Simple setup for pitch materials system
-- This creates the necessary table and storage bucket for pitch deck uploads and video URLs

-- Create startup_pitch_materials table
CREATE TABLE IF NOT EXISTS public.startup_pitch_materials (
    id BIGSERIAL PRIMARY KEY,
    startup_id BIGINT NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    pitch_deck_url TEXT,
    pitch_video_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(startup_id)
);

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

-- Create storage bucket for pitch deck uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'startup-documents',
    'startup-documents',
    true,
    10485760, -- 10MB limit
    ARRAY['application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- Create storage policies
DROP POLICY IF EXISTS startup_documents_select ON storage.objects;
CREATE POLICY startup_documents_select ON storage.objects
    FOR SELECT TO AUTHENTICATED USING (
        bucket_id = 'startup-documents' AND 
        EXISTS (
            SELECT 1 FROM public.startups s 
            WHERE s.user_id = auth.uid() AND s.id::text = (storage.foldername(name))[1]
        )
    );

DROP POLICY IF EXISTS startup_documents_insert ON storage.objects;
CREATE POLICY startup_documents_insert ON storage.objects
    FOR INSERT TO AUTHENTICATED WITH CHECK (
        bucket_id = 'startup-documents' AND 
        EXISTS (
            SELECT 1 FROM public.startups s 
            WHERE s.user_id = auth.uid() AND s.id::text = (storage.foldername(name))[1]
        )
    );

-- Verify setup
SELECT 'Pitch materials system setup complete!' as status;
