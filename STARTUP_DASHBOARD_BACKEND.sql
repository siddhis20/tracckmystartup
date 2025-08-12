-- =====================================================
-- STARTUP DASHBOARD BACKEND FUNCTIONS
-- =====================================================
-- This file contains all the backend functions needed for the startup dashboard

-- =====================================================
-- STEP 1: ENHANCE EXISTING TABLES
-- =====================================================

-- Add user_id to startups table if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'startups' AND column_name = 'user_id') THEN
        ALTER TABLE public.startups ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_startups_user_id ON public.startups(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_records_vertical ON public.financial_records(vertical);
CREATE INDEX IF NOT EXISTS idx_financial_records_entity ON public.financial_records(entity);
CREATE INDEX IF NOT EXISTS idx_employees_department ON public.employees(department);

-- =====================================================
-- STEP 2: ANALYTICS FUNCTIONS FOR DASHBOARD
-- =====================================================

-- Function to get monthly revenue vs expenses data
CREATE OR REPLACE FUNCTION get_monthly_financial_data(startup_id_param INTEGER, year_param INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE))
RETURNS TABLE (
    month_name TEXT,
    revenue DECIMAL(15,2),
    expenses DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH months AS (
        SELECT generate_series(
            date_trunc('year', make_date(year_param, 1, 1)),
            date_trunc('year', make_date(year_param, 12, 31)),
            interval '1 month'
        )::date as month_date
    ),
    revenue_data AS (
        SELECT 
            date_trunc('month', fr.date) as month_date,
            SUM(CASE WHEN fr.cogs IS NULL THEN fr.amount ELSE 0 END) as revenue
        FROM financial_records fr
        WHERE fr.startup_id = startup_id_param 
        AND fr.cogs IS NULL  -- Revenue records don't have COGS
        AND EXTRACT(YEAR FROM fr.date) = year_param
        GROUP BY date_trunc('month', fr.date)
    ),
    expense_data AS (
        SELECT 
            date_trunc('month', fr.date) as month_date,
            SUM(CASE WHEN fr.cogs IS NOT NULL THEN fr.amount ELSE 0 END) as expenses
        FROM financial_records fr
        WHERE fr.startup_id = startup_id_param 
        AND fr.cogs IS NOT NULL  -- Expense records have COGS
        AND EXTRACT(YEAR FROM fr.date) = year_param
        GROUP BY date_trunc('month', fr.date)
    )
    SELECT 
        to_char(m.month_date, 'Mon') as month_name,
        COALESCE(r.revenue, 0) as revenue,
        COALESCE(e.expenses, 0) as expenses
    FROM months m
    LEFT JOIN revenue_data r ON m.month_date = r.month_date
    LEFT JOIN expense_data e ON m.month_date = e.month_date
    ORDER BY m.month_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get fund usage breakdown
CREATE OR REPLACE FUNCTION get_fund_usage_breakdown(startup_id_param INTEGER)
RETURNS TABLE (
    category TEXT,
    amount DECIMAL(15,2),
    percentage DECIMAL(5,2)
) AS $$
DECLARE
    total_expenses DECIMAL(15,2);
BEGIN
    -- Get total expenses
    SELECT COALESCE(SUM(amount), 0) INTO total_expenses
    FROM financial_records 
    WHERE startup_id = startup_id_param AND cogs IS NOT NULL;
    
    RETURN QUERY
    SELECT 
        fr.vertical as category,
        SUM(fr.amount) as amount,
        CASE 
            WHEN total_expenses > 0 THEN (SUM(fr.amount) / total_expenses) * 100
            ELSE 0 
        END as percentage
    FROM financial_records fr
    WHERE fr.startup_id = startup_id_param AND fr.cogs IS NOT NULL
    GROUP BY fr.vertical
    ORDER BY amount DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get revenue by vertical
CREATE OR REPLACE FUNCTION get_revenue_by_vertical(startup_id_param INTEGER, year_param INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE))
RETURNS TABLE (
    vertical TEXT,
    amount DECIMAL(15,2),
    percentage DECIMAL(5,2)
) AS $$
DECLARE
    total_revenue DECIMAL(15,2);
BEGIN
    -- Get total revenue
    SELECT COALESCE(SUM(amount), 0) INTO total_revenue
    FROM financial_records 
    WHERE startup_id = startup_id_param 
    AND cogs IS NULL 
    AND EXTRACT(YEAR FROM date) = year_param;
    
    RETURN QUERY
    SELECT 
        fr.vertical,
        SUM(fr.amount) as amount,
        CASE 
            WHEN total_revenue > 0 THEN (SUM(fr.amount) / total_revenue) * 100
            ELSE 0 
        END as percentage
    FROM financial_records fr
    WHERE fr.startup_id = startup_id_param 
    AND fr.cogs IS NULL 
    AND EXTRACT(YEAR FROM fr.date) = year_param
    GROUP BY fr.vertical
    ORDER BY amount DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get expenses by vertical
CREATE OR REPLACE FUNCTION get_expenses_by_vertical(startup_id_param INTEGER, year_param INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE))
RETURNS TABLE (
    vertical TEXT,
    amount DECIMAL(15,2),
    percentage DECIMAL(5,2)
) AS $$
DECLARE
    total_expenses DECIMAL(15,2);
BEGIN
    -- Get total expenses
    SELECT COALESCE(SUM(amount), 0) INTO total_expenses
    FROM financial_records 
    WHERE startup_id = startup_id_param 
    AND cogs IS NOT NULL 
    AND EXTRACT(YEAR FROM date) = year_param;
    
    RETURN QUERY
    SELECT 
        fr.vertical,
        SUM(fr.amount) as amount,
        CASE 
            WHEN total_expenses > 0 THEN (SUM(fr.amount) / total_expenses) * 100
            ELSE 0 
        END as percentage
    FROM financial_records fr
    WHERE fr.startup_id = startup_id_param 
    AND fr.cogs IS NOT NULL 
    AND EXTRACT(YEAR FROM fr.date) = year_param
    GROUP BY fr.vertical
    ORDER BY amount DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get employee salary data by month
CREATE OR REPLACE FUNCTION get_monthly_salary_data(startup_id_param INTEGER, year_param INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE))
RETURNS TABLE (
    month_name TEXT,
    salary_expense DECIMAL(15,2),
    esop_expense DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH months AS (
        SELECT generate_series(
            date_trunc('year', make_date(year_param, 1, 1)),
            date_trunc('year', make_date(year_param, 12, 31)),
            interval '1 month'
        )::date as month_date
    ),
    salary_data AS (
        SELECT 
            date_trunc('month', e.joining_date) as month_date,
            SUM(e.salary / 12) as salary_expense,  -- Monthly salary
            SUM(e.esop_per_allocation) as esop_expense
        FROM employees e
        WHERE e.startup_id = startup_id_param 
        AND EXTRACT(YEAR FROM e.joining_date) = year_param
        GROUP BY date_trunc('month', e.joining_date)
    )
    SELECT 
        to_char(m.month_date, 'Mon') as month_name,
        COALESCE(s.salary_expense, 0) as salary_expense,
        COALESCE(s.esop_expense, 0) as esop_expense
    FROM months m
    LEFT JOIN salary_data s ON m.month_date = s.month_date
    ORDER BY m.month_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get employee distribution by department
CREATE OR REPLACE FUNCTION get_employee_department_distribution(startup_id_param INTEGER)
RETURNS TABLE (
    department TEXT,
    employee_count INTEGER,
    total_salary DECIMAL(15,2),
    total_esop DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.department,
        COUNT(*) as employee_count,
        SUM(e.salary) as total_salary,
        SUM(e.esop_allocation) as total_esop
    FROM employees e
    WHERE e.startup_id = startup_id_param
    GROUP BY e.department
    ORDER BY employee_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get startup summary statistics
CREATE OR REPLACE FUNCTION get_startup_summary_stats(startup_id_param INTEGER)
RETURNS TABLE (
    total_funding DECIMAL(15,2),
    total_revenue DECIMAL(15,2),
    total_expenses DECIMAL(15,2),
    available_funds DECIMAL(15,2),
    employee_count INTEGER,
    esop_reserved_value DECIMAL(15,2),
    esop_allocated_value DECIMAL(15,2)
) AS $$
DECLARE
    startup_record RECORD;
    esop_reserved_percentage DECIMAL(5,2) := 5.0; -- 5% reserved for ESOP
BEGIN
    -- Get startup basic info
    SELECT * INTO startup_record FROM startups WHERE id = startup_id_param;
    
    RETURN QUERY
    SELECT 
        startup_record.total_funding,
        startup_record.total_revenue,
        COALESCE((
            SELECT SUM(amount) 
            FROM financial_records 
            WHERE startup_id = startup_id_param AND cogs IS NOT NULL
        ), 0) as total_expenses,
        startup_record.total_funding - COALESCE((
            SELECT SUM(amount) 
            FROM financial_records 
            WHERE startup_id = startup_id_param AND cogs IS NOT NULL
        ), 0) as available_funds,
        COALESCE((
            SELECT COUNT(*) 
            FROM employees 
            WHERE startup_id = startup_id_param
        ), 0) as employee_count,
        startup_record.current_valuation * (esop_reserved_percentage / 100) as esop_reserved_value,
        COALESCE((
            SELECT SUM(esop_allocation) 
            FROM employees 
            WHERE startup_id = startup_id_param
        ), 0) as esop_allocated_value;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 3: ENHANCED CRUD FUNCTIONS
-- =====================================================

-- Function to add financial record with file upload
CREATE OR REPLACE FUNCTION add_financial_record(
    startup_id_param INTEGER,
    date_param DATE,
    entity_param TEXT,
    description_param TEXT,
    vertical_param TEXT,
    amount_param DECIMAL(15,2),
    funding_source_param TEXT DEFAULT NULL,
    cogs_param DECIMAL(15,2) DEFAULT NULL,
    attachment_url_param TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    record_id UUID;
BEGIN
    INSERT INTO financial_records (
        startup_id, date, entity, description, vertical, amount, 
        funding_source, cogs, attachment_url
    ) VALUES (
        startup_id_param, date_param, entity_param, description_param, 
        vertical_param, amount_param, funding_source_param, cogs_param, attachment_url_param
    ) RETURNING id INTO record_id;
    
    -- Update startup totals
    IF cogs_param IS NULL THEN
        -- This is revenue
        UPDATE startups 
        SET total_revenue = total_revenue + amount_param
        WHERE id = startup_id_param;
    END IF;
    
    RETURN record_id;
END;
$$ LANGUAGE plpgsql;

-- Function to add employee with contract upload
CREATE OR REPLACE FUNCTION add_employee(
    startup_id_param INTEGER,
    name_param TEXT,
    joining_date_param DATE,
    entity_param TEXT,
    department_param TEXT,
    salary_param DECIMAL(10,2),
    esop_allocation_param DECIMAL(10,2) DEFAULT 0,
    allocation_type_param esop_allocation_type DEFAULT 'one-time',
    esop_per_allocation_param DECIMAL(10,2) DEFAULT 0,
    contract_url_param TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    employee_id UUID;
BEGIN
    INSERT INTO employees (
        startup_id, name, joining_date, entity, department, salary,
        esop_allocation, allocation_type, esop_per_allocation, contract_url
    ) VALUES (
        startup_id_param, name_param, joining_date_param, entity_param, 
        department_param, salary_param, esop_allocation_param, allocation_type_param,
        esop_per_allocation_param, contract_url_param
    ) RETURNING id INTO employee_id;
    
    RETURN employee_id;
END;
$$ LANGUAGE plpgsql;

-- Function to add investment record
CREATE OR REPLACE FUNCTION add_investment_record(
    startup_id_param INTEGER,
    date_param DATE,
    investor_type_param investor_type,
    investment_type_param investment_round_type,
    investor_name_param TEXT,
    investor_code_param TEXT DEFAULT NULL,
    amount_param DECIMAL(15,2),
    equity_allocated_param DECIMAL(5,2),
    pre_money_valuation_param DECIMAL(15,2),
    proof_url_param TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    record_id UUID;
BEGIN
    INSERT INTO investment_records (
        startup_id, date, investor_type, investment_type, investor_name,
        investor_code, amount, equity_allocated, pre_money_valuation, proof_url
    ) VALUES (
        startup_id_param, date_param, investor_type_param, investment_type_param,
        investor_name_param, investor_code_param, amount_param, equity_allocated_param,
        pre_money_valuation_param, proof_url_param
    ) RETURNING id INTO record_id;
    
    -- Update startup funding
    UPDATE startups 
    SET total_funding = total_funding + amount_param
    WHERE id = startup_id_param;
    
    RETURN record_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 4: REAL-TIME SUBSCRIPTIONS
-- =====================================================

-- Enable real-time for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE financial_records;
ALTER PUBLICATION supabase_realtime ADD TABLE employees;
ALTER PUBLICATION supabase_realtime ADD TABLE investment_records;
ALTER PUBLICATION supabase_realtime ADD TABLE subsidiaries;
ALTER PUBLICATION supabase_realtime ADD TABLE international_ops;

-- =====================================================
-- STEP 5: ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enhanced RLS policies for startup data
CREATE POLICY "Users can view their own startup data" ON public.startups
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own startup data" ON public.startups
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their startup financial records" ON public.financial_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM startups 
            WHERE id = financial_records.startup_id 
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage their startup financial records" ON public.financial_records
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM startups 
            WHERE id = financial_records.startup_id 
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can view their startup employees" ON public.employees
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM startups 
            WHERE id = employees.startup_id 
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage their startup employees" ON public.employees
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM startups 
            WHERE id = employees.startup_id 
            AND user_id = auth.uid()
        )
    );

-- =====================================================
-- STEP 6: SAMPLE DATA INSERTION (for testing)
-- =====================================================

-- Insert sample startup if not exists
INSERT INTO public.startups (
    name, investment_type, investment_value, equity_allocation, 
    current_valuation, compliance_status, sector, total_funding, 
    total_revenue, registration_date, user_id
) VALUES (
    'TechStart Inc', 'Seed', 500000, 10.0, 5000000, 'Compliant', 
    'Technology', 500000, 150000, '2023-01-15', 
    (SELECT id FROM auth.users LIMIT 1)
) ON CONFLICT DO NOTHING;

-- Get the startup ID for sample data
DO $$
DECLARE
    sample_startup_id INTEGER;
BEGIN
    SELECT id INTO sample_startup_id FROM startups WHERE name = 'TechStart Inc' LIMIT 1;
    
    IF sample_startup_id IS NOT NULL THEN
        -- Insert sample financial records
        INSERT INTO financial_records (startup_id, date, entity, description, vertical, amount, funding_source)
        VALUES 
            (sample_startup_id, '2024-01-15', 'Parent', 'AWS Services', 'Infrastructure', 2500, 'Series A'),
            (sample_startup_id, '2024-01-20', 'Parent', 'Salaries - Engineering', 'Salary', 50000, 'Series A'),
            (sample_startup_id, '2024-01-25', 'Parent', 'SaaS Revenue', 'SaaS', 15000, NULL),
            (sample_startup_id, '2024-02-10', 'Parent', 'Marketing Expenses', 'Marketing', 5000, 'Series A'),
            (sample_startup_id, '2024-02-15', 'Parent', 'Consulting Revenue', 'Consulting', 8000, NULL)
        ON CONFLICT DO NOTHING;
        
        -- Insert sample employees
        INSERT INTO employees (startup_id, name, joining_date, entity, department, salary, esop_allocation)
        VALUES 
            (sample_startup_id, 'John Doe', '2024-01-01', 'Parent', 'Engineering', 120000, 50000),
            (sample_startup_id, 'Jane Smith', '2024-01-15', 'Parent', 'Sales', 90000, 35000)
        ON CONFLICT DO NOTHING;
        
        -- Insert sample investment records
        INSERT INTO investment_records (startup_id, date, investor_type, investment_type, investor_name, amount, equity_allocated, pre_money_valuation)
        VALUES 
            (sample_startup_id, '2024-01-01', 'VC Firm', 'Equity', 'SeedFund Ventures', 500000, 10.0, 4500000)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- =====================================================
-- STEP 7: USAGE EXAMPLES
-- =====================================================

/*
-- Example usage of the functions:

-- Get monthly financial data for charts
SELECT * FROM get_monthly_financial_data(1, 2024);

-- Get fund usage breakdown
SELECT * FROM get_fund_usage_breakdown(1);

-- Get revenue by vertical
SELECT * FROM get_revenue_by_vertical(1, 2024);

-- Get startup summary stats
SELECT * FROM get_startup_summary_stats(1);

-- Add new financial record
SELECT add_financial_record(
    1, '2024-03-01', 'Parent', 'New Revenue', 'SaaS', 20000, NULL, NULL
);

-- Add new employee
SELECT add_employee(
    1, 'New Employee', '2024-03-01', 'Parent', 'Engineering', 100000, 25000
);
*/
