-- =====================================================
-- CHECK COMPLIANCE_CHECKS TABLE STRUCTURE
-- =====================================================

-- Check if compliance_checks table exists and its structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'compliance_checks'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check constraints on compliance_checks table
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'compliance_checks'
AND tc.table_schema = 'public';

-- Check if there are any existing records
SELECT COUNT(*) as record_count FROM compliance_checks;

-- Test inserting a simple record
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
    'test-task-1',
    'parent',
    'Parent Company (IN)',
    2025,
    'Test Task',
    true,
    false,
    'annual',
    'pending',
    'pending'
);

-- Check if the test record was inserted
SELECT * FROM compliance_checks WHERE task_id = 'test-task-1';

-- Clean up test record
DELETE FROM compliance_checks WHERE task_id = 'test-task-1';
