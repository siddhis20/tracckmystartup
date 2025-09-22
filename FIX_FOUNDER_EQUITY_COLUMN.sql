-- =====================================================
-- FIX FOUNDER EQUITY COLUMN
-- =====================================================

-- Add equity_percentage column to founders table if it doesn't exist
DO $$ 
BEGIN
    -- Check if equity_percentage column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'founders' 
        AND column_name = 'equity_percentage'
    ) THEN
        -- Add the column
        ALTER TABLE public.founders ADD COLUMN equity_percentage DECIMAL(5,2) DEFAULT 0;
        RAISE NOTICE 'Added equity_percentage column to founders table';
    ELSE
        RAISE NOTICE 'equity_percentage column already exists in founders table';
    END IF;
END $$;

-- Add shares column to founders table if it doesn't exist
DO $$ 
BEGIN
    -- Check if shares column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'founders' 
        AND column_name = 'shares'
    ) THEN
        -- Add the column
        ALTER TABLE public.founders ADD COLUMN shares INTEGER DEFAULT 0;
        RAISE NOTICE 'Added shares column to founders table';
    ELSE
        RAISE NOTICE 'shares column already exists in founders table';
    END IF;
END $$;

-- Update existing founders with default equity percentages if they don't have any
-- This is a sample update - adjust percentages based on your business logic
UPDATE public.founders 
SET equity_percentage = CASE 
    WHEN equity_percentage = 0 OR equity_percentage IS NULL THEN
        -- Distribute equity equally among founders for the same startup
        (100.0 / (
            SELECT COUNT(*) 
            FROM public.founders f2 
            WHERE f2.startup_id = founders.startup_id
        ))
    ELSE equity_percentage
END
WHERE equity_percentage = 0 OR equity_percentage IS NULL;

-- Verify the changes
SELECT 
    'Founders table structure:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'founders'
ORDER BY ordinal_position;

-- Show sample data
SELECT 
    'Sample founders data:' as info,
    startup_id,
    name,
    email,
    equity_percentage,
    shares
FROM public.founders
LIMIT 5;
