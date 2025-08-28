-- TEST_COMPLIANCE_STATUS.sql
-- This file tests the compliance_status column functionality

-- 1. Check if the compliance_status column exists and its type
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name = 'compliance_status';

-- 2. Check the current compliance_status values in startups table
SELECT 
    id,
    name,
    compliance_status,
    typeof(compliance_status) as status_type
FROM startups 
LIMIT 10;

-- 3. Test updating a startup's compliance status
-- Replace STARTUP_ID with an actual startup ID from your table
UPDATE startups 
SET compliance_status = 'Compliant' 
WHERE id = 1 
RETURNING id, name, compliance_status;

-- 4. Check if the update worked
SELECT 
    id,
    name,
    compliance_status
FROM startups 
WHERE id = 1;

-- 5. Test with different status values
UPDATE startups 
SET compliance_status = 'Non-Compliant' 
WHERE id = 1 
RETURNING id, name, compliance_status;

-- 6. Check the enum type definition
SELECT 
    t.typname,
    e.enumlabel
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'compliance_status'
ORDER BY e.enumsortorder;
