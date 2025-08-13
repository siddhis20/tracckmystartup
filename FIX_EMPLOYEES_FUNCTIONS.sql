-- =====================================================
-- FIX EMPLOYEES FUNCTIONS TYPE MISMATCH
-- =====================================================

-- Drop existing functions to recreate them with correct types
DROP FUNCTION IF EXISTS get_employee_summary(INTEGER);
DROP FUNCTION IF EXISTS get_employees_by_department(INTEGER);
DROP FUNCTION IF EXISTS get_monthly_salary_data(INTEGER, INTEGER);

-- Recreate get_employee_summary function with correct types
CREATE OR REPLACE FUNCTION get_employee_summary(
    p_startup_id INTEGER
)
RETURNS TABLE (
    total_employees INTEGER,
    total_salary_expense DECIMAL(15,2),
    total_esop_allocated DECIMAL(15,2),
    avg_salary DECIMAL(15,2),
    avg_esop_allocation DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_employees,
        COALESCE(SUM(salary), 0) as total_salary_expense,
        COALESCE(SUM(esop_allocation), 0) as total_esop_allocated,
        COALESCE(AVG(salary), 0) as avg_salary,
        COALESCE(AVG(esop_allocation), 0) as avg_esop_allocation
    FROM employees
    WHERE startup_id = p_startup_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate get_employees_by_department function with correct types
CREATE OR REPLACE FUNCTION get_employees_by_department(
    p_startup_id INTEGER
)
RETURNS TABLE (
    department_name TEXT,
    employee_count INTEGER,
    total_salary DECIMAL(15,2),
    total_esop DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        department::TEXT as department_name,
        COUNT(*)::INTEGER as employee_count,
        COALESCE(SUM(salary), 0) as total_salary,
        COALESCE(SUM(esop_allocation), 0) as total_esop
    FROM employees
    WHERE startup_id = p_startup_id
    GROUP BY department
    ORDER BY employee_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate get_monthly_salary_data function with correct types
CREATE OR REPLACE FUNCTION get_monthly_salary_data(
    p_startup_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    month_name TEXT,
    total_salary DECIMAL(15,2),
    total_esop DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('month', joining_date), 'Mon')::TEXT as month_name,
        COALESCE(SUM(salary), 0) as total_salary,
        COALESCE(SUM(esop_allocation), 0) as total_esop
    FROM employees
    WHERE startup_id = p_startup_id 
        AND EXTRACT(YEAR FROM joining_date) = p_year
    GROUP BY DATE_TRUNC('month', joining_date)
    ORDER BY DATE_TRUNC('month', joining_date);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the functions
SELECT 'Testing fixed functions...' as status;

-- Test get_employee_summary
DO $$
DECLARE
    test_startup_id INTEGER;
    result RECORD;
BEGIN
    SELECT startup_id INTO test_startup_id FROM employees ORDER BY created_at LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing get_employee_summary with startup ID: %', test_startup_id;
        SELECT * INTO result FROM get_employee_summary(test_startup_id);
        RAISE NOTICE 'Summary result: %', result;
    ELSE
        RAISE NOTICE 'No employees found to test with';
    END IF;
END $$;

-- Test get_employees_by_department
DO $$
DECLARE
    test_startup_id INTEGER;
    result RECORD;
BEGIN
    SELECT startup_id INTO test_startup_id FROM employees ORDER BY created_at LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing get_employees_by_department with startup ID: %', test_startup_id;
        FOR result IN SELECT * FROM get_employees_by_department(test_startup_id) LOOP
            RAISE NOTICE 'Department result: %', result;
        END LOOP;
    ELSE
        RAISE NOTICE 'No employees found to test with';
    END IF;
END $$;

-- Test get_monthly_salary_data
DO $$
DECLARE
    test_startup_id INTEGER;
    result RECORD;
BEGIN
    SELECT startup_id INTO test_startup_id FROM employees ORDER BY created_at LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing get_monthly_salary_data with startup ID: %', test_startup_id;
        FOR result IN SELECT * FROM get_monthly_salary_data(test_startup_id, 2024) LOOP
            RAISE NOTICE 'Monthly result: %', result;
        END LOOP;
    ELSE
        RAISE NOTICE 'No employees found to test with';
    END IF;
END $$;

SELECT 'Employees functions fixed successfully!' as status;
