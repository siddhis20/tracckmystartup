-- Co-Investment Opportunities Database Schema
-- This script creates the necessary tables and functions for managing co-investment opportunities

-- 1. CREATE CO_INVESTMENT_OPPORTUNITIES TABLE
CREATE TABLE IF NOT EXISTS co_investment_opportunities (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER NOT NULL,
    listed_by_user_id UUID NOT NULL,
    listed_by_type VARCHAR(20) NOT NULL CHECK (listed_by_type IN ('Investor', 'Investment Advisor')),
    investment_amount DECIMAL(15,2) NOT NULL,
    equity_percentage DECIMAL(5,2),
    minimum_co_investment DECIMAL(15,2),
    maximum_co_investment DECIMAL(15,2),
    description TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_startup_id FOREIGN KEY (startup_id) REFERENCES startups(id) ON DELETE CASCADE,
    CONSTRAINT fk_listed_by_user_id FOREIGN KEY (listed_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 2. CREATE CO_INVESTMENT_INTERESTS TABLE (for tracking who is interested in co-investing)
CREATE TABLE IF NOT EXISTS co_investment_interests (
    id SERIAL PRIMARY KEY,
    opportunity_id INTEGER NOT NULL,
    interested_user_id UUID NOT NULL,
    interested_user_type VARCHAR(20) NOT NULL CHECK (interested_user_type IN ('Investor', 'Investment Advisor')),
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_opportunity_id FOREIGN KEY (opportunity_id) REFERENCES co_investment_opportunities(id) ON DELETE CASCADE,
    CONSTRAINT fk_interested_user_id FOREIGN KEY (interested_user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    -- Unique constraint to prevent duplicate interests
    UNIQUE(opportunity_id, interested_user_id)
);

-- 3. CREATE CO_INVESTMENT_APPROVALS TABLE (for investment advisor approvals)
CREATE TABLE IF NOT EXISTS co_investment_approvals (
    id SERIAL PRIMARY KEY,
    opportunity_id INTEGER NOT NULL,
    advisor_id UUID NOT NULL,
    investor_id UUID NOT NULL,
    approved BOOLEAN DEFAULT FALSE,
    approval_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_opportunity_id_approval FOREIGN KEY (opportunity_id) REFERENCES co_investment_opportunities(id) ON DELETE CASCADE,
    CONSTRAINT fk_advisor_id FOREIGN KEY (advisor_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_investor_id FOREIGN KEY (investor_id) REFERENCES users(id) ON DELETE CASCADE,
    
    -- Unique constraint to prevent duplicate approvals
    UNIQUE(opportunity_id, advisor_id, investor_id)
);

-- 4. CREATE INDEXES FOR BETTER PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_co_investment_opportunities_startup_id ON co_investment_opportunities(startup_id);
CREATE INDEX IF NOT EXISTS idx_co_investment_opportunities_listed_by ON co_investment_opportunities(listed_by_user_id, listed_by_type);
CREATE INDEX IF NOT EXISTS idx_co_investment_opportunities_status ON co_investment_opportunities(status);
CREATE INDEX IF NOT EXISTS idx_co_investment_opportunities_created_at ON co_investment_opportunities(created_at);

CREATE INDEX IF NOT EXISTS idx_co_investment_interests_opportunity_id ON co_investment_interests(opportunity_id);
CREATE INDEX IF NOT EXISTS idx_co_investment_interests_user_id ON co_investment_interests(interested_user_id);
CREATE INDEX IF NOT EXISTS idx_co_investment_interests_status ON co_investment_interests(status);

CREATE INDEX IF NOT EXISTS idx_co_investment_approvals_opportunity_id ON co_investment_approvals(opportunity_id);
CREATE INDEX IF NOT EXISTS idx_co_investment_approvals_advisor_id ON co_investment_approvals(advisor_id);
CREATE INDEX IF NOT EXISTS idx_co_investment_approvals_investor_id ON co_investment_approvals(investor_id);

-- 5. CREATE FUNCTIONS FOR CO-INVESTMENT OPERATIONS

-- Function to create a new co-investment opportunity
CREATE OR REPLACE FUNCTION create_co_investment_opportunity(
    p_startup_id INTEGER,
    p_listed_by_user_id UUID,
    p_listed_by_type VARCHAR(20),
    p_investment_amount DECIMAL(15,2),
    p_equity_percentage DECIMAL(5,2) DEFAULT NULL,
    p_minimum_co_investment DECIMAL(15,2) DEFAULT NULL,
    p_maximum_co_investment DECIMAL(15,2) DEFAULT NULL,
    p_description TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    opportunity_id INTEGER;
BEGIN
    INSERT INTO co_investment_opportunities (
        startup_id,
        listed_by_user_id,
        listed_by_type,
        investment_amount,
        equity_percentage,
        minimum_co_investment,
        maximum_co_investment,
        description
    ) VALUES (
        p_startup_id,
        p_listed_by_user_id,
        p_listed_by_type,
        p_investment_amount,
        p_equity_percentage,
        p_minimum_co_investment,
        p_maximum_co_investment,
        p_description
    ) RETURNING id INTO opportunity_id;
    
    RETURN opportunity_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get co-investment opportunities for a user based on their advisor relationship
CREATE OR REPLACE FUNCTION get_co_investment_opportunities_for_user(p_user_id UUID)
RETURNS TABLE (
    opportunity_id INTEGER,
    startup_id INTEGER,
    startup_name VARCHAR(255),
    startup_sector VARCHAR(100),
    startup_stage VARCHAR(50),
    listed_by_user_id INTEGER,
    listed_by_name VARCHAR(255),
    listed_by_type VARCHAR(20),
    investment_amount DECIMAL(15,2),
    equity_percentage DECIMAL(5,2),
    minimum_co_investment DECIMAL(15,2),
    maximum_co_investment DECIMAL(15,2),
    description TEXT,
    status VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cio.id as opportunity_id,
        cio.startup_id,
        s.name as startup_name,
        s.sector as startup_sector,
        s.stage as startup_stage,
        cio.listed_by_user_id,
        u.name as listed_by_name,
        cio.listed_by_type,
        cio.investment_amount,
        cio.equity_percentage,
        cio.minimum_co_investment,
        cio.maximum_co_investment,
        cio.description,
        cio.status,
        cio.created_at
    FROM co_investment_opportunities cio
    JOIN startups s ON cio.startup_id = s.id
    JOIN users u ON cio.listed_by_user_id = u.id
    WHERE cio.status = 'active'
    AND (
        -- If user has an investment advisor, only show opportunities approved by their advisor
        (EXISTS (
            SELECT 1 FROM users user_check 
            WHERE user_check.id = p_user_id 
            AND user_check.investment_advisor_code IS NOT NULL
            AND user_check.advisor_accepted = true
        ) AND EXISTS (
            SELECT 1 FROM co_investment_approvals cia
            JOIN users advisor ON cia.advisor_id = advisor.id
            JOIN users investor ON cia.investor_id = investor.id
            WHERE cia.opportunity_id = cio.id
            AND investor.id = p_user_id
            AND cia.approved = true
        ))
        OR
        -- If user doesn't have an investment advisor, show all opportunities
        (NOT EXISTS (
            SELECT 1 FROM users user_check 
            WHERE user_check.id = p_user_id 
            AND user_check.investment_advisor_code IS NOT NULL
            AND user_check.advisor_accepted = true
        ))
    )
    ORDER BY cio.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get all co-investment opportunities for investment advisors
CREATE OR REPLACE FUNCTION get_all_co_investment_opportunities()
RETURNS TABLE (
    opportunity_id INTEGER,
    startup_id INTEGER,
    startup_name VARCHAR(255),
    startup_sector VARCHAR(100),
    startup_stage VARCHAR(50),
    listed_by_user_id INTEGER,
    listed_by_name VARCHAR(255),
    listed_by_type VARCHAR(20),
    investment_amount DECIMAL(15,2),
    equity_percentage DECIMAL(5,2),
    minimum_co_investment DECIMAL(15,2),
    maximum_co_investment DECIMAL(15,2),
    description TEXT,
    status VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cio.id as opportunity_id,
        cio.startup_id,
        s.name as startup_name,
        s.sector as startup_sector,
        s.stage as startup_stage,
        cio.listed_by_user_id,
        u.name as listed_by_name,
        cio.listed_by_type,
        cio.investment_amount,
        cio.equity_percentage,
        cio.minimum_co_investment,
        cio.maximum_co_investment,
        cio.description,
        cio.status,
        cio.created_at
    FROM co_investment_opportunities cio
    JOIN startups s ON cio.startup_id = s.id
    JOIN users u ON cio.listed_by_user_id = u.id
    WHERE cio.status = 'active'
    ORDER BY cio.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to express interest in a co-investment opportunity
CREATE OR REPLACE FUNCTION express_co_investment_interest(
    p_opportunity_id INTEGER,
    p_interested_user_id UUID,
    p_interested_user_type VARCHAR(20),
    p_message TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    interest_id INTEGER;
BEGIN
    INSERT INTO co_investment_interests (
        opportunity_id,
        interested_user_id,
        interested_user_type,
        message
    ) VALUES (
        p_opportunity_id,
        p_interested_user_id,
        p_interested_user_type,
        p_message
    ) RETURNING id INTO interest_id;
    
    RETURN interest_id;
END;
$$ LANGUAGE plpgsql;

-- Function to approve/reject co-investment interest for an advisor
CREATE OR REPLACE FUNCTION approve_co_investment_interest(
    p_opportunity_id INTEGER,
    p_advisor_id UUID,
    p_investor_id UUID,
    p_approved BOOLEAN,
    p_approval_notes TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    approval_id INTEGER;
BEGIN
    INSERT INTO co_investment_approvals (
        opportunity_id,
        advisor_id,
        investor_id,
        approved,
        approval_notes
    ) VALUES (
        p_opportunity_id,
        p_advisor_id,
        p_investor_id,
        p_approved,
        p_approval_notes
    ) 
    ON CONFLICT (opportunity_id, advisor_id, investor_id) 
    DO UPDATE SET 
        approved = p_approved,
        approval_notes = p_approval_notes,
        updated_at = CURRENT_TIMESTAMP
    RETURNING id INTO approval_id;
    
    RETURN approval_id;
END;
$$ LANGUAGE plpgsql;

-- 6. CREATE TRIGGERS FOR UPDATED_AT TIMESTAMPS
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_co_investment_opportunities_updated_at
    BEFORE UPDATE ON co_investment_opportunities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_co_investment_interests_updated_at
    BEFORE UPDATE ON co_investment_interests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_co_investment_approvals_updated_at
    BEFORE UPDATE ON co_investment_approvals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 7. ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE co_investment_opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE co_investment_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE co_investment_approvals ENABLE ROW LEVEL SECURITY;

-- 8. CREATE RLS POLICIES
-- Policy for co_investment_opportunities: Users can see opportunities based on their advisor relationship
CREATE POLICY co_investment_opportunities_select_policy ON co_investment_opportunities
    FOR SELECT
    USING (
        -- Investment advisors can see all opportunities
        (EXISTS (SELECT 1 FROM users WHERE users.id = current_setting('app.current_user_id')::UUID AND users.role = 'Investment Advisor'))
        OR
        -- Investors can see opportunities based on their advisor relationship
        (EXISTS (SELECT 1 FROM users WHERE users.id = current_setting('app.current_user_id')::UUID AND users.role = 'Investor' AND (
            -- If they have an advisor, only show approved opportunities
            (users.investment_advisor_code IS NOT NULL AND users.advisor_accepted = true AND 
             EXISTS (SELECT 1 FROM co_investment_approvals WHERE opportunity_id = co_investment_opportunities.id AND investor_id = users.id AND approved = true))
            OR
            -- If they don't have an advisor, show all opportunities
            (users.investment_advisor_code IS NULL OR users.advisor_accepted = false)
        )))
    );

-- Policy for co_investment_interests: Users can see their own interests
CREATE POLICY co_investment_interests_select_policy ON co_investment_interests
    FOR SELECT
    USING (interested_user_id = current_setting('app.current_user_id')::UUID);

-- Policy for co_investment_approvals: Advisors can see approvals for their clients
CREATE POLICY co_investment_approvals_select_policy ON co_investment_approvals
    FOR SELECT
    USING (
        advisor_id = current_setting('app.current_user_id')::UUID
        OR investor_id = current_setting('app.current_user_id')::UUID
    );

-- 9. GRANT PERMISSIONS
GRANT SELECT, INSERT, UPDATE ON co_investment_opportunities TO authenticated;
GRANT SELECT, INSERT, UPDATE ON co_investment_interests TO authenticated;
GRANT SELECT, INSERT, UPDATE ON co_investment_approvals TO authenticated;

GRANT USAGE ON SEQUENCE co_investment_opportunities_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE co_investment_interests_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE co_investment_approvals_id_seq TO authenticated;

GRANT EXECUTE ON FUNCTION create_co_investment_opportunity TO authenticated;
GRANT EXECUTE ON FUNCTION get_co_investment_opportunities_for_user TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_co_investment_opportunities TO authenticated;
GRANT EXECUTE ON FUNCTION express_co_investment_interest TO authenticated;
GRANT EXECUTE ON FUNCTION approve_co_investment_interest TO authenticated;

-- 10. INSERT SAMPLE DATA (OPTIONAL - FOR TESTING)
-- Uncomment the following lines to insert sample data for testing

/*
INSERT INTO co_investment_opportunities (
    startup_id, listed_by_user_id, listed_by_type, investment_amount, 
    equity_percentage, minimum_co_investment, maximum_co_investment, description
) VALUES 
(1, 1, 'Investor', 1000000.00, 10.00, 100000.00, 500000.00, 'Looking for co-investors in this promising fintech startup'),
(2, 2, 'Investment Advisor', 2000000.00, 15.00, 200000.00, 1000000.00, 'Excellent opportunity in the healthcare sector');
*/

COMMENT ON TABLE co_investment_opportunities IS 'Stores co-investment opportunities listed by investors and investment advisors';
COMMENT ON TABLE co_investment_interests IS 'Tracks user interest in co-investment opportunities';
COMMENT ON TABLE co_investment_approvals IS 'Stores investment advisor approvals for co-investment opportunities';
