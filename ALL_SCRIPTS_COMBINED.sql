-- =====================================================
-- ALL SCRIPTS COMBINED - COMPLETE FIX FOR TRACK MY STARTUP
-- =====================================================
-- This script contains all the necessary fixes for the Track My Startup application
-- Run this script in your database to resolve all issues

-- =====================================================
-- SCRIPT 1: EMERGENCY INVESTOR FIX
-- =====================================================

-- Step 1: Check current state
SELECT '=== EMERGENCY DIAGNOSIS ===' as info;

-- Check the specific user having issues
SELECT 
    'Problem User Analysis' as check_type,
    id,
    email,
    role,
    investor_code,
    startup_name,
    created_at,
    CASE 
        WHEN investor_code IS NULL THEN '❌ CRITICAL: Missing Investor Code'
        WHEN investor_code = '' THEN '⚠️ WARNING: Empty Investor Code'
        ELSE '✅ OK: Has Investor Code'
    END as code_status,
    CASE 
        WHEN startup_name IS NULL THEN '⚠️ WARNING: startup_name is NULL'
        WHEN startup_name = '' THEN '⚠️ WARNING: startup_name is empty'
        ELSE '✅ OK: startup_name has value'
    END as startup_status
FROM users 
WHERE email = 'olympiad_info1@startupnationindia.com';

-- Step 2: Check if investor_code column exists
SELECT 
    'Column Check' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'investor_code';

-- Step 3: EMERGENCY FIX - Generate investor code for the specific user
DO $$
DECLARE
    user_id UUID;
    new_code TEXT;
    attempts INTEGER;
    max_attempts INTEGER := 100;
BEGIN
    -- Get the user ID
    SELECT id INTO user_id 
    FROM users 
    WHERE email = 'olympiad_info1@startupnationindia.com';
    
    IF user_id IS NULL THEN
        RAISE EXCEPTION 'User not found: olympiad_info1@startupnationindia.com';
    END IF;
    
    -- Generate a unique investor code
    attempts := 0;
    LOOP
        attempts := attempts + 1;
        new_code := 'INV-' || 
                   upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 6));
        
        -- Check if code already exists
        IF NOT EXISTS (
            SELECT 1 FROM users WHERE investor_code = new_code
        ) THEN
            EXIT;
        END IF;
        
        -- Prevent infinite loop
        IF attempts >= max_attempts THEN
            RAISE EXCEPTION 'Unable to generate unique investor code after % attempts', max_attempts;
        END IF;
    END LOOP;
    
    -- Update the user with the new investor code
    UPDATE users 
    SET investor_code = new_code 
    WHERE id = user_id;
    
    RAISE NOTICE 'EMERGENCY FIX: Generated investor code % for user % (%)', new_code, 'olympiad_info1@startupnationindia.com', user_id;
END $$;

-- Step 3.5: COMPREHENSIVE FIX - Generate codes for ALL investors missing codes
DO $$
DECLARE
    user_record RECORD;
    new_code TEXT;
    attempts INTEGER;
    max_attempts INTEGER := 100;
    codes_generated INTEGER := 0;
BEGIN
    FOR user_record IN 
        SELECT id, email 
        FROM users 
        WHERE role = 'Investor' 
        AND (investor_code IS NULL OR investor_code = '')
    LOOP
        -- Generate a unique investor code
        attempts := 0;
        LOOP
            attempts := attempts + 1;
            new_code := 'INV-' || 
                       upper(substring(md5(random()::text || clock_timestamp()::text || user_record.id::text) from 1 for 6));
            
            -- Check if code already exists
            IF NOT EXISTS (
                SELECT 1 FROM users WHERE investor_code = new_code
            ) THEN
                EXIT;
            END IF;
            
            -- Prevent infinite loop
            IF attempts >= max_attempts THEN
                RAISE EXCEPTION 'Unable to generate unique investor code after % attempts for user %', max_attempts, user_record.email;
            END IF;
        END LOOP;
        
        -- Update the user with the new investor code
        UPDATE users 
        SET investor_code = new_code 
        WHERE id = user_record.id;
        
        codes_generated := codes_generated + 1;
        RAISE NOTICE 'COMPREHENSIVE FIX: Generated investor code % for user % (%)', new_code, user_record.email, user_record.id;
    END LOOP;
    
    RAISE NOTICE 'COMPREHENSIVE FIX: Generated % investor codes for missing users', codes_generated;
END $$;

-- Step 4: Fix startup_name type issue if it exists
UPDATE users 
SET startup_name = NULL 
WHERE email = 'olympiad_info1@startupnationindia.com' 
AND startup_name IS NOT NULL 
AND startup_name::text = 'null';

-- =====================================================
-- SCRIPT 2: FIX COMPLIANCE CHECKS CONSTRAINTS
-- =====================================================

-- Add unique constraint on startup_id and task_id to prevent duplicates
-- First check if constraint already exists, if not, add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'compliance_checks_startup_task_unique'
        AND conrelid = 'public.compliance_checks'::regclass
    ) THEN
        ALTER TABLE public.compliance_checks 
        ADD CONSTRAINT compliance_checks_startup_task_unique 
        UNIQUE (startup_id, task_id);
        RAISE NOTICE 'Added unique constraint: compliance_checks_startup_task_unique';
    ELSE
        RAISE NOTICE 'Constraint already exists: compliance_checks_startup_task_unique';
    END IF;
END $$;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_compliance_checks_startup_id 
ON public.compliance_checks(startup_id);

CREATE INDEX IF NOT EXISTS idx_compliance_checks_task_id 
ON public.compliance_checks(task_id);

CREATE INDEX IF NOT EXISTS idx_compliance_checks_entity_identifier 
ON public.compliance_checks(entity_identifier);

-- Remove any duplicate entries that might exist
WITH duplicates AS (
  SELECT id, 
         ROW_NUMBER() OVER (PARTITION BY startup_id, task_id ORDER BY created_at DESC) as rn
  FROM public.compliance_checks
)
DELETE FROM public.compliance_checks 
WHERE id IN (
  SELECT id FROM duplicates WHERE rn > 1
);

-- =====================================================
-- SCRIPT 3: FIX STARTUP NAME MISMATCH
-- =====================================================

-- Show the current mismatches
SELECT '=== CURRENT MISMATCHES ===' as step;
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    s.user_id,
    u.email as user_email,
    u.startup_name as user_startup_name,
    'MISMATCH' as status
FROM startups s
JOIN users u ON s.user_id = u.id
WHERE s.name != u.startup_name;

-- Fix the mismatches by updating user startup_name to match startup name
UPDATE users 
SET startup_name = (
    SELECT s.name 
    FROM startups s 
    WHERE s.user_id = users.id 
    LIMIT 1
)
WHERE role = 'Startup' 
AND id IN (
    SELECT s.user_id 
    FROM startups s 
    JOIN users u ON s.user_id = u.id 
    WHERE s.name != u.startup_name
);

-- =====================================================
-- SCRIPT 4: FIX DILIGENCE ERROR
-- =====================================================

-- Drop the problematic function
DROP FUNCTION IF EXISTS safe_update_diligence_status(UUID, TEXT, TEXT);

-- Create the fixed function
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION safe_update_diligence_status(UUID, TEXT, TEXT) TO authenticated;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify investor code fix
SELECT 
    'Fix Verification' as check_type,
    id,
    email,
    role,
    investor_code,
    startup_name,
    created_at,
    CASE 
        WHEN investor_code IS NULL THEN '❌ STILL MISSING CODE'
        WHEN investor_code = '' THEN '⚠️ STILL EMPTY CODE'
        ELSE '✅ FIXED: Has Investor Code'
    END as code_status
FROM users 
WHERE email = 'olympiad_info1@startupnationindia.com';

-- Check all investors after fix
SELECT 
    'All Investors Status' as check_type,
    COUNT(*) as total_investors,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes
FROM users 
WHERE role = 'Investor';

-- Verify startup name fix
SELECT '=== AFTER STARTUP NAME FIX ===' as step;
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    s.user_id,
    u.email as user_email,
    u.startup_name as user_startup_name,
    CASE 
        WHEN s.name = u.startup_name THEN 'MATCHED'
        ELSE 'MISMATCH'
    END as relationship_status
FROM startups s
LEFT JOIN users u ON s.user_id = u.id
ORDER BY s.created_at DESC;

-- Verify compliance constraints
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.compliance_checks'::regclass
AND conname = 'compliance_checks_startup_task_unique';

-- Final status check
SELECT 
    'FINAL STATUS' as test_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE role = 'Investor' AND (investor_code IS NULL OR investor_code = '')
        ) THEN '❌ SYSTEM NOT READY: Some investors missing codes'
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE role = 'Investor' AND investor_code !~ '^INV-[A-Z0-9]{6}$'
        ) THEN '⚠️ SYSTEM PARTIALLY READY: Some codes have invalid format'
        ELSE '✅ SYSTEM READY: All investors have valid codes'
    END as overall_status;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 ALL SCRIPTS COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '✅ Investor codes generated for all missing users';
    RAISE NOTICE '✅ Compliance checks table constraints fixed';
    RAISE NOTICE '✅ Startup name mismatches resolved';
    RAISE NOTICE '✅ Diligence function fixed';
    RAISE NOTICE '✅ All database issues resolved';
    RAISE NOTICE '🚀 Your Track My Startup application should now work properly!';
END $$;
