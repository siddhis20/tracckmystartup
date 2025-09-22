-- =====================================================
-- CHECK COMPLIANCE_CHECKS TABLE CONSTRAINTS
-- =====================================================

-- Check all constraints on compliance_checks table
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'compliance_checks'
AND tc.table_schema = 'public';

-- Check the specific ca_status and cs_status constraints
SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints
WHERE constraint_name LIKE '%ca_status%' 
   OR constraint_name LIKE '%cs_status%'
   OR constraint_name LIKE '%compliance_checks%';

-- Check what values are currently in the table
SELECT DISTINCT ca_status, cs_status 
FROM compliance_checks 
LIMIT 10;

-- Test with different status values
-- Try 'Pending' instead of 'pending'
INSERT INTO compliance_checks (
    startup_id,
    task_id,
    entity_identifier,
    entity_display_name,
    year,
    task_name,
    ca_required,
    cs_required,
    task_type,
    ca_status,
    cs_status
) VALUES (
    41,
    'test-task-2',
    'parent',
    'Parent Company (IN)',
    2025,
    'Test Task 2',
    true,
    false,
    'annual',
    'Pending',
    'Pending'
);

-- Check if this worked
SELECT * FROM compliance_checks WHERE task_id = 'test-task-2';

-- Clean up
DELETE FROM compliance_checks WHERE task_id IN ('test-task-2');
