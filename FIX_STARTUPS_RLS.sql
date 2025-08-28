-- FIX_STARTUPS_RLS.sql
-- Add RLS policies to allow investors to read startup data for fundraising joins

-- 1. Enable RLS on startups table if not already enabled
ALTER TABLE startups ENABLE ROW LEVEL SECURITY;

-- 2. Create a policy to allow all authenticated users to read startup data
-- This is needed for investors to see startup details in fundraising joins
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'startups' 
        AND policyname = 'startups_read_all'
    ) THEN
        CREATE POLICY startups_read_all ON startups
        FOR SELECT
        TO authenticated
        USING (true);
    END IF;
END $$;

-- 3. Keep existing policies for startup owners to manage their own data
-- (Don't drop existing policies, just add the read policy)

-- 4. Grant necessary permissions to authenticated users
GRANT SELECT ON startups TO authenticated;

-- 5. Verify the policies were created
SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual
FROM pg_policies 
WHERE tablename = 'startups'
ORDER BY policyname;

-- 6. Test that investors can now read startup data
SELECT COUNT(*) as can_read_startups FROM startups;

-- 7. Test the exact join that was failing
SELECT 
    fd.id as fundraising_id,
    fd.startup_id,
    fd.active,
    fd.type,
    fd.value,
    fd.equity,
    s.id as startup_id,
    s.name as startup_name,
    s.sector as startup_sector
FROM fundraising_details fd
LEFT JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true
LIMIT 3;
