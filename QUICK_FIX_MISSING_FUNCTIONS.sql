-- =====================================================
-- QUICK FIX: CREATE ESSENTIAL MISSING RPC FUNCTIONS
-- =====================================================

-- 1. Employee Summary Function (FIXES THE CURRENT ERROR)
CREATE OR REPLACE FUNCTION get_employee_summary(p_startup_id INTEGER)
RETURNS TABLE (
    total_employees BIGINT,
    total_salary_expense DECIMAL,
    total_esop_allocated DECIMAL,
    avg_salary DECIMAL,
    avg_esop_allocation DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_employees,
        COALESCE(SUM(salary), 0) as total_salary_expense,
        COALESCE(SUM(esop_allocation), 0) as total_esop_allocated,
        COALESCE(AVG(salary), 0) as avg_salary,
        COALESCE(AVG(esop_allocation), 0) as avg_esop_allocation
    FROM employees 
    WHERE startup_id = p_startup_id;
END;
$$ LANGUAGE plpgsql;

-- 2. Monthly Financial Data Function
CREATE OR REPLACE FUNCTION get_monthly_financial_data(p_startup_id INTEGER, p_year INTEGER)
RETURNS TABLE (
    month_name TEXT,
    revenue DECIMAL,
    expenses DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    WITH monthly_data AS (
        SELECT 
            TO_CHAR(date, 'Mon') as month_name,
            EXTRACT(MONTH FROM date) as month_num,
            SUM(CASE WHEN record_type = 'revenue' THEN amount ELSE 0 END) as revenue,
            SUM(CASE WHEN record_type = 'expense' THEN amount ELSE 0 END) as expenses
        FROM financial_records 
        WHERE startup_id = p_startup_id 
        AND EXTRACT(YEAR FROM date) = p_year
        GROUP BY TO_CHAR(date, 'Mon'), EXTRACT(MONTH FROM date)
    )
    SELECT 
        month_name,
        COALESCE(revenue, 0) as revenue,
        COALESCE(expenses, 0) as expenses
    FROM monthly_data
    ORDER BY month_num;
END;
$$ LANGUAGE plpgsql;

-- 3. Revenue by Vertical Function
CREATE OR REPLACE FUNCTION get_revenue_by_vertical(p_startup_id INTEGER, p_year INTEGER)
RETURNS TABLE (
    vertical_name TEXT,
    total_revenue DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vertical as vertical_name,
        COALESCE(SUM(amount), 0) as total_revenue
    FROM financial_records 
    WHERE startup_id = p_startup_id 
    AND record_type = 'revenue'
    AND EXTRACT(YEAR FROM date) = p_year
    GROUP BY vertical
    ORDER BY total_revenue DESC;
END;
$$ LANGUAGE plpgsql;

-- 4. Expenses by Vertical Function
CREATE OR REPLACE FUNCTION get_expenses_by_vertical(p_startup_id INTEGER, p_year INTEGER)
RETURNS TABLE (
    vertical_name TEXT,
    total_expenses DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vertical as vertical_name,
        COALESCE(SUM(amount), 0) as total_expenses
    FROM financial_records 
    WHERE startup_id = p_startup_id 
    AND record_type = 'expense'
    AND EXTRACT(YEAR FROM date) = p_year
    GROUP BY vertical
    ORDER BY total_expenses DESC;
END;
$$ LANGUAGE plpgsql;

-- 5. Startup Financial Summary Function
CREATE OR REPLACE FUNCTION get_startup_financial_summary(p_startup_id INTEGER)
RETURNS TABLE (
    total_funding DECIMAL,
    total_revenue DECIMAL,
    total_expenses DECIMAL,
    available_funds DECIMAL
) AS $$
DECLARE
    funding_amount DECIMAL;
    revenue_amount DECIMAL;
    expense_amount DECIMAL;
BEGIN
    -- Get total funding from startups table
    SELECT COALESCE(total_funding, 0) INTO funding_amount
    FROM startups 
    WHERE id = p_startup_id;
    
    -- Get total revenue
    SELECT COALESCE(SUM(amount), 0) INTO revenue_amount
    FROM financial_records 
    WHERE startup_id = p_startup_id 
    AND record_type = 'revenue';
    
    -- Get total expenses
    SELECT COALESCE(SUM(amount), 0) INTO expense_amount
    FROM financial_records 
    WHERE startup_id = p_startup_id 
    AND record_type = 'expense';
    
    RETURN QUERY
    SELECT 
        funding_amount as total_funding,
        revenue_amount as total_revenue,
        expense_amount as total_expenses,
        (funding_amount - expense_amount) as available_funds;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_employee_summary(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_monthly_financial_data(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_revenue_by_vertical(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_expenses_by_vertical(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_startup_financial_summary(INTEGER) TO authenticated;
