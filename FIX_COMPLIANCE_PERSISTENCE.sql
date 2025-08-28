-- =====================================================
-- FIX COMPLIANCE PERSISTENCE - GENERATE TASKS FOR EXISTING PROFILES
-- =====================================================
-- This script ensures compliance tasks are generated for all existing profiles
-- and persist after refresh without requiring profile updates
-- =====================================================

-- Step 1: Check existing startups with profile data
-- =====================================================

SELECT 
    'existing_profiles' as check_type,
    COUNT(*) as total_startups,
    COUNT(CASE WHEN country_of_registration IS NOT NULL AND company_type IS NOT NULL AND registration_date IS NOT NULL THEN 1 END) as complete_profiles
FROM public.startups;

-- Step 2: Show startups that need compliance tasks
-- =====================================================

SELECT 
    'startups_needing_tasks' as check_type,
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

-- Step 3: Generate compliance tasks for all existing profiles
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
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW());
    
    -- Loop through all startups with complete profile data
    FOR startup_record IN 
        SELECT id, country_of_registration, company_type, registration_date
        FROM public.startups 
        WHERE country_of_registration IS NOT NULL 
        AND company_type IS NOT NULL 
        AND registration_date IS NOT NULL
    LOOP
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
            ) ON CONFLICT (startup_id, task_id) DO NOTHING;
            
            -- Board Meeting Minutes task
            compliance_task_id := entity_identifier || '-' || year || '-an-board_minutes';
            INSERT INTO public.compliance_checks (
                startup_id, task_id, entity_identifier, entity_display_name, 
                year, task_name, ca_required, cs_required
            ) VALUES (
                startup_record.id, compliance_task_id, entity_identifier, entity_display_name,
                year, 'Board Meeting Minutes', false, true
            ) ON CONFLICT (startup_id, task_id) DO NOTHING;
            
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
                ) ON CONFLICT (startup_id, task_id) DO NOTHING;
            END IF;
        END LOOP;
        
        tasks_created := tasks_created + 1;
        RAISE NOTICE 'Generated compliance tasks for startup ID: %', startup_record.id;
    END LOOP;
    
    RAISE NOTICE 'Total startups processed: %', tasks_created;
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
LIMIT 10;

-- Step 6: Ensure the trigger function is working correctly
-- =====================================================

-- Update the trigger function to handle existing data better
CREATE OR REPLACE FUNCTION public.create_compliance_tasks()
RETURNS TRIGGER AS $$
DECLARE
    profile_data RECORD;
    current_year INTEGER;
    registration_year INTEGER;
    compliance_task_id TEXT;
    entity_identifier TEXT;
    entity_display_name TEXT;
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW());
    
    -- Get profile data
    SELECT * INTO profile_data FROM public.startups WHERE id = NEW.id;
    
    IF profile_data IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Check if we have the required data
    IF profile_data.country_of_registration IS NULL OR 
       profile_data.company_type IS NULL OR 
       profile_data.registration_date IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Get registration year
    registration_year := EXTRACT(YEAR FROM profile_data.registration_date::date);
    
    -- Create tasks for parent company
    entity_identifier := 'parent';
    entity_display_name := 'Parent Company (' || COALESCE(profile_data.country_of_registration, 'Unknown') || ')';
    
    -- Create annual tasks for each year from registration to current
    FOR year IN registration_year..current_year LOOP
        -- Annual Report task
        compliance_task_id := entity_identifier || '-' || year || '-an-annual_report';
        INSERT INTO public.compliance_checks (
            startup_id, task_id, entity_identifier, entity_display_name, 
            year, task_name, ca_required, cs_required
        ) VALUES (
            NEW.id, compliance_task_id, entity_identifier, entity_display_name,
            year, 'Annual Report', true, false
        ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        
        -- Board Meeting Minutes task
        compliance_task_id := entity_identifier || '-' || year || '-an-board_minutes';
        INSERT INTO public.compliance_checks (
            startup_id, task_id, entity_identifier, entity_display_name, 
            year, task_name, ca_required, cs_required
        ) VALUES (
            NEW.id, compliance_task_id, entity_identifier, entity_display_name,
            year, 'Board Meeting Minutes', false, true
        ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        
        -- First year tasks (only for registration year)
        IF year = registration_year THEN
            -- Articles of Incorporation
            compliance_task_id := entity_identifier || '-' || year || '-fy-incorporation';
            INSERT INTO public.compliance_checks (
                startup_id, task_id, entity_identifier, entity_display_name, 
                year, task_name, ca_required, cs_required
            ) VALUES (
                NEW.id, compliance_task_id, entity_identifier, entity_display_name,
                year, 'Articles of Incorporation', true, false
            ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'COMPLIANCE PERSISTENCE FIXED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Tasks generated for all existing profiles';
    RAISE NOTICE '✅ Tasks will persist after refresh';
    RAISE NOTICE '✅ No need to update profile to see tasks';
    RAISE NOTICE '✅ Check the compliance page now';
    RAISE NOTICE '========================================';
END $$;


