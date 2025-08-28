-- CHECK_AND_FIX_PITCH_MATERIALS.sql
-- This script checks and fixes pitch materials for existing applications

-- Step 1: Check current state
SELECT '=== CURRENT STATE ===' as info;

-- Check if startup_pitch_materials table exists
SELECT 
    'Table check' as step,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'startup_pitch_materials';

-- Check if opportunity_applications has pitch columns
SELECT 
    'Column check' as step,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications' 
AND column_name IN ('pitch_deck_url', 'pitch_video_url');

-- Step 2: Show current applications and their pitch materials
SELECT 
    'Applications with pitch materials' as step,
    oa.id,
    oa.startup_id,
    oa.opportunity_id,
    oa.status,
    oa.pitch_deck_url,
    oa.pitch_video_url,
    s.name as startup_name
FROM opportunity_applications oa
JOIN startups s ON oa.startup_id = s.id
ORDER BY oa.created_at DESC;

-- Step 3: Show startup pitch materials
SELECT 
    'Startup pitch materials' as step,
    spm.startup_id,
    spm.pitch_deck_url,
    spm.pitch_video_url,
    s.name as startup_name
FROM startup_pitch_materials spm
JOIN startups s ON spm.startup_id = s.id
ORDER BY spm.created_at DESC;

-- Step 4: Check if startup 11 has pitch materials
SELECT 
    'Startup 11 pitch materials check' as step,
    s.id,
    s.name,
    spm.pitch_deck_url,
    spm.pitch_video_url
FROM startups s
LEFT JOIN startup_pitch_materials spm ON s.id = spm.startup_id
WHERE s.id = 11;

-- Step 5: Create sample pitch materials for startup 11 (if none exist)
INSERT INTO startup_pitch_materials (startup_id, pitch_deck_url, pitch_video_url)
SELECT 
    11,
    'https://drive.google.com/file/d/sample-pitch-deck.pdf',
    'https://www.youtube.com/watch?v=sample-video'
WHERE NOT EXISTS (
    SELECT 1 FROM startup_pitch_materials WHERE startup_id = 11
);

-- Step 6: Verify the insertion
SELECT 
    'After insertion check' as step,
    startup_id,
    pitch_deck_url,
    pitch_video_url
FROM startup_pitch_materials
WHERE startup_id = 11;

-- Step 7: Show final state of applications with pitch materials
SELECT 
    'Final applications state' as step,
    oa.id,
    oa.startup_id,
    oa.opportunity_id,
    oa.status,
    COALESCE(oa.pitch_deck_url, spm.pitch_deck_url) as final_pitch_deck_url,
    COALESCE(oa.pitch_video_url, spm.pitch_video_url) as final_pitch_video_url,
    s.name as startup_name
FROM opportunity_applications oa
JOIN startups s ON oa.startup_id = s.id
LEFT JOIN startup_pitch_materials spm ON oa.startup_id = spm.startup_id
ORDER BY oa.created_at DESC;
