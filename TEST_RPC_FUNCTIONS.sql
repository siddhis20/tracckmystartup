-- =====================================================
-- TEST RPC FUNCTIONS
-- =====================================================

-- Test the employee summary function
SELECT 'Testing get_employee_summary function...' as test_name;

-- This will work if you have a startup with ID 1 and employees
SELECT * FROM get_employee_summary(1);

-- Test the financial functions
SELECT 'Testing get_monthly_financial_data function...' as test_name;

-- This will work if you have financial records for startup ID 1 in 2024
SELECT * FROM get_monthly_financial_data(1, 2024);

SELECT 'Testing get_revenue_by_vertical function...' as test_name;
SELECT * FROM get_revenue_by_vertical(1, 2024);

SELECT 'Testing get_expenses_by_vertical function...' as test_name;
SELECT * FROM get_expenses_by_vertical(1, 2024);

SELECT 'Testing get_startup_financial_summary function...' as test_name;
SELECT * FROM get_startup_financial_summary(1);

-- Check if functions exist
SELECT 'Checking if functions exist...' as test_name;
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'get_employee_summary',
    'get_monthly_financial_data', 
    'get_revenue_by_vertical',
    'get_expenses_by_vertical',
    'get_startup_financial_summary'
)
ORDER BY routine_name;
