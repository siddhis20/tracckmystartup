-- =====================================================
-- GENERATE COMPLIANCE TASKS FOR ALL EXISTING PROFILES
-- =====================================================
-- This script generates compliance tasks for ALL existing profiles
-- so they appear immediately without needing to edit the profile
-- =====================================================

-- Step 1: Check what profiles exist
-- =====================================================

SELECT 
    'profile_check' as check_type,
    id,
    name,
    country_of_registration,
    company_type,
    registration_date,
    (SELECT COUNT(*) FROM public.compliance_checks WHERE startup_id = s.id) as existing_tasks
FROM public.startups s
WHERE country_of_registration IS NOT NULL 
AND company_type IS NOT NULL 
AND registration_date IS NOT NULL
ORDER BY id;

-- Step 2: Clear existing compliance tasks (to regenerate them properly)
-- =====================================================

DELETE FROM public.compliance_checks;

-- Step 3: Generate compliance tasks for ALL existing profiles
-- =====================================================

DO $$
DECLARE
    startup_record RECORD;
    current_year INTEGER;
    registration_year INTEGER;
    compliance_task_id TEXT;
    entity_identifier TEXT;
    entity_display_name TEXT;
    tasks_created INTEGER := 0;
    total_tasks INTEGER := 0;
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW());
    
    RAISE NOTICE 'Starting compliance task generation for all existing profiles...';
    
    -- Loop through all startups with complete profile data
    FOR startup_record IN 
        SELECT id, name, country_of_registration, company_type, registration_date
        FROM public.startups 
        WHERE country_of_registration IS NOT NULL 
        AND company_type IS NOT NULL 
        AND registration_date IS NOT NULL
        ORDER BY id
    LOOP
        RAISE NOTICE 'Processing startup ID: %, Name: %, Country: %, Type: %, Registration: %', 
            startup_record.id, 
            startup_record.name, 
            startup_record.country_of_registration, 
            startup_record.company_type, 
            startup_record.registration_date;
        
        -- Get registration year
        registration_year := EXTRACT(YEAR FROM startup_record.registration_date::date);
        
        -- Create tasks for parent company
        entity_identifier := 'parent';
        entity_display_name := 'Parent Company (' || COALESCE(startup_record.country_of_registration, 'Unknown') || ')';
        
        -- Create annual tasks for each year from registration to current
        FOR year IN registration_year..current_year LOOP
            -- Annual Report task
            compliance_task_id := entity_identifier || '-' || year || '-an-annual_report';
            INSERT INTO public.compliance_checks (
                startup_id, task_id, entity_identifier, entity_display_name, 
                year, task_name, ca_required, cs_required
            ) VALUES (
                startup_record.id, compliance_task_id, entity_identifier, entity_display_name,
                year, 'Annual Report', true, false
            );
            total_tasks := total_tasks + 1;
            
            -- Board Meeting Minutes task
            compliance_task_id := entity_identifier || '-' || year || '-an-board_minutes';
            INSERT INTO public.compliance_checks (
                startup_id, task_id, entity_identifier, entity_display_name, 
                year, task_name, ca_required, cs_required
            ) VALUES (
                startup_record.id, compliance_task_id, entity_identifier, entity_display_name,
                year, 'Board Meeting Minutes', false, true
            );
            total_tasks := total_tasks + 1;
            
            -- First year tasks (only for registration year)
            IF year = registration_year THEN
                -- Articles of Incorporation
                compliance_task_id := entity_identifier || '-' || year || '-fy-incorporation';
                INSERT INTO public.compliance_checks (
                    startup_id, task_id, entity_identifier, entity_display_name, 
                    year, task_name, ca_required, cs_required
                ) VALUES (
                    startup_record.id, compliance_task_id, entity_identifier, entity_display_name,
                    year, 'Articles of Incorporation', true, false
                );
                total_tasks := total_tasks + 1;
            END IF;
        END LOOP;
        
        tasks_created := tasks_created + 1;
        RAISE NOTICE '✅ Generated compliance tasks for startup ID: % (Name: %)', startup_record.id, startup_record.name;
    END LOOP;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'COMPLIANCE TASK GENERATION COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total startups processed: %', tasks_created;
    RAISE NOTICE 'Total tasks created: %', total_tasks;
    RAISE NOTICE '========================================';
END $$;

-- Step 4: Verify tasks were created
-- =====================================================

SELECT 
    'verification' as check_type,
    COUNT(*) as total_tasks,
    COUNT(DISTINCT startup_id) as startups_with_tasks
FROM public.compliance_checks;

-- Step 5: Show sample tasks for verification
-- =====================================================

SELECT 
    'sample_tasks' as check_type,
    startup_id,
    task_id,
    entity_display_name,
    year,
    task_name,
    ca_required,
    cs_required
FROM public.compliance_checks 
ORDER BY startup_id, year, task_name
LIMIT 15;

-- Step 6: Show tasks by startup
-- =====================================================

SELECT 
    'tasks_by_startup' as check_type,
    s.name as startup_name,
    s.country_of_registration,
    s.company_type,
    COUNT(cc.id) as task_count
FROM public.startups s
LEFT JOIN public.compliance_checks cc ON s.id = cc.startup_id
WHERE s.country_of_registration IS NOT NULL 
AND s.company_type IS NOT NULL 
AND s.registration_date IS NOT NULL
GROUP BY s.id, s.name, s.country_of_registration, s.company_type
ORDER BY s.id;

-- Step 7: Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'COMPLIANCE TASKS GENERATED FOR ALL PROFILES!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ All existing profiles now have compliance tasks';
    RAISE NOTICE '✅ Tasks will show immediately without editing profile';
    RAISE NOTICE '✅ Tasks are based on country, company type, and registration date';
    RAISE NOTICE '✅ Check the compliance page now - no profile edit needed!';
    RAISE NOTICE '========================================';
END $$;


