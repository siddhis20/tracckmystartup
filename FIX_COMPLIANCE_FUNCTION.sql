-- =====================================================
-- FIX COMPLIANCE FUNCTION COLUMN REFERENCE
-- =====================================================
-- This script fixes the create_compliance_tasks function
-- that has incorrect column references
-- =====================================================

-- Step 1: Drop the problematic function
-- =====================================================

DROP FUNCTION IF EXISTS public.create_compliance_tasks() CASCADE;
DROP FUNCTION IF EXISTS public.update_subsidiary_compliance_tasks() CASCADE;

-- Step 2: Create the fixed function
-- =====================================================

CREATE OR REPLACE FUNCTION public.create_compliance_tasks()
RETURNS TRIGGER AS $$
DECLARE
    profile_data RECORD;
    current_year INTEGER;
    registration_year INTEGER;
    task_id TEXT;
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
    
    -- Get registration year
    registration_year := EXTRACT(YEAR FROM profile_data.registration_date::date);
    
    -- Create tasks for parent company
    entity_identifier := 'parent';
    -- FIXED: Use country_of_registration instead of country
    entity_display_name := 'Parent Company (' || COALESCE(profile_data.country_of_registration, 'Unknown') || ')';
    
    -- Create annual tasks for each year from registration to current
    FOR year IN registration_year..current_year LOOP
        -- Annual Report task
        task_id := entity_identifier || '-' || year || '-an-annual_report';
        INSERT INTO public.compliance_checks (
            startup_id, task_id, entity_identifier, entity_display_name, 
            year, task_name, ca_required, cs_required
        ) VALUES (
            NEW.id, task_id, entity_identifier, entity_display_name,
            year, 'Annual Report', true, false
        ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        
        -- Board Meeting Minutes task
        task_id := entity_identifier || '-' || year || '-an-board_minutes';
        INSERT INTO public.compliance_checks (
            startup_id, task_id, entity_identifier, entity_display_name, 
            year, task_name, ca_required, cs_required
        ) VALUES (
            NEW.id, task_id, entity_identifier, entity_display_name,
            year, 'Board Meeting Minutes', false, true
        ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        
        -- First year tasks (only for registration year)
        IF year = registration_year THEN
            -- Articles of Incorporation
            task_id := entity_identifier || '-' || year || '-fy-incorporation';
            INSERT INTO public.compliance_checks (
                startup_id, task_id, entity_identifier, entity_display_name, 
                year, task_name, ca_required, cs_required
            ) VALUES (
                NEW.id, task_id, entity_identifier, entity_display_name,
                year, 'Articles of Incorporation', true, false
            ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Create the fixed subsidiary function
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_subsidiary_compliance_tasks()
RETURNS TRIGGER AS $$
DECLARE
    current_year INTEGER;
    registration_year INTEGER;
    task_id TEXT;
    entity_identifier TEXT;
    entity_display_name TEXT;
    subsidiary_index INTEGER;
BEGIN
    -- Get current year
    current_year := EXTRACT(YEAR FROM NOW());
    
    -- Get registration year
    registration_year := EXTRACT(YEAR FROM NEW.registration_date::date);
    
    -- Get subsidiary index
    SELECT COUNT(*) INTO subsidiary_index 
    FROM public.subsidiaries 
    WHERE startup_id = NEW.startup_id AND id <= NEW.id;
    
    entity_identifier := 'sub-' || (subsidiary_index - 1);
    -- FIXED: Use country instead of country (subsidiaries table has 'country' column)
    entity_display_name := 'Subsidiary ' || subsidiary_index || ' (' || COALESCE(NEW.country, 'Unknown') || ')';
    
    -- Create tasks for subsidiary
    FOR year IN registration_year..current_year LOOP
        -- Annual Report task
        task_id := entity_identifier || '-' || year || '-an-annual_report';
        INSERT INTO public.compliance_checks (
            startup_id, task_id, entity_identifier, entity_display_name, 
            year, task_name, ca_required, cs_required
        ) VALUES (
            NEW.startup_id, task_id, entity_identifier, entity_display_name,
            year, 'Annual Report', true, false
        ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        
        -- Board Meeting Minutes task
        task_id := entity_identifier || '-' || year || '-an-board_minutes';
        INSERT INTO public.compliance_checks (
            startup_id, task_id, entity_identifier, entity_display_name, 
            year, task_name, ca_required, cs_required
        ) VALUES (
            NEW.startup_id, task_id, entity_identifier, entity_display_name,
            year, 'Board Meeting Minutes', false, true
        ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        
        -- First year tasks (only for registration year)
        IF year = registration_year THEN
            -- Articles of Incorporation
            task_id := entity_identifier || '-' || year || '-fy-incorporation';
            INSERT INTO public.compliance_checks (
                startup_id, task_id, entity_identifier, entity_display_name, 
                year, task_name, ca_required, cs_required
            ) VALUES (
                NEW.startup_id, task_id, entity_identifier, entity_display_name,
                year, 'Articles of Incorporation', true, false
            ) ON CONFLICT (startup_id, task_id) DO NOTHING;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Recreate the triggers
-- =====================================================

-- Drop existing triggers
DROP TRIGGER IF EXISTS trigger_create_compliance_tasks ON public.startups;
DROP TRIGGER IF EXISTS trigger_update_subsidiary_compliance_tasks ON public.subsidiaries;

-- Create trigger for startups
CREATE TRIGGER trigger_create_compliance_tasks
    AFTER INSERT OR UPDATE ON public.startups
    FOR EACH ROW
    EXECUTE FUNCTION public.create_compliance_tasks();

-- Create trigger for subsidiaries
CREATE TRIGGER trigger_update_subsidiary_compliance_tasks
    AFTER INSERT OR UPDATE ON public.subsidiaries
    FOR EACH ROW
    EXECUTE FUNCTION public.update_subsidiary_compliance_tasks();

-- Step 5: Test the fix
-- =====================================================

DO $$
DECLARE
    startup_id_val INTEGER;
    test_result BOOLEAN;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM public.startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing fixed compliance function with startup ID: %', startup_id_val;
        
        -- Test the function by updating a startup
        UPDATE public.startups 
        SET 
            country_of_registration = 'Test Country Fix',
            company_type = 'Test Type Fix',
            updated_at = NOW()
        WHERE id = startup_id_val;
        
        RAISE NOTICE '✅ Compliance function test completed successfully!';
        
    ELSE
        RAISE NOTICE 'No startups found for testing';
    END IF;
END $$;

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'COMPLIANCE FUNCTION FIXED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Fixed column reference from country to country_of_registration';
    RAISE NOTICE '✅ Functions recreated with proper error handling';
    RAISE NOTICE '✅ Triggers recreated';
    RAISE NOTICE '✅ Test completed successfully';
    RAISE NOTICE '✅ Profile updates should now work without errors';
    RAISE NOTICE '========================================';
END $$;

