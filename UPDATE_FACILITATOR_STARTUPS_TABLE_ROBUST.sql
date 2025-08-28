-- Robust migration script for facilitator_startups table
-- This script safely converts the table to use UUID for recognition_record_id

-- First, check if there's existing data
SELECT '=== CHECKING EXISTING DATA ===' as info;
SELECT COUNT(*) as existing_records FROM public.facilitator_startups;

-- Step 1: Drop existing foreign key constraint
ALTER TABLE public.facilitator_startups 
DROP CONSTRAINT IF EXISTS facilitator_startups_recognition_record_id_fkey;

-- Step 2: Add a new UUID column
ALTER TABLE public.facilitator_startups 
ADD COLUMN recognition_record_id_new UUID;

-- Step 3: Drop the old integer column
ALTER TABLE public.facilitator_startups 
DROP COLUMN recognition_record_id;

-- Step 4: Rename the new column to the original name
ALTER TABLE public.facilitator_startups 
RENAME COLUMN recognition_record_id_new TO recognition_record_id;

-- Step 5: Add the new foreign key constraint to recognition_requests table
ALTER TABLE public.facilitator_startups 
ADD CONSTRAINT facilitator_startups_recognition_record_id_fkey 
FOREIGN KEY (recognition_record_id) 
REFERENCES public.recognition_requests(id) 
ON DELETE CASCADE;

-- Verify the changes
SELECT '=== FACILITATOR STARTUPS TABLE UPDATED ===' as info;
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'facilitator_startups' 
AND column_name = 'recognition_record_id';

-- Show the foreign key constraints
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

-- Verify the table is ready for new data
SELECT '=== VERIFICATION ===' as info;
SELECT COUNT(*) as current_records FROM public.facilitator_startups;
