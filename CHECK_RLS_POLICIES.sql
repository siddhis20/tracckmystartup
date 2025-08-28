-- CHECK_RLS_POLICIES.sql
-- Check RLS policies on fundraising_details table

-- 1. Check if RLS is enabled on fundraising_details table
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'fundraising_details';

-- 2. Check existing policies on fundraising_details table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'fundraising_details';

-- 3. Check if the current user can read from fundraising_details
SELECT 
    has_table_privilege(current_user, 'fundraising_details', 'SELECT') as can_select,
    has_table_privilege(current_user, 'fundraising_details', 'INSERT') as can_insert,
    has_table_privilege(current_user, 'fundraising_details', 'UPDATE') as can_update,
    has_table_privilege(current_user, 'fundraising_details', 'DELETE') as can_delete;

-- 4. Check if the anon role can read from fundraising_details
SELECT 
    has_table_privilege('anon', 'fundraising_details', 'SELECT') as anon_can_select,
    has_table_privilege('authenticated', 'fundraising_details', 'SELECT') as auth_can_select;

-- 5. Test a simple query as the current user
SELECT COUNT(*) as total_records FROM fundraising_details WHERE active = true;

-- 6. Check if the table exists and has data
SELECT 
    EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'fundraising_details'
    ) as table_exists;

-- 7. If table exists, show sample data
SELECT 
    id,
    startup_id,
    active,
    type,
    value,
    equity,
    pitch_deck_url,
    pitch_video_url
FROM fundraising_details 
WHERE active = true 
LIMIT 3;

