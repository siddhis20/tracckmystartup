-- =====================================================
-- CAP TABLE RLS POLICIES SETUP
-- =====================================================
-- This script sets up proper Row Level Security policies
-- for Cap Table related tables that are currently unrestricted

-- =====================================================
-- EQUITY HOLDINGS TABLE RLS
-- =====================================================

-- Enable RLS on equity_holdings table
ALTER TABLE equity_holdings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own startup's equity holdings" ON equity_holdings;
DROP POLICY IF EXISTS "Startup users can manage their own equity holdings" ON equity_holdings;

-- Create policies for equity_holdings
CREATE POLICY "Users can view their own startup's equity holdings" ON equity_holdings
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

CREATE POLICY "Startup users can manage their own equity holdings" ON equity_holdings
    FOR ALL USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

-- =====================================================
-- FUNDRAISING DETAILS TABLE RLS
-- =====================================================

-- Enable RLS on fundraising_details table
ALTER TABLE fundraising_details ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own startup's fundraising details" ON fundraising_details;
DROP POLICY IF EXISTS "Startup users can manage their own fundraising details" ON fundraising_details;

-- Create policies for fundraising_details
CREATE POLICY "Users can view their own startup's fundraising details" ON fundraising_details
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

CREATE POLICY "Startup users can manage their own fundraising details" ON fundraising_details
    FOR ALL USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

-- =====================================================
-- VALUATION HISTORY TABLE RLS
-- =====================================================

-- Enable RLS on valuation_history table
ALTER TABLE valuation_history ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own startup's valuation history" ON valuation_history;
DROP POLICY IF EXISTS "Startup users can manage their own valuation history" ON valuation_history;

-- Create policies for valuation_history
CREATE POLICY "Users can view their own startup's valuation history" ON valuation_history
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

CREATE POLICY "Startup users can manage their own valuation history" ON valuation_history
    FOR ALL USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

-- =====================================================
-- INVESTMENT RECORDS TABLE RLS (if not already set)
-- =====================================================

-- Enable RLS on investment_records table if not already enabled
ALTER TABLE investment_records ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own startup's investment records" ON investment_records;
DROP POLICY IF EXISTS "Startup users can manage their own investment records" ON investment_records;

-- Create policies for investment_records
CREATE POLICY "Users can view their own startup's investment records" ON investment_records
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

CREATE POLICY "Startup users can manage their own investment records" ON investment_records
    FOR ALL USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

-- =====================================================
-- FOUNDERS TABLE RLS (if not already set)
-- =====================================================

-- Enable RLS on founders table if not already enabled
ALTER TABLE founders ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own startup's founders" ON founders;
DROP POLICY IF EXISTS "Startup users can manage their own founders" ON founders;

-- Create policies for founders
CREATE POLICY "Users can view their own startup's founders" ON founders
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

CREATE POLICY "Startup users can manage their own founders" ON founders
    FOR ALL USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

-- =====================================================
-- VERIFICATION QUERY
-- =====================================================

-- Check which tables have RLS enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN (
        'equity_holdings',
        'fundraising_details', 
        'valuation_history',
        'investment_records',
        'founders',
        'startup_shares'
    )
ORDER BY tablename;

-- Check existing policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN (
        'equity_holdings',
        'fundraising_details', 
        'valuation_history',
        'investment_records',
        'founders',
        'startup_shares'
    )
ORDER BY tablename, policyname;

-- =====================================================
-- STARTUP_SHARES TABLE RLS
-- =====================================================

-- Enable RLS on startup_shares table
ALTER TABLE IF EXISTS startup_shares ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own startup's shares" ON startup_shares;
DROP POLICY IF EXISTS "Startup users can manage their own shares" ON startup_shares;

-- Create policies for startup_shares
CREATE POLICY "Users can view their own startup's shares" ON startup_shares
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

CREATE POLICY "Startup users can manage their own shares" ON startup_shares
    FOR ALL USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );
