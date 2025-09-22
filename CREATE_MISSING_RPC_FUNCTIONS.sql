-- =====================================================
-- CREATE MISSING RPC FUNCTIONS FOR EMPLOYEES AND FINANCIALS
-- =====================================================

-- 1. Employee Summary Function
CREATE OR REPLACE FUNCTION get_employee_summary(startup_id_param INTEGER)
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
    WHERE startup_id = startup_id_param;
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

-- 6. Investment Summary Function (if missing)
CREATE OR REPLACE FUNCTION get_investment_summary(p_startup_id INTEGER)
RETURNS TABLE (
    total_equity_funding DECIMAL,
    total_debt_funding DECIMAL,
    total_grant_funding DECIMAL,
    total_investments BIGINT,
    avg_equity_allocated DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(CASE WHEN investment_type = 'Equity' THEN amount ELSE 0 END), 0) as total_equity_funding,
        COALESCE(SUM(CASE WHEN investment_type = 'Debt' THEN amount ELSE 0 END), 0) as total_debt_funding,
        COALESCE(SUM(CASE WHEN investment_type = 'Grant' THEN amount ELSE 0 END), 0) as total_grant_funding,
        COUNT(*) as total_investments,
        COALESCE(AVG(equity_allocated), 0) as avg_equity_allocated
    FROM investment_records 
    WHERE startup_id = p_startup_id;
END;
$$ LANGUAGE plpgsql;

-- 7. Valuation History Function (if missing)
CREATE OR REPLACE FUNCTION get_valuation_history(p_startup_id INTEGER)
RETURNS TABLE (
    round_name TEXT,
    valuation DECIMAL,
    investment_amount DECIMAL,
    date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'Investment Round' as round_name,
        pre_money_valuation as valuation,
        amount as investment_amount,
        date
    FROM investment_records 
    WHERE startup_id = p_startup_id
    AND pre_money_valuation IS NOT NULL
    ORDER BY date ASC;
END;
$$ LANGUAGE plpgsql;

-- 8. Equity Distribution Function (if missing)
CREATE OR REPLACE FUNCTION get_equity_distribution(p_startup_id INTEGER)
RETURNS TABLE (
    holder_type TEXT,
    equity_percentage DECIMAL,
    total_amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    WITH investor_equity AS (
        SELECT 
            'Investor' as holder_type,
            equity_allocated as equity_percentage,
            amount as total_amount
        FROM investment_records 
        WHERE startup_id = p_startup_id
    ),
    founder_equity AS (
        SELECT 
            'Founder' as holder_type,
            equity_percentage,
            0 as total_amount
        FROM founders 
        WHERE startup_id = p_startup_id
    )
    SELECT * FROM investor_equity
    UNION ALL
    SELECT * FROM founder_equity
    ORDER BY equity_percentage DESC;
END;
$$ LANGUAGE plpgsql;

-- 9. Fundraising Status Function (if missing)
CREATE OR REPLACE FUNCTION get_fundraising_status(p_startup_id INTEGER)
RETURNS TABLE (
    active BOOLEAN,
    type TEXT,
    value DECIMAL,
    equity DECIMAL,
    validation_requested BOOLEAN,
    pitch_deck_url TEXT,
    pitch_video_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        active,
        type,
        value,
        equity,
        validation_requested,
        pitch_deck_url,
        pitch_video_url
    FROM fundraising_details 
    WHERE startup_id = p_startup_id
    ORDER BY created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions for these functions
GRANT EXECUTE ON FUNCTION get_employee_summary(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_monthly_financial_data(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_revenue_by_vertical(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_expenses_by_vertical(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_startup_financial_summary(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_investment_summary(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_valuation_history(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_equity_distribution(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_fundraising_status(INTEGER) TO authenticated;

-- Add comments for documentation
COMMENT ON FUNCTION get_employee_summary(INTEGER) IS 'Returns employee summary statistics for a startup';
COMMENT ON FUNCTION get_monthly_financial_data(INTEGER, INTEGER) IS 'Returns monthly financial data (revenue and expenses) for a startup in a given year';
COMMENT ON FUNCTION get_revenue_by_vertical(INTEGER, INTEGER) IS 'Returns revenue breakdown by vertical for a startup in a given year';
COMMENT ON FUNCTION get_expenses_by_vertical(INTEGER, INTEGER) IS 'Returns expenses breakdown by vertical for a startup in a given year';
COMMENT ON FUNCTION get_startup_financial_summary(INTEGER) IS 'Returns overall financial summary for a startup';
COMMENT ON FUNCTION get_investment_summary(INTEGER) IS 'Returns investment summary statistics for a startup';
COMMENT ON FUNCTION get_valuation_history(INTEGER) IS 'Returns valuation history for a startup';
COMMENT ON FUNCTION get_equity_distribution(INTEGER) IS 'Returns equity distribution data for a startup';
COMMENT ON FUNCTION get_fundraising_status(INTEGER) IS 'Returns current fundraising status for a startup';
