-- =====================================================
-- FIX FOUNDERS UPDATED_AT COLUMN ERROR
-- =====================================================

-- Add updated_at column to founders table if it doesn't exist
DO $$ 
BEGIN
    -- Check if updated_at column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'founders' 
        AND column_name = 'updated_at'
    ) THEN
        -- Add the column
        ALTER TABLE public.founders ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to founders table';
    ELSE
        RAISE NOTICE 'updated_at column already exists in founders table';
    END IF;
END $$;

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

-- Verify the table structure
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

-- Show sample data
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
