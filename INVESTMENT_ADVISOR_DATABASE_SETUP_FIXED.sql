-- Investment Advisor Database Setup - FIXED VERSION
-- This script creates all necessary tables, columns, and policies for the Investment Advisor system
-- Fixed: UUID data types for foreign keys and proper RLS policies for user registration

-- 0. CRITICAL: Update the user_role enum to include Investment Advisor
-- First, check if the enum exists and add the new value
DO $$ 
BEGIN
    -- Add 'Investment Advisor' to the user_role enum if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'Investment Advisor' 
        AND enumtypid = (
            SELECT oid FROM pg_type WHERE typname = 'user_role'
        )
    ) THEN
        ALTER TYPE user_role ADD VALUE 'Investment Advisor';
    END IF;
END $$;

-- 1. Add Investment Advisor specific columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS investment_advisor_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS logo_url TEXT,
ADD COLUMN IF NOT EXISTS proof_of_business_url TEXT,
ADD COLUMN IF NOT EXISTS financial_advisor_license_url TEXT;

-- 2. Add Investment Advisor code to startups table
ALTER TABLE startups 
ADD COLUMN IF NOT EXISTS investment_advisor_code TEXT;

-- 3. Add Investment Advisor code to startup_addition_requests table
ALTER TABLE startup_addition_requests 
ADD COLUMN IF NOT EXISTS investment_advisor_code TEXT;

-- 4. Create investment_advisor_recommendations table
CREATE TABLE IF NOT EXISTS investment_advisor_recommendations (
    id SERIAL PRIMARY KEY,
    investment_advisor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    investor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recommended_deal_value DECIMAL(15,2),
    recommended_valuation DECIMAL(15,2),
    recommendation_notes TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'viewed', 'interested', 'not_interested')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create investment_advisor_relationships table to track advisor-investor-startup relationships
CREATE TABLE IF NOT EXISTS investment_advisor_relationships (
    id SERIAL PRIMARY KEY,
    investment_advisor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    investor_id UUID REFERENCES users(id) ON DELETE CASCADE,
    startup_id INTEGER REFERENCES startups(id) ON DELETE CASCADE,
    relationship_type TEXT NOT NULL CHECK (relationship_type IN ('advisor_investor', 'advisor_startup')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(investment_advisor_id, investor_id, relationship_type),
    UNIQUE(investment_advisor_id, startup_id, relationship_type)
);

-- 6. Create investment_advisor_commissions table to track scouting fees
CREATE TABLE IF NOT EXISTS investment_advisor_commissions (
    id SERIAL PRIMARY KEY,
    investment_advisor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    investor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    investment_amount DECIMAL(15,2) NOT NULL,
    success_fee_percentage DECIMAL(5,2) DEFAULT 0.00,
    success_fee_amount DECIMAL(15,2) DEFAULT 0.00,
    scouting_fee_percentage DECIMAL(5,2) DEFAULT 30.00, -- 30% of success fee
    scouting_fee_amount DECIMAL(15,2) DEFAULT 0.00,
    commission_status TEXT DEFAULT 'pending' CHECK (commission_status IN ('pending', 'approved', 'paid', 'disputed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Create function to generate Investment Advisor codes
CREATE OR REPLACE FUNCTION generate_investment_advisor_code()
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a code like IA-XXXXXX
        new_code := 'IA-' || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM users WHERE investment_advisor_code = new_code) INTO code_exists;
        
        -- If code doesn't exist, return it
        IF NOT code_exists THEN
            RETURN new_code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger to auto-generate Investment Advisor code on user creation
CREATE OR REPLACE FUNCTION set_investment_advisor_code()
RETURNS TRIGGER AS $$
BEGIN
    -- Only set code for Investment Advisor role
    IF NEW.role = 'Investment Advisor' AND NEW.investment_advisor_code IS NULL THEN
        NEW.investment_advisor_code := generate_investment_advisor_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_investment_advisor_code
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION set_investment_advisor_code();

-- 9. Create function to get Investment Advisor's investors
CREATE OR REPLACE FUNCTION get_investment_advisor_investors(advisor_id UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    email TEXT,
    registration_date DATE,
    investor_code TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.name,
        u.email,
        u.registration_date::DATE,
        u.investor_code
    FROM users u
    WHERE u.role = 'Investor' 
    AND u.investment_advisor_code = (
        SELECT investment_advisor_code 
        FROM users 
        WHERE id = advisor_id AND role = 'Investment Advisor'
    );
END;
$$ LANGUAGE plpgsql;

-- 10. Create function to get Investment Advisor's startups
CREATE OR REPLACE FUNCTION get_investment_advisor_startups(advisor_id UUID)
RETURNS TABLE (
    id INTEGER,
    name TEXT,
    sector TEXT,
    current_valuation DECIMAL(15,2),
    compliance_status TEXT,
    total_funding DECIMAL(15,2),
    total_revenue DECIMAL(15,2),
    registration_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.sector,
        s.current_valuation,
        s.compliance_status,
        s.total_funding,
        s.total_revenue,
        s.registration_date::DATE
    FROM startups s
    WHERE s.investment_advisor_code = (
        SELECT investment_advisor_code 
        FROM users 
        WHERE id = advisor_id AND role = 'Investment Advisor'
    );
END;
$$ LANGUAGE plpgsql;

-- 11. Create function to create investment advisor recommendation
CREATE OR REPLACE FUNCTION create_investment_advisor_recommendation(
    p_advisor_id UUID,
    p_startup_id INTEGER,
    p_investor_ids UUID[],
    p_deal_value DECIMAL(15,2),
    p_valuation DECIMAL(15,2),
    p_notes TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    recommendation_id INTEGER;
    investor_id UUID;
BEGIN
    -- Create recommendation for each investor
    FOREACH investor_id IN ARRAY p_investor_ids
    LOOP
        INSERT INTO investment_advisor_recommendations (
            investment_advisor_id,
            startup_id,
            investor_id,
            recommended_deal_value,
            recommended_valuation,
            recommendation_notes
        ) VALUES (
            p_advisor_id,
            p_startup_id,
            investor_id,
            p_deal_value,
            p_valuation,
            p_notes
        ) RETURNING id INTO recommendation_id;
    END LOOP;
    
    RETURN recommendation_id;
END;
$$ LANGUAGE plpgsql;

-- 12. Create function to get recommendations for an investor
CREATE OR REPLACE FUNCTION get_investor_recommendations(investor_id UUID)
RETURNS TABLE (
    id INTEGER,
    startup_name TEXT,
    startup_sector TEXT,
    startup_valuation DECIMAL(15,2),
    recommended_deal_value DECIMAL(15,2),
    recommended_valuation DECIMAL(15,2),
    recommendation_notes TEXT,
    advisor_name TEXT,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        iar.id,
        s.name,
        s.sector,
        s.current_valuation,
        iar.recommended_deal_value,
        iar.recommended_valuation,
        iar.recommendation_notes,
        u.name as advisor_name,
        iar.status,
        iar.created_at
    FROM investment_advisor_recommendations iar
    JOIN startups s ON iar.startup_id = s.id
    JOIN users u ON iar.investment_advisor_id = u.id
    WHERE iar.investor_id = investor_id
    ORDER BY iar.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 13. Create RLS policies for investment_advisor_recommendations
ALTER TABLE investment_advisor_recommendations ENABLE ROW LEVEL SECURITY;

-- Policy for Investment Advisors to see their own recommendations
CREATE POLICY "Investment Advisors can view their own recommendations" ON investment_advisor_recommendations
    FOR SELECT USING (
        investment_advisor_id = auth.uid()
    );

-- Policy for Investors to see recommendations made to them
CREATE POLICY "Investors can view recommendations made to them" ON investment_advisor_recommendations
    FOR SELECT USING (
        investor_id = auth.uid()
    );

-- Policy for Investment Advisors to create recommendations
CREATE POLICY "Investment Advisors can create recommendations" ON investment_advisor_recommendations
    FOR INSERT WITH CHECK (
        investment_advisor_id = auth.uid()
    );

-- Policy for updating recommendation status
CREATE POLICY "Users can update recommendation status" ON investment_advisor_recommendations
    FOR UPDATE USING (
        investment_advisor_id = auth.uid() OR investor_id = auth.uid()
    );

-- 14. Create RLS policies for investment_advisor_relationships
ALTER TABLE investment_advisor_relationships ENABLE ROW LEVEL SECURITY;

-- Policy for Investment Advisors to manage their relationships
CREATE POLICY "Investment Advisors can manage their relationships" ON investment_advisor_relationships
    FOR ALL USING (
        investment_advisor_id = auth.uid()
    );

-- Policy for users to view relationships they're part of
CREATE POLICY "Users can view their relationships" ON investment_advisor_relationships
    FOR SELECT USING (
        investment_advisor_id = auth.uid() OR 
        investor_id = auth.uid() OR 
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- 15. Create RLS policies for investment_advisor_commissions
ALTER TABLE investment_advisor_commissions ENABLE ROW LEVEL SECURITY;

-- Policy for Investment Advisors to view their commissions
CREATE POLICY "Investment Advisors can view their commissions" ON investment_advisor_commissions
    FOR SELECT USING (
        investment_advisor_id = auth.uid()
    );

-- Policy for Admins to manage commissions
CREATE POLICY "Admins can manage commissions" ON investment_advisor_commissions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'Admin'
        )
    );

-- 16. CRITICAL: Fix users table RLS policies to allow registration
-- First, check if RLS is enabled on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies that might be blocking registration
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;

-- Create comprehensive users table policies
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (
        id = auth.uid() OR 
        role = 'Admin' OR
        (role = 'Investment Advisor' AND investment_advisor_code IN (
            SELECT investment_advisor_code FROM users WHERE id = auth.uid()
        ))
    );

-- CRITICAL: Allow users to insert their own profile (for registration)
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (
        id = auth.uid()
    );

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (
        id = auth.uid()
    );

-- 17. Update startups table policies to include Investment Advisor role
DROP POLICY IF EXISTS "Users can view startups" ON startups;
CREATE POLICY "Users can view startups" ON startups
    FOR SELECT USING (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role IN ('Admin', 'CA', 'CS', 'Startup Facilitation Center', 'Investment Advisor')
        ) OR
        (investment_advisor_code IN (
            SELECT investment_advisor_code FROM users WHERE id = auth.uid()
        ))
    );

-- 18. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_investment_advisor_code ON users(investment_advisor_code);
CREATE INDEX IF NOT EXISTS idx_startups_investment_advisor_code ON startups(investment_advisor_code);
CREATE INDEX IF NOT EXISTS idx_investment_advisor_recommendations_advisor ON investment_advisor_recommendations(investment_advisor_id);
CREATE INDEX IF NOT EXISTS idx_investment_advisor_recommendations_investor ON investment_advisor_recommendations(investor_id);
CREATE INDEX IF NOT EXISTS idx_investment_advisor_recommendations_startup ON investment_advisor_recommendations(startup_id);
CREATE INDEX IF NOT EXISTS idx_investment_advisor_relationships_advisor ON investment_advisor_relationships(investment_advisor_id);
CREATE INDEX IF NOT EXISTS idx_investment_advisor_commissions_advisor ON investment_advisor_commissions(investment_advisor_id);

-- 19. Create storage bucket for Investment Advisor documents
INSERT INTO storage.buckets (id, name, public) 
VALUES ('investment-advisor-documents', 'investment-advisor-documents', false)
ON CONFLICT (id) DO NOTHING;

-- 20. Create storage policies for Investment Advisor documents
CREATE POLICY "Investment Advisors can upload their own documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'investment-advisor-documents' AND
        auth.uid() IN (
            SELECT id FROM users WHERE role = 'Investment Advisor'
        )
    );

CREATE POLICY "Investment Advisors can view their own documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'investment-advisor-documents' AND
        auth.uid() IN (
            SELECT id FROM users WHERE role = 'Investment Advisor'
        )
    );

CREATE POLICY "Admins can view all Investment Advisor documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'investment-advisor-documents' AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'Admin'
        )
    );

-- 21. Create function to calculate scouting fees
CREATE OR REPLACE FUNCTION calculate_scouting_fee(
    p_investment_amount DECIMAL(15,2),
    p_success_fee_percentage DECIMAL(5,2) DEFAULT 5.00
)
RETURNS TABLE (
    success_fee_amount DECIMAL(15,2),
    scouting_fee_amount DECIMAL(15,2)
) AS $$
DECLARE
    success_fee DECIMAL(15,2);
    scouting_fee DECIMAL(15,2);
BEGIN
    success_fee := (p_investment_amount * p_success_fee_percentage) / 100;
    scouting_fee := (success_fee * 30) / 100; -- 30% of success fee
    
    RETURN QUERY SELECT success_fee, scouting_fee;
END;
$$ LANGUAGE plpgsql;

-- 22. Create view for Investment Advisor dashboard metrics
CREATE OR REPLACE VIEW investment_advisor_dashboard_metrics AS
SELECT 
    u.id as advisor_id,
    u.name as advisor_name,
    u.investment_advisor_code,
    COUNT(DISTINCT iar.investor_id) as total_investors,
    COUNT(DISTINCT iar.startup_id) as total_startups,
    COUNT(DISTINCT iar.id) as total_recommendations,
    COALESCE(SUM(iac.investment_amount), 0) as total_investments_facilitated,
    COALESCE(SUM(iac.scouting_fee_amount), 0) as total_scouting_fees
FROM users u
LEFT JOIN investment_advisor_relationships iar ON u.id = iar.investment_advisor_id
LEFT JOIN investment_advisor_commissions iac ON u.id = iac.investment_advisor_id
WHERE u.role = 'Investment Advisor'
GROUP BY u.id, u.name, u.investment_advisor_code;

-- 23. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- 24. Create function to update relationship when user adds advisor code
CREATE OR REPLACE FUNCTION update_investment_advisor_relationship()
RETURNS TRIGGER AS $$
BEGIN
    -- If user is an investor and has an investment advisor code
    IF NEW.role = 'Investor' AND NEW.investment_advisor_code IS NOT NULL THEN
        INSERT INTO investment_advisor_relationships (
            investment_advisor_id,
            investor_id,
            relationship_type
        ) VALUES (
            (SELECT id FROM users WHERE investment_advisor_code = NEW.investment_advisor_code AND role = 'Investment Advisor' LIMIT 1),
            NEW.id,
            'advisor_investor'
        ) ON CONFLICT (investment_advisor_id, investor_id, relationship_type) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_investment_advisor_relationship
    AFTER UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_investment_advisor_relationship();

-- 25. Create function to update startup relationship when startup adds advisor code
CREATE OR REPLACE FUNCTION update_startup_investment_advisor_relationship()
RETURNS TRIGGER AS $$
BEGIN
    -- If startup has an investment advisor code
    IF NEW.investment_advisor_code IS NOT NULL THEN
        INSERT INTO investment_advisor_relationships (
            investment_advisor_id,
            startup_id,
            relationship_type
        ) VALUES (
            (SELECT id FROM users WHERE investment_advisor_code = NEW.investment_advisor_code AND role = 'Investment Advisor' LIMIT 1),
            NEW.id,
            'advisor_startup'
        ) ON CONFLICT (investment_advisor_id, startup_id, relationship_type) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_startup_investment_advisor_relationship
    AFTER UPDATE ON startups
    FOR EACH ROW
    EXECUTE FUNCTION update_startup_investment_advisor_relationship();

-- 26. Add Investment Advisor code field to registration forms (this would be handled in the frontend)
-- The field would be optional and allow users to enter an Investment Advisor code during registration

COMMENT ON TABLE investment_advisor_recommendations IS 'Stores recommendations made by Investment Advisors to their investors';
COMMENT ON TABLE investment_advisor_relationships IS 'Tracks relationships between Investment Advisors, Investors, and Startups';
COMMENT ON TABLE investment_advisor_commissions IS 'Tracks scouting fees and commissions for Investment Advisors';
COMMENT ON COLUMN users.investment_advisor_code IS 'Unique code for Investment Advisor users';
COMMENT ON COLUMN users.logo_url IS 'URL to Investment Advisor company logo';
COMMENT ON COLUMN users.proof_of_business_url IS 'URL to proof of business document';
COMMENT ON COLUMN users.financial_advisor_license_url IS 'URL to financial advisor license document';
COMMENT ON COLUMN startups.investment_advisor_code IS 'Investment Advisor code associated with this startup';
COMMENT ON COLUMN startup_addition_requests.investment_advisor_code IS 'Investment Advisor code associated with this startup addition request';

-- 27. IMPORTANT: Test the setup by creating a test Investment Advisor user
-- This is commented out but can be uncommented for testing
/*
INSERT INTO users (id, email, name, role, registration_date, investment_advisor_code)
VALUES (
    gen_random_uuid(),
    'test-advisor@example.com',
    'Test Investment Advisor',
    'Investment Advisor',
    CURRENT_DATE,
    'IA-123456'
) ON CONFLICT (email) DO NOTHING;
*/
