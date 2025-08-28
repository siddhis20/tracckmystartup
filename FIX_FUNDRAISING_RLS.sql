-- FIX_FUNDRAISING_RLS.sql
-- Add RLS policies for fundraising_details table to allow investors to read data

-- 1. Enable RLS on fundraising_details table if not already enabled
ALTER TABLE fundraising_details ENABLE ROW LEVEL SECURITY;

-- 2. Create a policy to allow all authenticated users to read fundraising_details
-- This is needed for investors to see all active fundraising opportunities
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'fundraising_details' 
        AND policyname = 'fundraising_details_read_all'
    ) THEN
        CREATE POLICY fundraising_details_read_all ON fundraising_details
        FOR SELECT
        TO authenticated
        USING (true);
    END IF;
END $$;

-- 3. Create a policy to allow startup owners to manage their own fundraising details
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'fundraising_details' 
        AND policyname = 'fundraising_details_owner_manage'
    ) THEN
        CREATE POLICY fundraising_details_owner_manage ON fundraising_details
        FOR ALL
        TO authenticated
        USING (
            startup_id IN (
                SELECT id FROM startups 
                WHERE id = fundraising_details.startup_id
            )
        );
    END IF;
END $$;

-- 4. Grant necessary permissions to authenticated users
GRANT SELECT ON fundraising_details TO authenticated;
GRANT SELECT ON startups TO authenticated;

-- 5. Verify the policies were created
SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual
FROM pg_policies 
WHERE tablename = 'fundraising_details'
ORDER BY policyname;

