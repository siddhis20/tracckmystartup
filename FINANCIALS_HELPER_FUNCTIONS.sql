-- =====================================================
-- FINANCIALS HELPER FUNCTIONS
-- =====================================================

-- Function to get monthly financial data
CREATE OR REPLACE FUNCTION get_monthly_financial_data(
    p_startup_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    month_name VARCHAR(3),
    revenue DECIMAL(15,2),
    expenses DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('month', fr.date), 'Mon') as month_name,
        COALESCE(SUM(CASE WHEN fr.record_type = 'revenue' THEN fr.amount ELSE 0 END), 0) as revenue,
        COALESCE(SUM(CASE WHEN fr.record_type = 'expense' THEN fr.amount ELSE 0 END), 0) as expenses
    FROM financial_records fr
    WHERE fr.startup_id = p_startup_id 
        AND EXTRACT(YEAR FROM fr.date) = p_year
    GROUP BY DATE_TRUNC('month', fr.date)
    ORDER BY DATE_TRUNC('month', fr.date);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get revenue by vertical
CREATE OR REPLACE FUNCTION get_revenue_by_vertical(
    p_startup_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    vertical_name VARCHAR(100),
    total_revenue DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fr.vertical as vertical_name,
        COALESCE(SUM(fr.amount), 0) as total_revenue
    FROM financial_records fr
    WHERE fr.startup_id = p_startup_id 
        AND fr.record_type = 'revenue'
        AND EXTRACT(YEAR FROM fr.date) = p_year
    GROUP BY fr.vertical
    ORDER BY total_revenue DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get expenses by vertical
CREATE OR REPLACE FUNCTION get_expenses_by_vertical(
    p_startup_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    vertical_name VARCHAR(100),
    total_expenses DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fr.vertical as vertical_name,
        COALESCE(SUM(fr.amount), 0) as total_expenses
    FROM financial_records fr
    WHERE fr.startup_id = p_startup_id 
        AND fr.record_type = 'expense'
        AND EXTRACT(YEAR FROM fr.date) = p_year
    GROUP BY fr.vertical
    ORDER BY total_expenses DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get startup financial summary
CREATE OR REPLACE FUNCTION get_startup_financial_summary(
    p_startup_id INTEGER
)
RETURNS TABLE (
    total_funding DECIMAL(15,2),
    total_revenue DECIMAL(15,2),
    total_expenses DECIMAL(15,2),
    available_funds DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.total_funding,
        COALESCE(SUM(CASE WHEN fr.record_type = 'revenue' THEN fr.amount ELSE 0 END), 0) as total_revenue,
        COALESCE(SUM(CASE WHEN fr.record_type = 'expense' THEN fr.amount ELSE 0 END), 0) as total_expenses,
        s.total_funding - COALESCE(SUM(CASE WHEN fr.record_type = 'expense' THEN fr.amount ELSE 0 END), 0) as available_funds
    FROM startups s
    LEFT JOIN financial_records fr ON s.id = fr.startup_id
    WHERE s.id = p_startup_id
    GROUP BY s.total_funding;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert sample financial records for testing
INSERT INTO financial_records (startup_id, record_type, date, entity, description, vertical, amount, funding_source, cogs, attachment_url) VALUES
-- Sample expenses
(1, 'expense', '2024-01-15', 'Parent Company', 'AWS Services', 'Infrastructure', 2500.00, 'Series A', NULL, NULL),
(1, 'expense', '2024-01-20', 'Parent Company', 'Salaries - Engineering', 'Salary', 15000.00, 'Series A', NULL, NULL),
(1, 'expense', '2024-02-10', 'Parent Company', 'Marketing Campaign', 'Marketing', 5000.00, 'Series A', NULL, NULL),
(1, 'expense', '2024-02-15', 'Parent Company', 'Office Rent', 'Infrastructure', 3000.00, 'Series A', NULL, NULL),
(1, 'expense', '2024-03-05', 'Parent Company', 'Legal Services', 'Legal', 2000.00, 'Series A', NULL, NULL),
(1, 'expense', '2024-03-20', 'Parent Company', 'Salaries - Sales', 'Salary', 12000.00, 'Series A', NULL, NULL),

-- Sample revenue
(1, 'revenue', '2024-01-25', 'Parent Company', 'SaaS Subscription Revenue', 'SaaS', 8000.00, NULL, 2000.00, NULL),
(1, 'revenue', '2024-02-28', 'Parent Company', 'Consulting Services', 'Consulting', 15000.00, NULL, 5000.00, NULL),
(1, 'revenue', '2024-03-15', 'Parent Company', 'API Revenue', 'API', 5000.00, NULL, 1000.00, NULL),
(1, 'revenue', '2024-03-30', 'Parent Company', 'SaaS Subscription Revenue', 'SaaS', 12000.00, NULL, 3000.00, NULL)
ON CONFLICT DO NOTHING;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Test the functions
SELECT 'Testing monthly financial data function...' as test_step;
SELECT * FROM get_monthly_financial_data(1, 2024);

SELECT 'Testing revenue by vertical function...' as test_step;
SELECT * FROM get_revenue_by_vertical(1, 2024);

SELECT 'Testing expenses by vertical function...' as test_step;
SELECT * FROM get_expenses_by_vertical(1, 2024);

SELECT 'Testing financial summary function...' as test_step;
SELECT * FROM get_startup_financial_summary(1);

SELECT 'All helper functions created and tested successfully!' as status;
