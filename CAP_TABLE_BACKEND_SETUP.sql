-- =====================================================
-- CAP TABLE BACKEND SETUP
-- =====================================================

-- Enable RLS
ALTER TABLE IF EXISTS investment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS founders ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS fundraising_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS valuation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS equity_holdings ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 0.a TOTAL SHARES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS startup_shares (
    startup_id INTEGER PRIMARY KEY REFERENCES startups(id) ON DELETE CASCADE,
    total_shares NUMERIC NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE IF EXISTS startup_shares ENABLE ROW LEVEL SECURITY;

-- Add price_per_share column if missing
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'startup_shares' AND column_name = 'price_per_share'
  ) THEN
    ALTER TABLE public.startup_shares ADD COLUMN price_per_share NUMERIC NOT NULL DEFAULT 0;
  END IF;
END $$;

-- Add ESOP reserved shares column to store company-level ESOP pool shares
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'startup_shares' AND column_name = 'esop_reserved_shares'
  ) THEN
    ALTER TABLE public.startup_shares ADD COLUMN esop_reserved_shares NUMERIC NOT NULL DEFAULT 0;
  END IF;
END $$;

-- =====================================================
-- 1. INVESTMENT RECORDS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS investment_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    investor_type TEXT NOT NULL CHECK (investor_type IN ('Angel', 'VC Firm', 'Corporate', 'Government')),
    investment_type TEXT NOT NULL CHECK (investment_type IN ('Equity', 'Debt', 'Grant')),
    investor_name TEXT NOT NULL,
    investor_code TEXT,
    amount DECIMAL(15,2) NOT NULL,
    equity_allocated DECIMAL(5,2) NOT NULL, -- Percentage
    pre_money_valuation DECIMAL(15,2),
    post_money_valuation DECIMAL(15,2),
    proof_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for investment_records
CREATE INDEX IF NOT EXISTS idx_investment_records_startup_id ON investment_records(startup_id);
CREATE INDEX IF NOT EXISTS idx_investment_records_date ON investment_records(date);
CREATE INDEX IF NOT EXISTS idx_investment_records_investor_type ON investment_records(investor_type);
CREATE INDEX IF NOT EXISTS idx_investment_records_investment_type ON investment_records(investment_type);

-- =====================================================
-- 2. FOUNDERS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS founders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    equity_percentage DECIMAL(5,2) DEFAULT 0, -- Percentage of equity owned
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for founders
CREATE INDEX IF NOT EXISTS idx_founders_startup_id ON founders(startup_id);
CREATE INDEX IF NOT EXISTS idx_founders_email ON founders(email);

-- =====================================================
-- 3. FUNDRAISING DETAILS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS fundraising_details (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    active BOOLEAN DEFAULT false,
    type TEXT NOT NULL CHECK (type IN ('Pre-Seed', 'Seed', 'Series A', 'Series B', 'Bridge')),
    value DECIMAL(15,2) NOT NULL,
    equity DECIMAL(5,2) NOT NULL, -- Percentage
    validation_requested BOOLEAN DEFAULT false,
    pitch_deck_url TEXT,
    pitch_video_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for fundraising_details
CREATE INDEX IF NOT EXISTS idx_fundraising_details_startup_id ON fundraising_details(startup_id);
CREATE INDEX IF NOT EXISTS idx_fundraising_details_active ON fundraising_details(active);

-- =====================================================
-- 4. VALUATION HISTORY TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS valuation_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    valuation DECIMAL(15,2) NOT NULL,
    round_type TEXT NOT NULL CHECK (round_type IN ('Pre-Seed', 'Seed', 'Series A', 'Series B', 'Bridge', 'Current')),
    investment_amount DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for valuation_history
CREATE INDEX IF NOT EXISTS idx_valuation_history_startup_id ON valuation_history(startup_id);
CREATE INDEX IF NOT EXISTS idx_valuation_history_date ON valuation_history(date);
CREATE INDEX IF NOT EXISTS idx_valuation_history_round_type ON valuation_history(round_type);

-- =====================================================
-- 5. EQUITY HOLDINGS TABLE (for tracking ownership)
-- =====================================================

CREATE TABLE IF NOT EXISTS equity_holdings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    holder_type TEXT NOT NULL CHECK (holder_type IN ('Founder', 'Investor', 'ESOP', 'Other')),
    holder_name TEXT NOT NULL,
    equity_percentage DECIMAL(5,2) NOT NULL, -- Percentage
    shares_count INTEGER DEFAULT 0,
    total_shares INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for equity_holdings
CREATE INDEX IF NOT EXISTS idx_equity_holdings_startup_id ON equity_holdings(startup_id);
CREATE INDEX IF NOT EXISTS idx_equity_holdings_holder_type ON equity_holdings(holder_type);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Investment Records trigger
CREATE OR REPLACE FUNCTION update_investment_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_investment_records_updated_at ON investment_records;
CREATE TRIGGER update_investment_records_updated_at
    BEFORE UPDATE ON investment_records
    FOR EACH ROW
    EXECUTE FUNCTION update_investment_records_updated_at();

-- Founders trigger
CREATE OR REPLACE FUNCTION update_founders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_founders_updated_at ON founders;
CREATE TRIGGER update_founders_updated_at
    BEFORE UPDATE ON founders
    FOR EACH ROW
    EXECUTE FUNCTION update_founders_updated_at();

-- Fundraising Details trigger
CREATE OR REPLACE FUNCTION update_fundraising_details_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_fundraising_details_updated_at ON fundraising_details;
CREATE TRIGGER update_fundraising_details_updated_at
    BEFORE UPDATE ON fundraising_details
    FOR EACH ROW
    EXECUTE FUNCTION update_fundraising_details_updated_at();

-- Equity Holdings trigger
CREATE OR REPLACE FUNCTION update_equity_holdings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_equity_holdings_updated_at ON equity_holdings;
CREATE TRIGGER update_equity_holdings_updated_at
    BEFORE UPDATE ON equity_holdings
    FOR EACH ROW
    EXECUTE FUNCTION update_equity_holdings_updated_at();

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Investment Records policies
DROP POLICY IF EXISTS "Users can view their own investment records" ON investment_records;
CREATE POLICY "Users can view their own investment records" ON investment_records
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert their own investment records" ON investment_records;
CREATE POLICY "Users can insert their own investment records" ON investment_records
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update their own investment records" ON investment_records;
CREATE POLICY "Users can update their own investment records" ON investment_records
    FOR UPDATE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete their own investment records" ON investment_records;
CREATE POLICY "Users can delete their own investment records" ON investment_records
    FOR DELETE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Founders policies
DROP POLICY IF EXISTS "Users can view their own founders" ON founders;
CREATE POLICY "Users can view their own founders" ON founders
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert their own founders" ON founders;
CREATE POLICY "Users can insert their own founders" ON founders
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update their own founders" ON founders;
CREATE POLICY "Users can update their own founders" ON founders
    FOR UPDATE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete their own founders" ON founders;
CREATE POLICY "Users can delete their own founders" ON founders
    FOR DELETE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Fundraising Details policies
DROP POLICY IF EXISTS "Users can view their own fundraising details" ON fundraising_details;
CREATE POLICY "Users can view their own fundraising details" ON fundraising_details
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert their own fundraising details" ON fundraising_details;
CREATE POLICY "Users can insert their own fundraising details" ON fundraising_details
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update their own fundraising details" ON fundraising_details;
CREATE POLICY "Users can update their own fundraising details" ON fundraising_details
    FOR UPDATE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete their own fundraising details" ON fundraising_details;
CREATE POLICY "Users can delete their own fundraising details" ON fundraising_details
    FOR DELETE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Valuation History policies
DROP POLICY IF EXISTS "Users can view their own valuation history" ON valuation_history;
CREATE POLICY "Users can view their own valuation history" ON valuation_history
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert their own valuation history" ON valuation_history;
CREATE POLICY "Users can insert their own valuation history" ON valuation_history
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update their own valuation history" ON valuation_history;
CREATE POLICY "Users can update their own valuation history" ON valuation_history
    FOR UPDATE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete their own valuation history" ON valuation_history;
CREATE POLICY "Users can delete their own valuation history" ON valuation_history
    FOR DELETE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Equity Holdings policies
DROP POLICY IF EXISTS "Users can view their own equity holdings" ON equity_holdings;
CREATE POLICY "Users can view their own equity holdings" ON equity_holdings
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert their own equity holdings" ON equity_holdings;
CREATE POLICY "Users can insert their own equity holdings" ON equity_holdings
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update their own equity holdings" ON equity_holdings;
CREATE POLICY "Users can update their own equity holdings" ON equity_holdings
    FOR UPDATE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete their own equity holdings" ON equity_holdings;
CREATE POLICY "Users can delete their own equity holdings" ON equity_holdings
    FOR DELETE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Get investment summary for a startup
CREATE OR REPLACE FUNCTION get_investment_summary(p_startup_id INTEGER)
RETURNS TABLE (
    total_equity_funding DECIMAL(15,2),
    total_debt_funding DECIMAL(15,2),
    total_grant_funding DECIMAL(15,2),
    total_investments INTEGER,
    avg_equity_allocated DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(CASE WHEN ir.investment_type = 'Equity' THEN ir.amount ELSE 0 END), 0) as total_equity_funding,
        COALESCE(SUM(CASE WHEN ir.investment_type = 'Debt' THEN ir.amount ELSE 0 END), 0) as total_debt_funding,
        COALESCE(SUM(CASE WHEN ir.investment_type = 'Grant' THEN ir.amount ELSE 0 END), 0) as total_grant_funding,
        COUNT(*)::INTEGER as total_investments,
        COALESCE(AVG(ir.equity_allocated), 0) as avg_equity_allocated
    FROM investment_records ir
    WHERE ir.startup_id = p_startup_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get valuation history for charts
CREATE OR REPLACE FUNCTION get_valuation_history(p_startup_id INTEGER)
RETURNS TABLE (
    round_name TEXT,
    valuation DECIMAL(15,2),
    investment_amount DECIMAL(15,2),
    date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vh.round_type::TEXT as round_name,
        vh.valuation,
        vh.investment_amount,
        vh.date
    FROM valuation_history vh
    WHERE vh.startup_id = p_startup_id
    ORDER BY vh.date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get equity distribution for pie chart
CREATE OR REPLACE FUNCTION get_equity_distribution(p_startup_id INTEGER)
RETURNS TABLE (
    holder_type TEXT,
    equity_percentage DECIMAL(5,2),
    total_amount DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        eh.holder_type::TEXT,
        eh.equity_percentage,
        COALESCE(SUM(ir.amount), 0) as total_amount
    FROM equity_holdings eh
    LEFT JOIN investment_records ir ON ir.startup_id = eh.startup_id 
        AND ir.investor_name = eh.holder_name
    WHERE eh.startup_id = p_startup_id
    GROUP BY eh.holder_type, eh.equity_percentage
    ORDER BY eh.equity_percentage DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get current fundraising status
CREATE OR REPLACE FUNCTION get_fundraising_status(p_startup_id INTEGER)
RETURNS TABLE (
    active BOOLEAN,
    type TEXT,
    value DECIMAL(15,2),
    equity DECIMAL(5,2),
    validation_requested BOOLEAN,
    pitch_deck_url TEXT,
    pitch_video_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fd.active,
        fd.type::TEXT,
        fd.value,
        fd.equity,
        fd.validation_requested,
        fd.pitch_deck_url,
        fd.pitch_video_url
    FROM fundraising_details fd
    WHERE fd.startup_id = p_startup_id
    ORDER BY fd.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Insert sample founders for existing startups
INSERT INTO founders (startup_id, name, email)
SELECT 
    s.id,
    'John Doe',
    'john.doe@startup.com'
FROM startups s
WHERE NOT EXISTS (SELECT 1 FROM founders f WHERE f.startup_id = s.id)
LIMIT 1;

INSERT INTO founders (startup_id, name, email)
SELECT 
    s.id,
    'Jane Smith',
    'jane.smith@startup.com'
FROM startups s
WHERE NOT EXISTS (SELECT 1 FROM founders f WHERE f.startup_id = s.id AND f.email = 'jane.smith@startup.com')
LIMIT 1;

-- Insert sample investment records
INSERT INTO investment_records (startup_id, date, investor_type, investment_type, investor_name, amount, equity_allocated, pre_money_valuation)
SELECT 
    s.id,
    '2023-01-15',
    'VC Firm',
    'Equity',
    'SeedFund Ventures',
    500000,
    10.0,
    4500000
FROM startups s
WHERE NOT EXISTS (SELECT 1 FROM investment_records ir WHERE ir.startup_id = s.id)
LIMIT 1;

-- Insert sample valuation history
INSERT INTO valuation_history (startup_id, date, valuation, round_type, investment_amount)
SELECT 
    s.id,
    '2023-01-15',
    5000000,
    'Seed',
    500000
FROM startups s
WHERE NOT EXISTS (SELECT 1 FROM valuation_history vh WHERE vh.startup_id = s.id)
LIMIT 1;

-- Insert sample equity holdings
INSERT INTO equity_holdings (startup_id, holder_type, holder_name, equity_percentage)
SELECT 
    s.id,
    'Founder',
    'John Doe',
    45.0
FROM startups s
WHERE NOT EXISTS (SELECT 1 FROM equity_holdings eh WHERE eh.startup_id = s.id AND eh.holder_name = 'John Doe')
LIMIT 1;

INSERT INTO equity_holdings (startup_id, holder_type, holder_name, equity_percentage)
SELECT 
    s.id,
    'Founder',
    'Jane Smith',
    45.0
FROM startups s
WHERE NOT EXISTS (SELECT 1 FROM equity_holdings eh WHERE eh.startup_id = s.id AND eh.holder_name = 'Jane Smith')
LIMIT 1;

INSERT INTO equity_holdings (startup_id, holder_type, holder_name, equity_percentage)
SELECT 
    s.id,
    'Investor',
    'SeedFund Ventures',
    10.0
FROM startups s
WHERE NOT EXISTS (SELECT 1 FROM equity_holdings eh WHERE eh.startup_id = s.id AND eh.holder_name = 'SeedFund Ventures')
LIMIT 1;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT 'Cap Table backend setup completed successfully!' as status;
