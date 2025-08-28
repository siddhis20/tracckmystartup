-- Add pitch materials columns to opportunity_applications table
-- This allows startups to submit pitch deck and video URLs when applying for opportunities

-- Add the new columns
ALTER TABLE public.opportunity_applications 
ADD COLUMN IF NOT EXISTS pitch_deck_url TEXT,
ADD COLUMN IF NOT EXISTS pitch_video_url TEXT;

-- Add comments to document the new columns
COMMENT ON COLUMN public.opportunity_applications.pitch_deck_url IS 'URL to the startup''s pitch deck (Google Drive, Dropbox, etc.)';
COMMENT ON COLUMN public.opportunity_applications.pitch_video_url IS 'URL to the startup''s pitch video (YouTube, Vimeo, etc.)';

-- Verify the columns were added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications' 
AND column_name IN ('pitch_deck_url', 'pitch_video_url');

-- Show current table structure
\d public.opportunity_applications;
