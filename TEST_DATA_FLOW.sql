-- Test script to verify the data flow from startup to facilitator
-- Run this after setting up the pitch materials system

-- 1. Check if startup_pitch_materials table exists
SELECT 'startup_pitch_materials table exists' as test, 
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'startup_pitch_materials') as result;

-- 2. Check if opportunity_applications table has pitch columns
SELECT 'opportunity_applications has pitch columns' as test,
       EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'opportunity_applications' AND column_name = 'pitch_deck_url') as has_deck,
       EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'opportunity_applications' AND column_name = 'pitch_video_url') as has_video;

-- 3. Check if storage bucket exists
SELECT 'startup-documents bucket exists' as test,
       EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'startup-documents') as result;

-- 4. Show sample data flow (if any data exists)
SELECT 'Sample startup pitch materials:' as info;
SELECT s.name as startup_name, 
       spm.pitch_deck_url, 
       spm.pitch_video_url,
       spm.created_at
FROM startup_pitch_materials spm
JOIN startups s ON s.id = spm.startup_id
LIMIT 5;

SELECT 'Sample opportunity applications:' as info;
SELECT s.name as startup_name,
       io.program_name as opportunity_name,
       oa.status,
       oa.pitch_deck_url,
       oa.pitch_video_url,
       oa.created_at
FROM opportunity_applications oa
JOIN startups s ON s.id = oa.startup_id
JOIN incubation_opportunities io ON io.id = oa.opportunity_id
LIMIT 5;

-- 5. Test RLS policies
SELECT 'RLS policies for startup_pitch_materials:' as info;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'startup_pitch_materials';

SELECT 'RLS policies for opportunity_applications:' as info;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'opportunity_applications';

-- 6. Verify the complete flow
SELECT 'Data flow verification complete!' as status;
