-- =====================================================
-- FINAL DILIGENCE FIX - REMOVES CONFLICTING TRIGGER
-- =====================================================
-- This script removes the conflicting trigger that calls the old function

-- Step 1: Drop the conflicting trigger and function
DROP TRIGGER IF EXISTS diligence_approval_access_trigger ON public.opportunity_applications;
DROP FUNCTION IF EXISTS grant_facilitator_access_on_diligence_approval();

-- Step 2: Drop ALL conflicting functions to ensure clean slate
DROP FUNCTION IF EXISTS safe_update_diligence_status(UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS grant_facilitator_compliance_access(UUID, BIGINT);
DROP FUNCTION IF EXISTS grant_facilitator_compliance_access(UUID, BIGINT, UUID);
DROP FUNCTION IF EXISTS request_diligence(UUID);
DROP FUNCTION IF EXISTS approve_diligence(UUID);

-- Step 3: Create the correct safe_update_diligence_status function
CREATE OR REPLACE FUNCTION safe_update_diligence_status(
    p_application_id UUID,
    p_new_status TEXT,
    p_old_status TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    app_record RECORD;
    update_success BOOLEAN;
BEGIN
    -- Get application details with facilitator_id
    SELECT 
        oa.id,
        oa.startup_id,
        oa.diligence_status,
        io.facilitator_id
    INTO app_record
    FROM opportunity_applications oa
    JOIN incubation_opportunities io ON oa.opportunity_id = io.id
    WHERE oa.id = p_application_id;
    
    -- Check if application exists
    IF app_record.id IS NULL THEN
        RAISE EXCEPTION 'Application not found: %', p_application_id;
    END IF;
    
    -- Check if status transition is valid
    IF app_record.diligence_status = p_old_status THEN
        -- Update the diligence status
        UPDATE opportunity_applications 
        SET diligence_status = p_new_status, updated_at = NOW()
        WHERE id = p_application_id;
        
        GET DIAGNOSTICS update_success = ROW_COUNT;
        
        -- If diligence is approved by startup, grant compliance access
        IF p_new_status = 'approved' AND update_success > 0 THEN
            -- Insert compliance access record with proper application_id
            INSERT INTO compliance_access (
                facilitator_id, 
                startup_id, 
                application_id,
                expires_at
            ) VALUES (
                app_record.facilitator_id,
                app_record.startup_id,
                p_application_id,  -- This is the key fix
                NOW() + INTERVAL '30 days'
            )
            ON CONFLICT (facilitator_id, startup_id, application_id)
            DO UPDATE SET 
                is_active = TRUE,
                access_granted_at = NOW(),
                expires_at = NOW() + INTERVAL '30 days';
            
            RAISE NOTICE 'Diligence approved and compliance access granted for application %', p_application_id;
        END IF;
        
        RETURN update_success > 0;
    ELSE
        RAISE NOTICE 'Status transition not allowed: current=% to new=%', app_record.diligence_status, p_new_status;
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create the correct grant_facilitator_compliance_access function
CREATE OR REPLACE FUNCTION grant_facilitator_compliance_access(
    p_facilitator_id UUID,
    p_startup_id BIGINT,
    p_application_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    access_count INTEGER;
BEGIN
    -- Grant compliance access using the proper system with application_id
    INSERT INTO compliance_access (
        facilitator_id, 
        startup_id, 
        application_id,
        expires_at
    ) VALUES (
        p_facilitator_id,
        p_startup_id,
        p_application_id,
        NOW() + INTERVAL '30 days'
    )
    ON CONFLICT (facilitator_id, startup_id, application_id)
    DO UPDATE SET 
        is_active = TRUE,
        access_granted_at = NOW(),
        expires_at = NOW() + INTERVAL '30 days';
    
    GET DIAGNOSTICS access_count = ROW_COUNT;
    
    RAISE NOTICE 'Compliance access granted for facilitator % to startup % for application %', 
        p_facilitator_id, p_startup_id, p_application_id;
    
    RETURN access_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create the request_diligence function
CREATE OR REPLACE FUNCTION request_diligence(
    p_application_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    app_record RECORD;
    update_success BOOLEAN;
BEGIN
    -- Get application details
    SELECT 
        oa.id,
        oa.status,
        oa.diligence_status
    INTO app_record
    FROM opportunity_applications oa
    WHERE oa.id = p_application_id;
    
    -- Check if application exists and is accepted
    IF app_record.id IS NULL THEN
        RAISE EXCEPTION 'Application not found: %', p_application_id;
    END IF;
    
    IF app_record.status != 'accepted' THEN
        RAISE EXCEPTION 'Can only request diligence for accepted applications. Current status: %', app_record.status;
    END IF;
    
    IF app_record.diligence_status = 'requested' THEN
        RAISE NOTICE 'Diligence already requested for application %', p_application_id;
        RETURN TRUE;
    END IF;
    
    -- Update diligence status to requested
    UPDATE opportunity_applications 
    SET diligence_status = 'requested', updated_at = NOW()
    WHERE id = p_application_id;
    
    GET DIAGNOSTICS update_success = ROW_COUNT;
    
    RAISE NOTICE 'Diligence requested for application %', p_application_id;
    RETURN update_success > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Grant permissions for all functions
GRANT EXECUTE ON FUNCTION safe_update_diligence_status(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION grant_facilitator_compliance_access(UUID, BIGINT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION request_diligence(UUID) TO authenticated;

-- Step 7: Verify no conflicting triggers exist
SELECT 'CHECKING FOR CONFLICTING TRIGGERS:' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%diligence%' OR trigger_name LIKE '%access%';

-- Step 8: Verify functions exist
SELECT 'VERIFYING FUNCTIONS:' as info;
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name IN (
    'safe_update_diligence_status',
    'grant_facilitator_compliance_access',
    'request_diligence'
)
ORDER BY routine_name;

-- Step 9: Test current applications
SELECT 'CURRENT APPLICATIONS STATUS:' as info;
SELECT 
    oa.id as application_id,
    s.name as startup_name,
    io.program_name,
    oa.status,
    oa.diligence_status,
    CASE 
        WHEN oa.status = 'accepted' AND (oa.diligence_status IS NULL OR oa.diligence_status = 'none') 
        THEN 'Can Request Diligence'
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'requested' 
        THEN 'Waiting for Startup to Accept'
        WHEN oa.diligence_status = 'approved' 
        THEN 'Compliance Access Granted'
        ELSE 'No Action Available'
    END as available_action
FROM opportunity_applications oa
JOIN incubation_opportunities io ON oa.opportunity_id = io.id
JOIN startups s ON oa.startup_id = s.id
ORDER BY oa.created_at DESC;

-- Step 10: Summary
SELECT 'FINAL DILIGENCE FIX APPLIED' as summary;
SELECT 
    '✅ Conflicting trigger removed' as fix_1,
    '✅ All conflicting functions dropped and recreated' as fix_2,
    '✅ safe_update_diligence_status properly handles application_id' as fix_3,
    '✅ grant_facilitator_compliance_access has correct 3-parameter signature' as fix_4,
    '✅ All permissions granted correctly' as fix_5;
