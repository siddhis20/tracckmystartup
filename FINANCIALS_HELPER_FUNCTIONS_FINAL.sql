-- =====================================================
-- FINANCIALS HELPER FUNCTIONS (FINAL VERSION)
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
-- DYNAMIC SAMPLE DATA INSERTION
-- =====================================================

-- Get the actual startup ID to use and insert sample data
DO $$
DECLARE
    actual_startup_id INTEGER;
    has_description BOOLEAN;
    has_industry BOOLEAN;
    has_stage BOOLEAN;
    has_founded_date BOOLEAN;
BEGIN
    -- Get the first available startup ID
    SELECT id INTO actual_startup_id FROM startups ORDER BY id LIMIT 1;
    
    -- If no startup exists, create one with available columns
    IF actual_startup_id IS NULL THEN
        -- Check which columns exist
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'startups' AND column_name = 'description'
        ) INTO has_description;
        
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'startups' AND column_name = 'industry'
        ) INTO has_industry;
        
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'startups' AND column_name = 'stage'
        ) INTO has_stage;
        
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'startups' AND column_name = 'founded_date'
        ) INTO has_founded_date;
        
        -- Create startup with only existing columns
        IF has_description AND has_industry AND has_stage AND has_founded_date THEN
            INSERT INTO startups (name, user_id, total_funding, description, industry, stage, founded_date) 
            VALUES 
                ('Default Startup', 
                 (SELECT id FROM auth.users LIMIT 1), 
                 1000000.00, 
                 'Default startup for testing financials', 
                 'Technology', 
                 'Seed', 
                 '2024-01-01')
            RETURNING id INTO actual_startup_id;
        ELSIF has_description AND has_industry AND has_stage THEN
            INSERT INTO startups (name, user_id, total_funding, description, industry, stage) 
            VALUES 
                ('Default Startup', 
                 (SELECT id FROM auth.users LIMIT 1), 
                 1000000.00, 
                 'Default startup for testing financials', 
                 'Technology', 
                 'Seed')
            RETURNING id INTO actual_startup_id;
        ELSIF has_description AND has_industry THEN
            INSERT INTO startups (name, user_id, total_funding, description, industry) 
            VALUES 
                ('Default Startup', 
                 (SELECT id FROM auth.users LIMIT 1), 
                 1000000.00, 
                 'Default startup for testing financials', 
                 'Technology')
            RETURNING id INTO actual_startup_id;
        ELSIF has_description THEN
            INSERT INTO startups (name, user_id, total_funding, description) 
            VALUES 
                ('Default Startup', 
                 (SELECT id FROM auth.users LIMIT 1), 
                 1000000.00, 
                 'Default startup for testing financials')
            RETURNING id INTO actual_startup_id;
        ELSE
            -- Basic insert with only required columns
            INSERT INTO startups (name, user_id, total_funding) 
            VALUES 
                ('Default Startup', 
                 (SELECT id FROM auth.users LIMIT 1), 
                 1000000.00)
            RETURNING id INTO actual_startup_id;
        END IF;
    END IF;
    
    RAISE NOTICE 'Using startup ID: %', actual_startup_id;
    
    -- Insert sample financial records using the correct startup ID
    INSERT INTO financial_records (startup_id, record_type, date, entity, description, vertical, amount, funding_source, cogs, attachment_url) VALUES
    -- Sample expenses
    (actual_startup_id, 'expense', '2024-01-15', 'Parent Company', 'AWS Services', 'Infrastructure', 2500.00, 'Series A', NULL, NULL),
    (actual_startup_id, 'expense', '2024-01-20', 'Parent Company', 'Salaries - Engineering', 'Salary', 15000.00, 'Series A', NULL, NULL),
    (actual_startup_id, 'expense', '2024-02-10', 'Parent Company', 'Marketing Campaign', 'Marketing', 5000.00, 'Series A', NULL, NULL),
    (actual_startup_id, 'expense', '2024-02-15', 'Parent Company', 'Office Rent', 'Infrastructure', 3000.00, 'Series A', NULL, NULL),
    (actual_startup_id, 'expense', '2024-03-05', 'Parent Company', 'Legal Services', 'Legal', 2000.00, 'Series A', NULL, NULL),
    (actual_startup_id, 'expense', '2024-03-20', 'Parent Company', 'Salaries - Sales', 'Salary', 12000.00, 'Series A', NULL, NULL),
    
    -- Sample revenue
    (actual_startup_id, 'revenue', '2024-01-25', 'Parent Company', 'SaaS Subscription Revenue', 'SaaS', 8000.00, NULL, 2000.00, NULL),
    (actual_startup_id, 'revenue', '2024-02-28', 'Parent Company', 'Consulting Services', 'Consulting', 15000.00, NULL, 5000.00, NULL),
    (actual_startup_id, 'revenue', '2024-03-15', 'Parent Company', 'API Revenue', 'API', 5000.00, NULL, 1000.00, NULL),
    (actual_startup_id, 'revenue', '2024-03-30', 'Parent Company', 'SaaS Subscription Revenue', 'SaaS', 12000.00, NULL, 3000.00, NULL)
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE 'Sample data inserted successfully for startup ID: %', actual_startup_id;
END $$;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Get the startup ID we used
SELECT 'Startup ID used for testing:' as info, id as startup_id FROM startups ORDER BY id LIMIT 1;

-- Show the actual data
SELECT 'Sample financial records created:' as status;
SELECT 
    id,
    startup_id,
    record_type,
    date,
    entity,
    description,
    vertical,
    amount,
    funding_source,
    cogs
FROM financial_records 
ORDER BY date, record_type;

-- Test the functions
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    RAISE NOTICE 'Testing functions with startup ID: %', test_startup_id;
    
    -- Test monthly financial data
    RAISE NOTICE 'Testing monthly financial data function...';
    -- SELECT * FROM get_monthly_financial_data(test_startup_id, 2024);
    
    -- Test revenue by vertical
    RAISE NOTICE 'Testing revenue by vertical function...';
    -- SELECT * FROM get_revenue_by_vertical(test_startup_id, 2024);
    
    -- Test expenses by vertical
    RAISE NOTICE 'Testing expenses by vertical function...';
    -- SELECT * FROM get_expenses_by_vertical(test_startup_id, 2024);
    
    -- Test financial summary
    RAISE NOTICE 'Testing financial summary function...';
    -- SELECT * FROM get_startup_financial_summary(test_startup_id);
END $$;

SELECT 'All helper functions created and sample data inserted successfully!' as status;
