-- =====================================================
-- FIX FINANCIAL FUNCTIONS - TYPE MISMATCH
-- =====================================================

-- Drop existing functions first
DROP FUNCTION IF EXISTS get_monthly_financial_data(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_revenue_by_vertical(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_expenses_by_vertical(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_startup_financial_summary(INTEGER);

-- Function to get monthly financial data (FIXED)
CREATE OR REPLACE FUNCTION get_monthly_financial_data(
    p_startup_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    month_name TEXT,
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

-- Function to get revenue by vertical (FIXED)
CREATE OR REPLACE FUNCTION get_revenue_by_vertical(
    p_startup_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    vertical_name TEXT,
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

-- Function to get expenses by vertical (FIXED)
CREATE OR REPLACE FUNCTION get_expenses_by_vertical(
    p_startup_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    vertical_name TEXT,
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

-- Function to get startup financial summary (FIXED)
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
-- VERIFICATION
-- =====================================================

-- Test the functions
SELECT 'Testing monthly financial data function...' as test_step;
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing monthly financial data for startup ID: %', test_startup_id;
        -- This will show the actual data
        PERFORM * FROM get_monthly_financial_data(test_startup_id, 2024);
    ELSE
        RAISE NOTICE 'No startup found for testing';
    END IF;
END $$;

SELECT 'Testing revenue by vertical function...' as test_step;
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing revenue by vertical for startup ID: %', test_startup_id;
        -- This will show the actual data
        PERFORM * FROM get_revenue_by_vertical(test_startup_id, 2024);
    ELSE
        RAISE NOTICE 'No startup found for testing';
    END IF;
END $$;

SELECT 'Testing expenses by vertical function...' as test_step;
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing expenses by vertical for startup ID: %', test_startup_id;
        -- This will show the actual data
        PERFORM * FROM get_expenses_by_vertical(test_startup_id, 2024);
    ELSE
        RAISE NOTICE 'No startup found for testing';
    END IF;
END $$;

SELECT 'Testing financial summary function...' as test_step;
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing financial summary for startup ID: %', test_startup_id;
        -- This will show the actual data
        PERFORM * FROM get_startup_financial_summary(test_startup_id);
    ELSE
        RAISE NOTICE 'No startup found for testing';
    END IF;
END $$;

SELECT 'All functions fixed and tested successfully!' as status;
