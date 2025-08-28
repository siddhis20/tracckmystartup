-- Update opportunity_applications table to support diligence and agreement features
-- This adds the missing columns for the complete application flow

-- Add missing columns if they don't exist
ALTER TABLE public.opportunity_applications 
ADD COLUMN IF NOT EXISTS diligence_status TEXT DEFAULT 'none',
ADD COLUMN IF NOT EXISTS agreement_url TEXT;

-- Add comments
COMMENT ON COLUMN public.opportunity_applications.diligence_status IS 'Status of due diligence: none, requested, approved';
COMMENT ON COLUMN public.opportunity_applications.agreement_url IS 'URL to the uploaded agreement PDF';

-- Update existing records to have default diligence_status
UPDATE public.opportunity_applications 
SET diligence_status = 'none' 
WHERE diligence_status IS NULL;

-- Verify the columns were added
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications' 
AND column_name IN ('diligence_status', 'agreement_url', 'pitch_deck_url', 'pitch_video_url')
ORDER BY column_name;

-- Show complete table structure
SELECT 'Complete opportunity_applications table structure:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications'
ORDER BY ordinal_position;

-- Test the updated structure
SELECT 'Sample applications with new fields:' as info;
SELECT 
    id,
    startup_id,
    opportunity_id,
    status,
    diligence_status,
    CASE 
        WHEN agreement_url IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END as has_agreement,
    CASE 
        WHEN pitch_deck_url IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END as has_pitch_deck,
    CASE 
        WHEN pitch_video_url IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END as has_pitch_video
FROM public.opportunity_applications
LIMIT 5;

SELECT 'opportunity_applications table updated successfully!' as status;
