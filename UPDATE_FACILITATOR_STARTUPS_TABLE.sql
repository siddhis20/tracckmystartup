-- Update facilitator_startups table to reference the new recognition_requests table
-- This script updates the foreign key reference and changes the data type

-- First, drop the existing foreign key constraint
ALTER TABLE public.facilitator_startups 
DROP CONSTRAINT IF EXISTS facilitator_startups_recognition_record_id_fkey;

-- Update the column type to UUID to match recognition_requests.id
ALTER TABLE public.facilitator_startups 
ALTER COLUMN recognition_record_id TYPE UUID USING recognition_record_id::UUID;

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
