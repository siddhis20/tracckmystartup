-- =====================================================
-- ADD INVESTMENT ADVISOR CODE ENTERED COLUMN
-- =====================================================

-- 1. Check if the column already exists
SELECT 
  'Checking if column exists' as info,
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'public'
  AND column_name = 'investment_advisor_code_entered';

-- 2. Add the column if it doesn't exist
DO $$
BEGIN
    -- Check if the column exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND table_schema = 'public' 
        AND column_name = 'investment_advisor_code_entered'
    ) THEN
        -- Add the column
        ALTER TABLE public.users 
        ADD COLUMN investment_advisor_code_entered TEXT;
        
        RAISE NOTICE 'Column investment_advisor_code_entered added successfully';
    ELSE
        RAISE NOTICE 'Column investment_advisor_code_entered already exists';
    END IF;
END $$;

-- 3. Verify the column was added
SELECT 
  'Verification' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'public'
  AND column_name = 'investment_advisor_code_entered';

-- 4. Test inserting a value
SELECT 
  'Test Complete' as info,
  'Column investment_advisor_code_entered is ready for use' as message;
