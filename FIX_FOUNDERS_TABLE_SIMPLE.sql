-- =====================================================
-- SIMPLE FOUNDERS TABLE FIX
-- =====================================================
-- This script fixes all founders table issues without complex testing

-- Step 1: Add missing columns to founders table
DO $$ 
BEGIN
    -- Add equity_percentage column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'founders' 
        AND column_name = 'equity_percentage'
    ) THEN
        ALTER TABLE public.founders ADD COLUMN equity_percentage DECIMAL(5,2) DEFAULT 0;
        RAISE NOTICE 'Added equity_percentage column to founders table';
    ELSE
        RAISE NOTICE 'equity_percentage column already exists in founders table';
    END IF;

    -- Add shares column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'founders' 
        AND column_name = 'shares'
    ) THEN
        ALTER TABLE public.founders ADD COLUMN shares INTEGER DEFAULT 0;
        RAISE NOTICE 'Added shares column to founders table';
    ELSE
        RAISE NOTICE 'shares column already exists in founders table';
    END IF;

    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'founders' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.founders ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to founders table';
    ELSE
        RAISE NOTICE 'updated_at column already exists in founders table';
    END IF;
END $$;

-- Step 2: Update existing founders with default equity percentages if they don't have any
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

-- Step 3: Fix the trigger function and trigger
-- Drop the existing trigger if it exists
DROP TRIGGER IF EXISTS update_founders_updated_at ON public.founders;

-- Recreate the trigger function
CREATE OR REPLACE FUNCTION update_founders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER update_founders_updated_at
    BEFORE UPDATE ON public.founders
    FOR EACH ROW
    EXECUTE FUNCTION update_founders_updated_at();

-- Step 4: Verify the table structure
SELECT 
    'Founders table structure after fix:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'founders'
ORDER BY ordinal_position;

-- Step 5: Show sample data (if any founders exist)
SELECT 
    'Sample founders data:' as info,
    startup_id,
    name,
    email,
    equity_percentage,
    shares,
    created_at,
    updated_at
FROM public.founders
LIMIT 5;

-- Step 6: Show summary
SELECT 
    'Summary:' as info,
    COUNT(*) as total_founders,
    COUNT(CASE WHEN equity_percentage > 0 THEN 1 END) as founders_with_equity,
    COUNT(CASE WHEN shares > 0 THEN 1 END) as founders_with_shares
FROM public.founders;
