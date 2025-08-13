-- =====================================================
-- FINANCIALS BACKEND SETUP
-- =====================================================

-- Create financial records table (unified for both expenses and revenue)
CREATE TABLE IF NOT EXISTS financial_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    record_type VARCHAR(20) NOT NULL CHECK (record_type IN ('expense', 'revenue')),
    date DATE NOT NULL,
    entity VARCHAR(100) NOT NULL,
    description TEXT,
    vertical VARCHAR(100) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    funding_source VARCHAR(100), -- For expenses
    cogs DECIMAL(15,2), -- For revenue (Cost of Goods Sold)
    attachment_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_financial_records_startup_id ON financial_records(startup_id);
CREATE INDEX IF NOT EXISTS idx_financial_records_date ON financial_records(date);
CREATE INDEX IF NOT EXISTS idx_financial_records_type ON financial_records(record_type);
CREATE INDEX IF NOT EXISTS idx_financial_records_entity ON financial_records(entity);
CREATE INDEX IF NOT EXISTS idx_financial_records_vertical ON financial_records(vertical);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_financial_records_updated_at 
    BEFORE UPDATE ON financial_records 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create RLS policies
ALTER TABLE financial_records ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see financial records for startups they own
CREATE POLICY "Users can view their own financial records" ON financial_records
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can insert financial records for their startups
CREATE POLICY "Users can insert their own financial records" ON financial_records
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can update their own financial records
CREATE POLICY "Users can update their own financial records" ON financial_records
    FOR UPDATE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Policy: Users can delete their own financial records
CREATE POLICY "Users can delete their own financial records" ON financial_records
    FOR DELETE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Admin can view all financial records
CREATE POLICY "Admins can view all financial records" ON financial_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role = 'Admin'
        )
    );

-- CA can view all financial records for compliance
CREATE POLICY "CA can view all financial records" ON financial_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role = 'CA'
        )
    );

-- CS can view all financial records for compliance
CREATE POLICY "CS can view all financial records" ON financial_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role = 'CS'
        )
    );

-- =====================================================
-- HELPER FUNCTIONS FOR FINANCIAL CALCULATIONS
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
(1, 'revenue', '2024-03-30', 'Parent Company', 'SaaS Subscription Revenue', 'SaaS', 12000.00, NULL, 3000.00, NULL);

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Verify the setup
SELECT 'Financial records table created successfully' as status;

-- Test the functions
SELECT * FROM get_monthly_financial_data(1, 2024);
SELECT * FROM get_revenue_by_vertical(1, 2024);
SELECT * FROM get_expenses_by_vertical(1, 2024);
SELECT * FROM get_startup_financial_summary(1);
