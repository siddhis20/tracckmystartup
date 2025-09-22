-- =====================================================
-- ADD SHARES COLUMNS TO INVESTMENT RECORDS
-- =====================================================

-- Add shares column to investment_records table if it doesn't exist
DO $$ 
BEGIN
    -- Check if shares column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'investment_records' 
        AND column_name = 'shares'
    ) THEN
        -- Add the column
        ALTER TABLE public.investment_records ADD COLUMN shares INTEGER DEFAULT 0;
        RAISE NOTICE 'Added shares column to investment_records table';
    ELSE
        RAISE NOTICE 'shares column already exists in investment_records table';
    END IF;
END $$;

-- Add price_per_share column to investment_records table if it doesn't exist
DO $$ 
BEGIN
    -- Check if price_per_share column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'investment_records' 
        AND column_name = 'price_per_share'
    ) THEN
        -- Add the column
        ALTER TABLE public.investment_records ADD COLUMN price_per_share DECIMAL(15,4) DEFAULT 0;
        RAISE NOTICE 'Added price_per_share column to investment_records table';
    ELSE
        RAISE NOTICE 'price_per_share column already exists in investment_records table';
    END IF;
END $$;

-- Verify the changes
SELECT 
    'investment_records table structure:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'investment_records'
ORDER BY ordinal_position;


