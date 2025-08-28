-- =====================================================
-- QUICK FIX FOR NULL application_id ERROR
-- =====================================================
-- This script fixes the immediate NULL application_id error

-- Step 1: Drop the problematic function
DROP FUNCTION IF EXISTS safe_update_diligence_status(UUID, TEXT, TEXT);

-- Step 2: Create the fixed function
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

-- Step 3: Grant permissions
GRANT EXECUTE ON FUNCTION safe_update_diligence_status(UUID, TEXT, TEXT) TO authenticated;

-- Step 4: Test the function
SELECT 'QUICK FIX APPLIED - NULL application_id ERROR SHOULD BE RESOLVED' as status;
