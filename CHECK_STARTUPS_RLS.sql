-- CHECK_STARTUPS_RLS.sql
-- Check RLS policies on startups table that might be preventing joins

-- 1. Check if RLS is enabled on startups table
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'startups';

-- 2. Check existing policies on startups table
SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual
FROM pg_policies 
WHERE tablename = 'startups'
ORDER BY policyname;

-- 3. Test if current user can read from startups table
SELECT 
    COUNT(*) as can_read_startups
FROM startups;

-- 4. Test the exact join that's failing
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

-- 5. Check if the specific startup IDs exist and are accessible
SELECT 
    id,
    name,
    sector,
    compliance_status
FROM startups
WHERE id IN (9, 11, 12, 13, 16)
ORDER BY id;
