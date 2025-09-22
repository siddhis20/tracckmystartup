-- =====================================================
-- FIX STARTUP NAME MISMATCH ISSUE
-- =====================================================
-- This script fixes the mismatch between startup names and user startup_name fields

-- Step 1: Show the current mismatches
SELECT '=== CURRENT MISMATCHES ===' as step;
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    s.user_id,
    u.email as user_email,
    u.startup_name as user_startup_name,
    'MISMATCH' as status
FROM startups s
JOIN users u ON s.user_id = u.id
WHERE s.name != u.startup_name;

-- Step 2: Fix the mismatches by updating user startup_name to match startup name
-- This ensures the user's startup_name field matches the actual startup name
UPDATE users 
SET startup_name = (
    SELECT s.name 
    FROM startups s 
    WHERE s.user_id = users.id 
    LIMIT 1
)
WHERE role = 'Startup' 
AND id IN (
    SELECT s.user_id 
    FROM startups s 
    JOIN users u ON s.user_id = u.id 
    WHERE s.name != u.startup_name
);

-- Step 3: Verify the fix
SELECT '=== AFTER FIX ===' as step;
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    s.user_id,
    u.email as user_email,
    u.startup_name as user_startup_name,
    CASE 
        WHEN s.name = u.startup_name THEN 'MATCHED'
        ELSE 'MISMATCH'
    END as relationship_status
FROM startups s
LEFT JOIN users u ON s.user_id = u.id
ORDER BY s.created_at DESC;

-- Step 4: Check for any remaining mismatches
SELECT '=== REMAINING MISMATCHES ===' as step;
SELECT COUNT(*) as remaining_mismatches
FROM startups s
JOIN users u ON s.user_id = u.id
WHERE s.name != u.startup_name;
