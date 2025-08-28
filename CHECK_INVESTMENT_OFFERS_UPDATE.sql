-- CHECK_INVESTMENT_OFFERS_UPDATE.sql
-- Check and fix issues with investment_offers table updates

-- 1. Check table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'investment_offers'
ORDER BY ordinal_position;

-- 2. Check RLS policies on investment_offers table
SELECT 
    policyname,
    cmd AS command,
    roles,
    qual AS "using",
    with_check
FROM pg_policies 
WHERE tablename = 'investment_offers';

-- 3. Check if there are any existing offers
SELECT COUNT(*) as total_offers FROM investment_offers;

-- 4. Check a sample offer
SELECT * FROM investment_offers LIMIT 1;

-- 5. Test update operation (if there are offers)
-- Uncomment the following lines if you want to test an update
-- UPDATE investment_offers 
-- SET offer_amount = offer_amount 
-- WHERE id = (SELECT id FROM investment_offers LIMIT 1);

-- 6. Add UPDATE policy if missing
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'investment_offers' 
        AND cmd = 'UPDATE'
    ) THEN
        CREATE POLICY investment_offers_update_owner ON investment_offers
        FOR UPDATE TO authenticated
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;

-- 7. Grant UPDATE permissions if needed
GRANT UPDATE ON investment_offers TO authenticated;

-- 8. Verify the fix
SELECT 
    policyname,
    cmd AS command
FROM pg_policies 
WHERE tablename = 'investment_offers' 
AND cmd = 'UPDATE';
