-- =====================================================
-- RESTORE COMPLIANCE FUNCTION - GENERATES TASKS ON PROFILE UPDATE
-- =====================================================
-- This script restores the compliance function that generates tasks
-- when profile is updated, without breaking existing functionality
-- =====================================================

-- Step 1: Check if compliance function exists
-- =====================================================

SELECT 
    'function_check' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'create_compliance_tasks'
AND routine_schema = 'public';

-- Step 2: Create the compliance function (if it doesn't exist or is broken)
-- =====================================================

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

-- Step 3: Create the trigger (if it doesn't exist)
-- =====================================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_create_compliance_tasks ON public.startups;

-- Create trigger for startups
CREATE TRIGGER trigger_create_compliance_tasks
    AFTER INSERT OR UPDATE ON public.startups
    FOR EACH ROW
    EXECUTE FUNCTION public.create_compliance_tasks();

-- Step 4: Test the function by updating an existing startup
-- =====================================================

DO $$
DECLARE
    startup_id_val INTEGER;
    tasks_count_before INTEGER;
    tasks_count_after INTEGER;
BEGIN
    -- Get first startup with profile data
    SELECT id INTO startup_id_val 
    FROM public.startups 
    WHERE country_of_registration IS NOT NULL 
    AND company_type IS NOT NULL 
    AND registration_date IS NOT NULL
    ORDER BY id 
    LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing compliance task generation for startup ID: %', startup_id_val;
        
        -- Count existing tasks
        SELECT COUNT(*) INTO tasks_count_before 
        FROM public.compliance_checks 
        WHERE startup_id = startup_id_val;
        
        RAISE NOTICE 'Tasks before update: %', tasks_count_before;
        
        -- Trigger the function by updating the startup
        UPDATE public.startups 
        SET updated_at = NOW()
        WHERE id = startup_id_val;
        
        -- Count tasks after update
        SELECT COUNT(*) INTO tasks_count_after 
        FROM public.compliance_checks 
        WHERE startup_id = startup_id_val;
        
        RAISE NOTICE 'Tasks after update: %', tasks_count_after;
        
        IF tasks_count_after > tasks_count_before THEN
            RAISE NOTICE '✅ Compliance tasks generated successfully!';
        ELSE
            RAISE NOTICE '⚠️ No new tasks generated (might already exist)';
        END IF;
        
    ELSE
        RAISE NOTICE 'No startups with complete profile data found for testing';
    END IF;
END $$;

-- Step 5: Show current compliance tasks
-- =====================================================

SELECT 
    'current_compliance_tasks' as check_type,
    COUNT(*) as total_tasks,
    COUNT(DISTINCT startup_id) as startups_with_tasks
FROM public.compliance_checks;

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'COMPLIANCE FUNCTION RESTORED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Compliance function created/updated';
    RAISE NOTICE '✅ Trigger created/updated';
    RAISE NOTICE '✅ Tasks will be generated on profile updates';
    RAISE NOTICE '✅ Check the compliance page now';
    RAISE NOTICE '========================================';
END $$;


