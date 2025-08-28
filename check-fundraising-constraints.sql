-- =====================================================
-- CHECK FUNDRAISING CONSTRAINTS
-- =====================================================
-- This script checks the check constraints on fundraising_details table

-- Check all constraints on fundraising_details table
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'fundraising_details'::regclass;

-- Check the specific type check constraint
SELECT 
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'fundraising_details'::regclass 
    AND conname = 'fundraising_details_type_check';

-- Check the table structure to see the type column definition
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'fundraising_details' 
    AND table_schema = 'public'
    AND column_name = 'type';

-- Check if there's an enum type being used
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname IN (
    SELECT udt_name 
    FROM information_schema.columns 
    WHERE table_name = 'fundraising_details' 
        AND column_name = 'type'
);

-- Show sample data to see what values are currently stored
SELECT DISTINCT type FROM fundraising_details;
