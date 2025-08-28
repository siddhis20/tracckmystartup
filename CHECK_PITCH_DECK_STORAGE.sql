-- Check Pitch Deck Storage
-- This script helps verify where pitch deck files are stored

-- 1. Check if there's a pitch_deck_url column in startups table
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'startups' 
  AND column_name LIKE '%pitch%'
ORDER BY column_name;

-- 2. Check if there's a separate pitch_decks table
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE '%pitch%';

-- 3. Check startups table for any pitch deck related columns
SELECT 
  id,
  name,
  -- Add any pitch deck related columns here
  created_at,
  updated_at
FROM public.startups 
WHERE id = 11  -- Replace with your actual startup ID
LIMIT 5;

-- 4. Check storage bucket contents (if you have access)
-- This will show files in the pitch-decks bucket
SELECT 
  name,
  created_at,
  updated_at,
  metadata
FROM storage.objects 
WHERE bucket_id = (SELECT id FROM storage.buckets WHERE name = 'pitch-decks')
ORDER BY created_at DESC
LIMIT 10;

