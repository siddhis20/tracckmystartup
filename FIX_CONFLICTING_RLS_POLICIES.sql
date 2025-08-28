-- FIX_CONFLICTING_RLS_POLICIES.sql
-- Remove conflicting RLS policies that prevent investors from seeing all fundraising details

-- Drop the restrictive policies that only allow users to see their own fundraising details
-- These policies conflict with the fundraising_details_read_all policy

-- 1. Drop the policy that restricts users to their own fundraising details
DROP POLICY IF EXISTS "Startup users can manage their own fundraising details" ON fundraising_details;

-- 2. Drop the policy that restricts users to their own fundraising details for DELETE
DROP POLICY IF EXISTS "Users can delete their own fundraising details" ON fundraising_details;

-- 3. Drop the policy that allows INSERT without restrictions (this one is fine, but let's be consistent)
DROP POLICY IF EXISTS "Users can insert their own fundraising details" ON fundraising_details;

-- 4. Drop the policy that restricts users to their own fundraising details for UPDATE
DROP POLICY IF EXISTS "Users can update their own fundraising details" ON fundraising_details;

-- 5. Drop the policy that restricts users to their own fundraising details for SELECT
DROP POLICY IF EXISTS "Users can view their own fundraising details" ON fundraising_details;

-- 6. Drop the policy that restricts users to their own startup's fundraising details for SELECT
DROP POLICY IF EXISTS "Users can view their own startup's fundraising details" ON fundraising_details;

-- 7. Keep the fundraising_details_owner_manage policy (this one is good for startup owners)
-- Keep the fundraising_details_read_all policy (this one allows investors to see all)

-- 8. Add a new INSERT policy for authenticated users
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'fundraising_details' 
        AND policyname = 'fundraising_details_insert_authenticated'
    ) THEN
        CREATE POLICY fundraising_details_insert_authenticated ON fundraising_details
        FOR INSERT
        TO authenticated
        WITH CHECK (true);
    END IF;
END $$;

-- 9. Verify the remaining policies
SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual
FROM pg_policies 
WHERE tablename = 'fundraising_details'
ORDER BY policyname;

-- 10. Test that investors can now read all fundraising details
-- This should return all active fundraising records
SELECT COUNT(*) as total_active_fundraising FROM fundraising_details WHERE active = true;
