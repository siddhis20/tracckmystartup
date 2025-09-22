-- =====================================================
-- COMPLETE DATABASE FIX SCRIPT
-- =====================================================
-- This script ensures all tables have the correct structure for the application

-- =====================================================
-- 1. FIX INVESTMENT RECORDS TABLE
-- =====================================================

-- Add missing columns to investment_records
DO $$ 
BEGIN
    -- pre_money_valuation
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'investment_records' AND column_name = 'pre_money_valuation'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN pre_money_valuation DECIMAL(15,2);
        RAISE NOTICE 'Added pre_money_valuation column to investment_records table';
    END IF;
    
    -- post_money_valuation
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'investment_records' AND column_name = 'post_money_valuation'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN post_money_valuation DECIMAL(15,2);
        RAISE NOTICE 'Added post_money_valuation column to investment_records table';
    END IF;
    
    -- shares
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'investment_records' AND column_name = 'shares'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN shares INTEGER DEFAULT 0;
        RAISE NOTICE 'Added shares column to investment_records table';
    END IF;
    
    -- price_per_share
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'investment_records' AND column_name = 'price_per_share'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN price_per_share DECIMAL(15,4) DEFAULT 0;
        RAISE NOTICE 'Added price_per_share column to investment_records table';
    END IF;
    
    -- proof_url
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'investment_records' AND column_name = 'proof_url'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN proof_url TEXT;
        RAISE NOTICE 'Added proof_url column to investment_records table';
    END IF;
    
    -- investor_code
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'investment_records' AND column_name = 'investor_code'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN investor_code TEXT;
        RAISE NOTICE 'Added investor_code column to investment_records table';
    END IF;
    
    -- created_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'investment_records' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added created_at column to investment_records table';
    END IF;
    
    -- updated_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'investment_records' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to investment_records table';
    END IF;
END $$;

-- =====================================================
-- 2. FIX FOUNDERS TABLE
-- =====================================================

DO $$ 
BEGIN
    -- equity_percentage
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'founders' AND column_name = 'equity_percentage'
    ) THEN
        ALTER TABLE public.founders ADD COLUMN equity_percentage DECIMAL(5,2) DEFAULT 0;
        RAISE NOTICE 'Added equity_percentage column to founders table';
    END IF;
    
    -- shares
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'founders' AND column_name = 'shares'
    ) THEN
        ALTER TABLE public.founders ADD COLUMN shares INTEGER DEFAULT 0;
        RAISE NOTICE 'Added shares column to founders table';
    END IF;
    
    -- updated_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'founders' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.founders ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to founders table';
    END IF;
END $$;

-- =====================================================
-- 3. FIX STARTUP SHARES TABLE
-- =====================================================

-- Create startup_shares table if it doesn't exist
CREATE TABLE IF NOT EXISTS startup_shares (
    startup_id INTEGER PRIMARY KEY REFERENCES startups(id) ON DELETE CASCADE,
    total_shares NUMERIC NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $$ 
BEGIN
    -- price_per_share
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'startup_shares' AND column_name = 'price_per_share'
    ) THEN
        ALTER TABLE public.startup_shares ADD COLUMN price_per_share NUMERIC NOT NULL DEFAULT 0;
        RAISE NOTICE 'Added price_per_share column to startup_shares table';
    END IF;
    
    -- esop_reserved_shares
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'startup_shares' AND column_name = 'esop_reserved_shares'
    ) THEN
        ALTER TABLE public.startup_shares ADD COLUMN esop_reserved_shares NUMERIC NOT NULL DEFAULT 0;
        RAISE NOTICE 'Added esop_reserved_shares column to startup_shares table';
    END IF;
END $$;

-- =====================================================
-- 4. FIX STARTUP PROFILES TABLE
-- =====================================================

-- Create startup_profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS startup_profiles (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    country TEXT,
    company_type TEXT,
    registration_date DATE,
    ca_service_code TEXT,
    cs_service_code TEXT,
    currency TEXT DEFAULT 'USD',
    total_shares NUMERIC DEFAULT 0,
    price_per_share NUMERIC DEFAULT 0,
    esop_reserved_shares NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 5. CREATE TRIGGERS
-- =====================================================

-- Investment records trigger
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

-- =====================================================
-- 6. ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE IF EXISTS investment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS founders ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS startup_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS startup_profiles ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 7. VERIFICATION
-- =====================================================

-- Show final table structures
SELECT 'Investment records table structure:' as info, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'investment_records'
ORDER BY ordinal_position;

SELECT 'Founders table structure:' as info, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'founders'
ORDER BY ordinal_position;

SELECT 'Startup shares table structure:' as info, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'startup_shares'
ORDER BY ordinal_position;

SELECT 'Startup profiles table structure:' as info, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'startup_profiles'
ORDER BY ordinal_position;


