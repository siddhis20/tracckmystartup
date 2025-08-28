-- TEST_INVESTOR_ACCESS.sql
-- Test if the current user can access fundraising_details data

-- 1. Check current user and role
SELECT 
    auth.uid() as current_user_id,
    auth.jwt() ->> 'email' as current_user_email,
    auth.jwt() ->> 'role' as current_user_role;

-- 2. Test direct access to fundraising_details as current user
SELECT 
    COUNT(*) as can_access_fundraising_details
FROM fundraising_details 
WHERE active = true;

-- 3. Test the exact query that the frontend is using
SELECT 
    fd.id as fundraising_id,
    fd.startup_id,
    fd.active,
    fd.type,
    fd.value,
    fd.equity,
    fd.pitch_deck_url,
    fd.pitch_video_url,
    s.id as startup_id,
    s.name as startup_name,
    s.sector as startup_sector,
    s.compliance_status
FROM fundraising_details fd
INNER JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true
ORDER BY fd.created_at DESC;

-- 4. Check if the user exists in the users table
SELECT 
    id,
    email,
    role,
    investor_code
FROM users 
WHERE email = auth.jwt() ->> 'email';
