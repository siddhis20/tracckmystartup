-- =====================================================
-- FIX DILIGENCE FLOW - FINAL CORRECTED VERSION
-- =====================================================
-- This script fixes the diligence flow to work as intended:
-- 1. Accept Application → 2. Request Diligence → 3. Startup Accepts → 4. Compliance Access Granted

-- =====================================================
-- STEP 1: FIX THE COMPLIANCE ACCESS FUNCTION
-- =====================================================

-- Update the grant_facilitator_compliance_access function to require application_id
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

-- =====================================================
-- STEP 2: FIX THE SAFE_UPDATE_DILIGENCE_STATUS FUNCTION
-- =====================================================

-- Drop the existing function first to avoid parameter name conflicts
DROP FUNCTION IF EXISTS safe_update_diligence_status(UUID, TEXT, TEXT);

-- Create the corrected version that properly handles application_id
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
    -- Get application details
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
            -- Grant compliance access to the facilitator using the application_id
            PERFORM grant_facilitator_compliance_access(
                app_record.facilitator_id,
                app_record.startup_id,
                p_application_id  -- This is the key fix - passing the application_id
            );
            
            RAISE NOTICE 'Diligence approved by startup and compliance access granted for application %', p_application_id;
        END IF;
        
        RETURN update_success > 0;
    ELSE
        RAISE NOTICE 'Status transition not allowed: current=% to new=%', app_record.diligence_status, p_new_status;
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 3: CREATE FUNCTION TO REQUEST DILIGENCE
-- =====================================================

-- Function to request diligence (step 2 in the flow)
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

-- =====================================================
-- STEP 4: GRANT PERMISSIONS
-- =====================================================

-- Grant execute permissions for all functions
GRANT EXECUTE ON FUNCTION safe_update_diligence_status(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION request_diligence(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION grant_facilitator_compliance_access(UUID, BIGINT, UUID) TO authenticated;

-- =====================================================
-- STEP 5: TEST THE FLOW
-- =====================================================

-- Show current applications and their status
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

-- =====================================================
-- STEP 6: SUMMARY
-- =====================================================

SELECT 'DILIGENCE FLOW FIXED - FINAL VERSION' as summary;
SELECT 
    '✅ Accept Application → Request Diligence → Startup Accepts → Compliance Access Granted' as flow,
    '✅ Fixed NULL application_id error in compliance_access' as fix_1,
    '✅ No facilitator approval needed - startup acceptance grants access' as fix_2,
    '✅ Proper application_id passed to compliance_access table' as fix_3;
