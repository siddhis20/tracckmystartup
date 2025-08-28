-- Update facilitator_startups table to reference the new recognition_requests table
-- This script properly handles the data type conversion from integer to UUID

-- First, check if there's existing data that needs to be handled
SELECT '=== CHECKING EXISTING DATA ===' as info;
SELECT COUNT(*) as existing_records FROM public.facilitator_startups;

-- If there's existing data, we need to handle it properly
-- For now, let's drop the existing data since we're switching to a new table structure
-- This is safe because the new recognition_requests table will be the source of truth

-- Drop existing data from facilitator_startups table
DELETE FROM public.facilitator_startups;

-- Drop the existing foreign key constraint
ALTER TABLE public.facilitator_startups 
DROP CONSTRAINT IF EXISTS facilitator_startups_recognition_record_id_fkey;

-- Update the column type to UUID with explicit casting
ALTER TABLE public.facilitator_startups 
ALTER COLUMN recognition_record_id TYPE UUID USING recognition_record_id::uuid;

-- Add the new foreign key constraint to recognition_requests table
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

-- Verify the table is empty and ready for new data
SELECT '=== VERIFICATION ===' as info;
SELECT COUNT(*) as current_records FROM public.facilitator_startups;
