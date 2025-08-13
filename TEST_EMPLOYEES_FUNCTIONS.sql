-- =====================================================
-- TEST EMPLOYEES FUNCTIONS
-- =====================================================

-- Check if functions exist
SELECT 'Checking if employees functions exist...' as status;

SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN (
        'get_employee_summary',
        'get_employees_by_department', 
        'get_monthly_salary_data'
    );

-- Check if employees table has data
SELECT 'Checking employees table data...' as status;
SELECT COUNT(*) as total_employees FROM employees;

-- Test get_employee_summary function
SELECT 'Testing get_employee_summary function...' as status;
DO $$
DECLARE
    test_startup_id INTEGER;
    result RECORD;
BEGIN
    -- Get a startup ID that has employees
    SELECT startup_id INTO test_startup_id 
    FROM employees 
    ORDER BY created_at 
    LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with startup ID: %', test_startup_id;
        
        -- Test the function
        SELECT * INTO result FROM get_employee_summary(test_startup_id);
        RAISE NOTICE 'Summary result: %', result;
    ELSE
        RAISE NOTICE 'No employees found to test with';
    END IF;
END $$;

-- Test get_employees_by_department function
SELECT 'Testing get_employees_by_department function...' as status;
DO $$
DECLARE
    test_startup_id INTEGER;
    result RECORD;
BEGIN
    -- Get a startup ID that has employees
    SELECT startup_id INTO test_startup_id 
    FROM employees 
    ORDER BY created_at 
    LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with startup ID: %', test_startup_id;
        
        -- Test the function
        FOR result IN SELECT * FROM get_employees_by_department(test_startup_id) LOOP
            RAISE NOTICE 'Department result: %', result;
        END LOOP;
    ELSE
        RAISE NOTICE 'No employees found to test with';
    END IF;
END $$;

-- Test get_monthly_salary_data function
SELECT 'Testing get_monthly_salary_data function...' as status;
DO $$
DECLARE
    test_startup_id INTEGER;
    result RECORD;
BEGIN
    -- Get a startup ID that has employees
    SELECT startup_id INTO test_startup_id 
    FROM employees 
    ORDER BY created_at 
    LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with startup ID: %', test_startup_id;
        
        -- Test the function
        FOR result IN SELECT * FROM get_monthly_salary_data(test_startup_id, 2024) LOOP
            RAISE NOTICE 'Monthly result: %', result;
        END LOOP;
    ELSE
        RAISE NOTICE 'No employees found to test with';
    END IF;
END $$;

-- Show current employee data
SELECT 'Current employee data:' as status;
SELECT 
    id,
    startup_id,
    name,
    department,
    salary,
    esop_allocation,
    joining_date
FROM employees 
ORDER BY created_at;
