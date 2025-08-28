-- Fix opportunity_applications table to add pitch columns
-- This resolves the 400 error when submitting applications

-- Add pitch columns if they don't exist
ALTER TABLE public.opportunity_applications 
ADD COLUMN IF NOT EXISTS pitch_deck_url TEXT,
ADD COLUMN IF NOT EXISTS pitch_video_url TEXT;

-- Add comments
COMMENT ON COLUMN public.opportunity_applications.pitch_deck_url IS 'URL to the startup''s pitch deck';
COMMENT ON COLUMN public.opportunity_applications.pitch_video_url IS 'URL to the startup''s pitch video';

-- Verify the columns were added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications' 
AND column_name IN ('pitch_deck_url', 'pitch_video_url');

-- Show current table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications'
ORDER BY ordinal_position;

-- Test insert to verify the table works
-- (This will be commented out to avoid actual inserts during setup)
/*
INSERT INTO public.opportunity_applications (
    startup_id, 
    opportunity_id, 
    status, 
    pitch_deck_url, 
    pitch_video_url
) VALUES (
    1, 
    'test-opportunity-id', 
    'pending', 
    'https://example.com/pitch-deck.pdf', 
    'https://youtube.com/watch?v=test'
);
*/

SELECT 'opportunity_applications table fixed successfully!' as status;
