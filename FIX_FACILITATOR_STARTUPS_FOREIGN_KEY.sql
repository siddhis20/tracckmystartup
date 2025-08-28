-- Fix facilitator_startups table to work with recognition_records table
-- This script updates the foreign key constraint to reference recognition_records instead of recognition_requests

-- First, check current foreign key constraints
SELECT '=== CURRENT FOREIGN KEY CONSTRAINTS ===' as info;
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'facilitator_startups';

-- Check current column type
SELECT '=== CURRENT COLUMN TYPE ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'facilitator_startups' 
AND column_name = 'recognition_record_id';

-- Step 1: Drop the existing foreign key constraint
ALTER TABLE public.facilitator_startups 
DROP CONSTRAINT IF EXISTS facilitator_startups_recognition_record_id_fkey;

-- Step 2: Change the column type to INTEGER to match recognition_records.id
ALTER TABLE public.facilitator_startups 
ALTER COLUMN recognition_record_id TYPE INTEGER USING recognition_record_id::INTEGER;

-- Step 3: Add the new foreign key constraint to recognition_records table
ALTER TABLE public.facilitator_startups 
ADD CONSTRAINT facilitator_startups_recognition_record_id_fkey 
FOREIGN KEY (recognition_record_id) 
REFERENCES public.recognition_records(id) 
ON DELETE CASCADE;

-- Verify the changes
SELECT '=== UPDATED FOREIGN KEY CONSTRAINTS ===' as info;
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'facilitator_startups';

-- Verify the column type
SELECT '=== UPDATED COLUMN TYPE ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'facilitator_startups' 
AND column_name = 'recognition_record_id';

-- Test the connection
SELECT '=== TESTING CONNECTION ===' as info;
SELECT 
    fs.id as facilitator_startup_id,
    fs.facilitator_id,
    fs.startup_id,
    fs.recognition_record_id,
    rr.program_name,
    rr.status as recognition_status,
    s.name as startup_name
FROM facilitator_startups fs
LEFT JOIN recognition_records rr ON fs.recognition_record_id = rr.id
LEFT JOIN startups s ON fs.startup_id = s.id
LIMIT 5;
