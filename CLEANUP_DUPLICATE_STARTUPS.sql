-- CLEANUP_DUPLICATE_STARTUPS.sql
-- Clean up duplicate startups created by the old acceptStartupRequest logic

-- 1. Check for duplicate startups by name
SELECT '=== CHECKING FOR DUPLICATE STARTUPS ===' as info;

SELECT 
    name,
    COUNT(*) as count,
    STRING_AGG(id::text, ', ') as startup_ids,
    STRING_AGG(user_id::text, ', ') as user_ids,
    STRING_AGG(created_at::text, ', ') as created_dates
FROM startups 
GROUP BY name 
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- 2. Show details of duplicate startups
SELECT '=== DETAILS OF DUPLICATE STARTUPS ===' as info;

WITH duplicates AS (
    SELECT name, COUNT(*) as count
    FROM startups 
    GROUP BY name 
    HAVING COUNT(*) > 1
)
SELECT 
    s.id,
    s.name,
    s.user_id,
    s.investment_type,
    s.investment_value,
    s.total_funding,
    s.compliance_status,
    s.created_at,
    u.email as owner_email,
    u.role as owner_role
FROM startups s
JOIN duplicates d ON s.name = d.name
JOIN users u ON s.user_id = u.id
ORDER BY s.name, s.created_at;

-- 3. Clean up duplicates (keep the oldest one, delete newer ones)
SELECT '=== CLEANING UP DUPLICATES ===' as info;

-- Create a temporary table to identify which startups to keep
CREATE TEMP TABLE startups_to_keep AS
SELECT DISTINCT ON (name) 
    id,
    name,
    user_id,
    created_at
FROM startups 
ORDER BY name, created_at ASC;

-- Show which startups will be kept
SELECT '=== STARTUPS TO KEEP ===' as info;
SELECT * FROM startups_to_keep ORDER BY name;

-- Show which startups will be deleted
SELECT '=== STARTUPS TO DELETE ===' as info;
SELECT 
    s.id,
    s.name,
    s.user_id,
    s.created_at
FROM startups s
WHERE NOT EXISTS (
    SELECT 1 FROM startups_to_keep stk 
    WHERE stk.id = s.id
)
ORDER BY s.name, s.created_at;

-- 4. Delete duplicate startups (uncomment to actually delete)
-- DELETE FROM startups 
-- WHERE NOT EXISTS (
--     SELECT 1 FROM startups_to_keep stk 
--     WHERE stk.id = startups.id
-- );

-- 5. Verify cleanup
SELECT '=== VERIFICATION AFTER CLEANUP ===' as info;

SELECT 
    name,
    COUNT(*) as count
FROM startups 
GROUP BY name 
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- 6. Show final startup list
SELECT '=== FINAL STARTUP LIST ===' as info;
SELECT 
    id,
    name,
    user_id,
    investment_type,
    total_funding,
    compliance_status,
    created_at
FROM startups 
ORDER BY name, created_at;
