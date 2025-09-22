-- =====================================================
-- FIX INVESTMENT RECORDS MISSING COLUMNS
-- =====================================================
-- This script adds missing columns to the investment_records table

-- Step 1: Add pre_money_valuation column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'investment_records' 
        AND column_name = 'pre_money_valuation'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN pre_money_valuation DECIMAL(15,2);
        RAISE NOTICE 'Added pre_money_valuation column to investment_records table';
    ELSE
        RAISE NOTICE 'pre_money_valuation column already exists in investment_records table';
    END IF;
END $$;

-- Step 2: Add post_money_valuation column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'investment_records' 
        AND column_name = 'post_money_valuation'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN post_money_valuation DECIMAL(15,2);
        RAISE NOTICE 'Added post_money_valuation column to investment_records table';
    ELSE
        RAISE NOTICE 'post_money_valuation column already exists in investment_records table';
    END IF;
END $$;

-- Step 3: Add shares column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'investment_records' 
        AND column_name = 'shares'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN shares INTEGER DEFAULT 0;
        RAISE NOTICE 'Added shares column to investment_records table';
    ELSE
        RAISE NOTICE 'shares column already exists in investment_records table';
    END IF;
END $$;

-- Step 4: Add price_per_share column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'investment_records' 
        AND column_name = 'price_per_share'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN price_per_share DECIMAL(15,4) DEFAULT 0;
        RAISE NOTICE 'Added price_per_share column to investment_records table';
    ELSE
        RAISE NOTICE 'price_per_share column already exists in investment_records table';
    END IF;
END $$;

-- Step 5: Add proof_url column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'investment_records' 
        AND column_name = 'proof_url'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN proof_url TEXT;
        RAISE NOTICE 'Added proof_url column to investment_records table';
    ELSE
        RAISE NOTICE 'proof_url column already exists in investment_records table';
    END IF;
END $$;

-- Step 6: Add investor_code column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'investment_records' 
        AND column_name = 'investor_code'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN investor_code TEXT;
        RAISE NOTICE 'Added investor_code column to investment_records table';
    ELSE
        RAISE NOTICE 'investor_code column already exists in investment_records table';
    END IF;
END $$;

-- Step 7: Add created_at and updated_at columns if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'investment_records' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added created_at column to investment_records table';
    ELSE
        RAISE NOTICE 'created_at column already exists in investment_records table';
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'investment_records' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.investment_records ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to investment_records table';
    ELSE
        RAISE NOTICE 'updated_at column already exists in investment_records table';
    END IF;
END $$;

-- Step 8: Verify the table structure
SELECT 
    'Investment records table structure after fix:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'investment_records'
ORDER BY ordinal_position;

-- Step 9: Test the table by showing sample data (if any exists)
SELECT 
    'Sample investment records data:' as info,
    id,
    startup_id,
    date,
    investor_type,
    investment_type,
    investor_name,
    amount,
    equity_allocated,
    pre_money_valuation,
    post_money_valuation,
    shares,
    price_per_share,
    created_at
FROM public.investment_records
LIMIT 5;


