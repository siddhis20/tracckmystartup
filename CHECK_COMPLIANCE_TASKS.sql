-- =====================================================
-- CHECK COMPLIANCE TASKS GENERATION
-- =====================================================
-- This script checks if compliance tasks are being generated properly
-- =====================================================

-- Step 1: Check if compliance_checks table exists and has data
-- =====================================================

SELECT 
    'compliance_table_check' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'compliance_checks') 
        THEN '✅ compliance_checks table exists'
        ELSE '❌ compliance_checks table missing'
    END as status;

-- Step 2: Check compliance_checks table structure
-- =====================================================

SELECT 
    'compliance_table_structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'compliance_checks' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 3: Check if there are any compliance tasks in the database
-- =====================================================

SELECT 
    'compliance_tasks_count' as check_type,
    COUNT(*) as total_tasks,
    COUNT(DISTINCT startup_id) as startups_with_tasks
FROM public.compliance_checks;

-- Step 4: Show sample compliance tasks
-- =====================================================

SELECT 
    'sample_compliance_tasks' as check_type,
    id,
    startup_id,
    task_id,
    entity_identifier,
    entity_display_name,
    year,
    task_name,
    ca_required,
    cs_required,
    ca_status,
    cs_status,
    created_at
FROM public.compliance_checks 
ORDER BY startup_id, year DESC, task_name
LIMIT 10;

-- Step 5: Check if the trigger function exists
-- =====================================================

SELECT 
    'trigger_function_check' as check_type,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name = 'create_compliance_tasks'
AND routine_schema = 'public';

-- Step 6: Check if the trigger exists
-- =====================================================

SELECT 
    'trigger_check' as check_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_create_compliance_tasks'
AND trigger_schema = 'public';

-- Step 7: Check sample startup data to see if it has the required fields
-- =====================================================

SELECT 
    'sample_startup_data' as check_type,
    id,
    name,
    country_of_registration,
    company_type,
    registration_date,
    user_id,
    updated_at
FROM public.startups 
ORDER BY id 
LIMIT 5;

-- Step 8: Test the compliance function manually
-- =====================================================

DO $$
DECLARE
    startup_id_val INTEGER;
    test_result BOOLEAN;
    tasks_count INTEGER;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM public.startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing compliance task generation for startup ID: %', startup_id_val;
        
        -- Count existing tasks
        SELECT COUNT(*) INTO tasks_count FROM public.compliance_checks WHERE startup_id = startup_id_val;
        RAISE NOTICE 'Existing compliance tasks for startup %: %', startup_id_val, tasks_count;
        
        -- Test the function by updating a startup
        UPDATE public.startups 
        SET 
            country_of_registration = 'Test Compliance Country',
            company_type = 'Test Compliance Type',
            updated_at = NOW()
        WHERE id = startup_id_val;
        
        -- Count tasks after update
        SELECT COUNT(*) INTO tasks_count FROM public.compliance_checks WHERE startup_id = startup_id_val;
        RAISE NOTICE 'Compliance tasks after update for startup %: %', startup_id_val, tasks_count;
        
        IF tasks_count > 0 THEN
            RAISE NOTICE '✅ Compliance tasks are being generated!';
        ELSE
            RAISE NOTICE '❌ No compliance tasks were generated';
        END IF;
        
    ELSE
        RAISE NOTICE 'No startups found for testing';
    END IF;
END $$;

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'COMPLIANCE TASKS DIAGNOSTIC COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Check the results above to see if:';
    RAISE NOTICE '- Compliance table exists and has data';
    RAISE NOTICE '- Trigger function exists';
    RAISE NOTICE '- Tasks are being generated on profile updates';
    RAISE NOTICE '========================================';
END $$;


