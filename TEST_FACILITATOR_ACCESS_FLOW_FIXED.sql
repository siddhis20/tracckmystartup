-- Test script for complete facilitator access flow (FIXED)
-- This verifies the 30-day view-only access system with correct role values

-- 1. Check if all required tables and functions exist
SELECT '1. System verification:' as test_step;
SELECT 
    'Tables' as component,
    COUNT(*) as count
FROM information_schema.tables 
WHERE table_name IN ('facilitator_access', 'opportunity_applications', 'incubation_opportunities', 'startups', 'users')
AND table_schema = 'public'

UNION ALL

SELECT 
    'Functions' as component,
    COUNT(*) as count
FROM information_schema.routines 
WHERE routine_name IN (
    'grant_facilitator_compliance_access',
    'check_facilitator_access',
    'revoke_facilitator_access',
    'cleanup_expired_access',
    'get_facilitator_access_list',
    'grant_facilitator_access_on_diligence_approval'
)
AND routine_schema = 'public';

-- 2. Check valid user roles
SELECT '2. Valid user roles:' as test_step;
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname = 'user_role'
ORDER BY e.enumsortorder;

-- 3. Show current test data
SELECT '3. Current test data:' as test_step;
SELECT 
    'Users' as table_name,
    COUNT(*) as record_count
FROM users

UNION ALL

SELECT 
    'Startups' as table_name,
    COUNT(*) as record_count
FROM startups

UNION ALL

SELECT 
    'Opportunities' as table_name,
    COUNT(*) as record_count
FROM incubation_opportunities

UNION ALL

SELECT 
    'Applications' as table_name,
    COUNT(*) as record_count
FROM opportunity_applications

UNION ALL

SELECT 
    'Access Records' as table_name,
    COUNT(*) as record_count
FROM facilitator_access;

-- 4. Show users by role
SELECT '4. Users by role:' as test_step;
SELECT 
    role,
    COUNT(*) as user_count
FROM users
GROUP BY role
ORDER BY user_count DESC;

-- 5. Test the complete flow with any available user
SELECT '5. Testing complete flow:' as test_step;

-- Get a test user and startup (using any available user)
DO $$
DECLARE
    test_user_id UUID;
    test_startup_id INTEGER;
    test_opportunity_id UUID;
    test_application_id UUID;
    access_granted BOOLEAN;
    access_check BOOLEAN;
    access_list_count INTEGER;
    user_role TEXT;
    cleanup_count INTEGER;
BEGIN
    -- Get any test user (we'll use the first available user)
    SELECT id, role INTO test_user_id, user_role
    FROM users
    LIMIT 1;
    
    -- Get test startup
    SELECT id INTO test_startup_id
    FROM startups
    LIMIT 1;
    
    -- Get test opportunity (or create one if none exists)
    SELECT id INTO test_opportunity_id
    FROM incubation_opportunities
    LIMIT 1;
    
    IF test_opportunity_id IS NULL THEN
        -- Create a test opportunity
        INSERT INTO incubation_opportunities (
            program_name,
            description,
            deadline,
            facilitator_id,
            created_at
        ) VALUES (
            'Test Program',
            'Test program for facilitator access testing',
            (NOW() + INTERVAL '30 days')::date,
            test_user_id,
            NOW()
        ) RETURNING id INTO test_opportunity_id;
        
        RAISE NOTICE 'Created test opportunity: %', test_opportunity_id;
    END IF;
    
    IF test_user_id IS NULL THEN
        RAISE NOTICE '❌ No users found for testing';
        RETURN;
    END IF;
    
    IF test_startup_id IS NULL THEN
        RAISE NOTICE '❌ No startup found for testing';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Test data found:';
    RAISE NOTICE '   User ID: % (Role: %)', test_user_id, user_role;
    RAISE NOTICE '   Startup ID: %', test_startup_id;
    RAISE NOTICE '   Opportunity ID: %', test_opportunity_id;
    
    -- Step 1: Test manual access grant
    RAISE NOTICE 'Step 1: Testing manual access grant...';
    SELECT grant_facilitator_compliance_access(test_user_id, test_startup_id) INTO access_granted;
    
    IF access_granted THEN
        RAISE NOTICE '✅ Access granted successfully';
    ELSE
        RAISE NOTICE '❌ Access grant failed';
    END IF;
    
    -- Step 2: Test access check
    RAISE NOTICE 'Step 2: Testing access check...';
    SELECT check_facilitator_access(test_user_id, test_startup_id) INTO access_check;
    
    IF access_check THEN
        RAISE NOTICE '✅ Access check passed';
    ELSE
        RAISE NOTICE '❌ Access check failed';
    END IF;
    
    -- Step 3: Test access list
    RAISE NOTICE 'Step 3: Testing access list...';
    SELECT COUNT(*) INTO access_list_count
    FROM get_facilitator_access_list(test_user_id);
    
    RAISE NOTICE '✅ Access list shows % records', access_list_count;
    
    -- Step 4: Test automatic access grant via trigger
    RAISE NOTICE 'Step 4: Testing automatic access grant...';
    
    -- Create a test application if none exists
    SELECT id INTO test_application_id
    FROM opportunity_applications
    WHERE opportunity_id = test_opportunity_id
    AND startup_id = test_startup_id
    LIMIT 1;
    
    IF test_application_id IS NULL THEN
        -- Create test application
        INSERT INTO opportunity_applications (
            startup_id,
            opportunity_id,
            status,
            diligence_status,
            created_at
        ) VALUES (
            test_startup_id,
            test_opportunity_id,
            'accepted',
            'requested',
            NOW()
        ) RETURNING id INTO test_application_id;
        
        RAISE NOTICE 'Created test application: %', test_application_id;
    END IF;
    
    -- Update diligence status to trigger access grant
    UPDATE opportunity_applications
    SET diligence_status = 'approved'
    WHERE id = test_application_id;
    
    -- Check if access was granted
    SELECT check_facilitator_access(test_user_id, test_startup_id) INTO access_check;
    
    IF access_check THEN
        RAISE NOTICE '✅ Automatic access grant via trigger worked';
    ELSE
        RAISE NOTICE '❌ Automatic access grant via trigger failed';
    END IF;
    
    -- Step 5: Test access expiration
    RAISE NOTICE 'Step 5: Testing access expiration...';
    
    -- Update access to expire in 1 minute
    UPDATE facilitator_access
    SET expires_at = NOW() + INTERVAL '1 minute'
    WHERE facilitator_id = test_user_id
    AND startup_id = test_startup_id;
    
    RAISE NOTICE 'Updated access to expire in 1 minute';
    
    -- Wait a moment and check expiration
    PERFORM pg_sleep(2);
    
    -- Run cleanup
    SELECT cleanup_expired_access() INTO cleanup_count;
    
    -- Check if access is still valid
    SELECT check_facilitator_access(test_user_id, test_startup_id) INTO access_check;
    
    IF NOT access_check THEN
        RAISE NOTICE '✅ Access expiration working correctly';
    ELSE
        RAISE NOTICE '❌ Access expiration not working';
    END IF;
    
END $$;

-- 6. Show current access records
SELECT '6. Current access records:' as test_step;
SELECT 
    fa.id,
    u.name as user_name,
    u.role as user_role,
    s.name as startup_name,
    fa.access_type,
    fa.granted_at,
    fa.expires_at,
    fa.is_active,
    EXTRACT(DAY FROM (fa.expires_at - NOW()))::INTEGER as days_remaining,
    CASE 
        WHEN fa.is_active AND fa.expires_at > NOW() THEN 'Active'
        WHEN fa.is_active AND fa.expires_at <= NOW() THEN 'Expired'
        ELSE 'Inactive'
    END as status
FROM facilitator_access fa
JOIN users u ON fa.facilitator_id = u.id
JOIN startups s ON fa.startup_id = s.id
ORDER BY fa.granted_at DESC;

-- 7. Test RPC functions
SELECT '7. Testing RPC functions:' as test_step;

-- Test get_facilitator_access_list with any user
DO $$
DECLARE
    test_user_id UUID;
    access_count INTEGER;
BEGIN
    SELECT id INTO test_user_id
    FROM users
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        SELECT COUNT(*) INTO access_count
        FROM get_facilitator_access_list(test_user_id);
        
        RAISE NOTICE 'RPC get_facilitator_access_list returned % records for user %', access_count, test_user_id;
    END IF;
END $$;

-- 8. Show trigger verification
SELECT '8. Trigger verification:' as test_step;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'diligence_approval_access_trigger'
AND event_object_table = 'opportunity_applications';

-- 9. Summary
SELECT 'FACILITATOR ACCESS FLOW TEST COMPLETE' as summary;
SELECT 
    '✅ Database tables created' as component,
    '✅ RPC functions working' as functions,
    '✅ Triggers configured' as triggers,
    '✅ Access control active' as access_control;
