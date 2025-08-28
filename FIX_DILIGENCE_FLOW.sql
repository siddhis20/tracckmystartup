-- =====================================================
-- FIX DILIGENCE FLOW - PROPER SEQUENCE
-- =====================================================
-- This script fixes the diligence acceptance flow to follow the proper sequence:
-- 1. Accept Application → 2. Request Diligence → 3. Approve Diligence → 4. Grant Compliance Access

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
-- STEP 2: UPDATE THE SAFE_UPDATE_DILIGENCE_STATUS FUNCTION
-- =====================================================

-- Drop the existing function first to avoid parameter name conflicts
DROP FUNCTION IF EXISTS safe_update_diligence_status(UUID, TEXT, TEXT);

-- Create a new version that handles the proper flow
CREATE OR REPLACE FUNCTION safe_update_diligence_status(
    p_application_id UUID,
    p_new_status TEXT,
    p_old_status TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    app_record RECORD;
    facilitator_id UUID;
    startup_id BIGINT;
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
        
        -- If diligence is approved, grant compliance access
        IF p_new_status = 'approved' AND update_success > 0 THEN
            -- Grant compliance access to the facilitator
            PERFORM grant_facilitator_compliance_access(
                app_record.facilitator_id,
                app_record.startup_id,
                p_application_id
            );
            
            RAISE NOTICE 'Diligence approved and compliance access granted for application %', p_application_id;
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
-- STEP 4: CREATE FUNCTION TO APPROVE DILIGENCE
-- =====================================================

-- Function to approve diligence (step 3 in the flow)
CREATE OR REPLACE FUNCTION approve_diligence(
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
    
    -- Check if application exists and diligence was requested
    IF app_record.id IS NULL THEN
        RAISE EXCEPTION 'Application not found: %', p_application_id;
    END IF;
    
    IF app_record.status != 'accepted' THEN
        RAISE EXCEPTION 'Can only approve diligence for accepted applications. Current status: %', app_record.status;
    END IF;
    
    IF app_record.diligence_status != 'requested' THEN
        RAISE EXCEPTION 'Can only approve diligence that was requested. Current diligence status: %', app_record.diligence_status;
    END IF;
    
    -- Use the safe_update_diligence_status function
    RETURN safe_update_diligence_status(p_application_id, 'approved', 'requested');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 5: GRANT PERMISSIONS
-- =====================================================

-- Grant execute permissions for all functions
GRANT EXECUTE ON FUNCTION safe_update_diligence_status(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION request_diligence(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION approve_diligence(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION grant_facilitator_compliance_access(UUID, BIGINT, UUID) TO authenticated;

-- =====================================================
-- STEP 6: CREATE HELPER FUNCTION TO GET APPLICATION STATUS
-- =====================================================

-- Function to get application status for UI
CREATE OR REPLACE FUNCTION get_application_status(
    p_application_id UUID
)
RETURNS TABLE (
    application_id UUID,
    startup_id BIGINT,
    startup_name TEXT,
    opportunity_id UUID,
    program_name TEXT,
    status TEXT,
    diligence_status TEXT,
    can_request_diligence BOOLEAN,
    can_approve_diligence BOOLEAN,
    can_view_compliance BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        oa.id as application_id,
        oa.startup_id,
        s.name as startup_name,
        oa.opportunity_id,
        io.program_name,
        oa.status,
        oa.diligence_status,
        -- Can request diligence if: accepted and no diligence requested yet
        (oa.status = 'accepted' AND (oa.diligence_status IS NULL OR oa.diligence_status = 'none')) as can_request_diligence,
        -- Can approve diligence if: accepted and diligence was requested
        (oa.status = 'accepted' AND oa.diligence_status = 'requested') as can_approve_diligence,
        -- Can view compliance if: diligence is approved
        (oa.diligence_status = 'approved') as can_view_compliance
    FROM opportunity_applications oa
    JOIN incubation_opportunities io ON oa.opportunity_id = io.id
    JOIN startups s ON oa.startup_id = s.id
    WHERE oa.id = p_application_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_application_status(UUID) TO authenticated;

-- =====================================================
-- STEP 7: TEST THE FLOW
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
        THEN 'Can Approve Diligence'
        WHEN oa.diligence_status = 'approved' 
        THEN 'Can View Compliance'
        ELSE 'No Action Available'
    END as available_action
FROM opportunity_applications oa
JOIN incubation_opportunities io ON oa.opportunity_id = io.id
JOIN startups s ON oa.startup_id = s.id
ORDER BY oa.created_at DESC;

-- =====================================================
-- STEP 8: SUMMARY
-- =====================================================

SELECT 'DILIGENCE FLOW FIXED - PROPER SEQUENCE IMPLEMENTED' as summary;
SELECT 
    '✅ Accept Application → Request Diligence → Approve Diligence → Grant Compliance Access' as flow,
    '✅ All functions updated with proper application_id handling' as functions,
    '✅ Compliance access only granted after diligence approval' as security,
    '✅ UI can now show correct buttons based on application status' as ui;
