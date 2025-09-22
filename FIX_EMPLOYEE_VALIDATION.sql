-- =====================================================
-- FIX EMPLOYEE VALIDATION - PREVENT HIRING BEFORE REGISTRATION
-- =====================================================

-- Update the add_employee function to include validation
CREATE OR REPLACE FUNCTION add_employee(
    startup_id_param INTEGER,
    name_param TEXT,
    joining_date_param DATE,
    entity_param TEXT,
    department_param TEXT,
    salary_param DECIMAL(10,2),
    esop_allocation_param DECIMAL(10,2) DEFAULT 0,
    allocation_type_param esop_allocation_type DEFAULT 'one-time',
    esop_per_allocation_param DECIMAL(10,2) DEFAULT 0,
    contract_url_param TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    employee_id UUID;
    startup_registration_date DATE;
BEGIN
    -- Get the startup's registration date
    SELECT registration_date INTO startup_registration_date
    FROM startups 
    WHERE id = startup_id_param;
    
    -- Validate that employee joining date is not before company registration date
    IF startup_registration_date IS NOT NULL AND joining_date_param < startup_registration_date THEN
        RAISE EXCEPTION 'Employee joining date cannot be before the company registration date (%). Please select a date on or after the registration date.', startup_registration_date;
    END IF;
    
    -- Insert the employee
    INSERT INTO employees (
        startup_id, name, joining_date, entity, department, salary,
        esop_allocation, allocation_type, esop_per_allocation, contract_url
    ) VALUES (
        startup_id_param, name_param, joining_date_param, entity_param, 
        department_param, salary_param, esop_allocation_param, allocation_type_param,
        esop_per_allocation_param, contract_url_param
    ) RETURNING id INTO employee_id;
    
    RETURN employee_id;
END;
$$ LANGUAGE plpgsql;

-- Test the updated function
DO $$
DECLARE
    test_startup_id INTEGER;
    test_result UUID;
BEGIN
    -- Get a startup ID for testing
    SELECT id INTO test_startup_id FROM startups LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing add_employee function with startup ID: %', test_startup_id;
        
        -- This should work (joining date after registration)
        BEGIN
            SELECT add_employee(
                test_startup_id,
                'Test Employee',
                CURRENT_DATE,
                'Test Entity',
                'Test Department',
                50000.00
            ) INTO test_result;
            RAISE NOTICE '✅ Valid employee creation test passed';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Valid employee creation test failed: %', SQLERRM;
        END;
        
        -- This should fail (joining date before registration)
        BEGIN
            SELECT add_employee(
                test_startup_id,
                'Invalid Employee',
                '1900-01-01'::DATE,
                'Test Entity',
                'Test Department',
                50000.00
            ) INTO test_result;
            RAISE NOTICE '❌ Invalid employee creation test failed - should have thrown error';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '✅ Invalid employee creation test passed - error caught: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'No startups found for testing';
    END IF;
END $$;
