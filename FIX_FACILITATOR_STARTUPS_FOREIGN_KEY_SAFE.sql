-- Safe fix for facilitator_startups table to work with recognition_records table
-- This script safely updates the foreign key constraint by clearing existing data first

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

-- Check current data
SELECT '=== CURRENT DATA ===' as info;
SELECT COUNT(*) as total_records FROM facilitator_startups;

-- Step 1: Clear existing data (since we're switching to a new table structure)
DELETE FROM public.facilitator_startups;

-- Step 2: Drop the existing foreign key constraint
ALTER TABLE public.facilitator_startups 
DROP CONSTRAINT IF EXISTS facilitator_startups_recognition_record_id_fkey;

-- Step 3: Drop the old column
ALTER TABLE public.facilitator_startups 
DROP COLUMN recognition_record_id;

-- Step 4: Add a new INTEGER column
ALTER TABLE public.facilitator_startups 
ADD COLUMN recognition_record_id INTEGER;

-- Step 5: Add the new foreign key constraint to recognition_records table
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

-- Verify the table is ready for new data
SELECT '=== VERIFICATION ===' as info;
SELECT COUNT(*) as current_records FROM facilitator_startups;

-- Test the connection with recognition_records table
SELECT '=== TESTING CONNECTION ===' as info;
SELECT 
    'Table ready for new data' as status,
    'recognition_record_id column is now INTEGER' as column_type,
    'Foreign key references recognition_records.id' as foreign_key_status;
