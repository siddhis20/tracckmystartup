-- Fix CS Table Structure - Final Version
-- This script ensures the CS tables have the correct structure and works with auth.users

-- 1. First, ensure users table has cs_code column
ALTER TABLE auth.users 
ADD COLUMN IF NOT EXISTS cs_code VARCHAR(20);

-- 2. Update existing CS users with generated codes if they don't have one
UPDATE auth.users 
SET cs_code = 'CS-' || LPAD(CAST(id AS TEXT), 6, '0')
WHERE role = 'CS' AND cs_code IS NULL;

-- 3. Drop and recreate cs_assignment_requests table with correct structure
DROP TABLE IF EXISTS cs_assignment_requests CASCADE;

CREATE TABLE cs_assignment_requests (
    id BIGSERIAL PRIMARY KEY,
    startup_id BIGINT NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    startup_name TEXT NOT NULL,
    cs_code VARCHAR(20) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ,
    response_notes TEXT
);

-- 4. Drop and recreate cs_assignments table with correct structure
DROP TABLE IF EXISTS cs_assignments CASCADE;

CREATE TABLE cs_assignments (
    id BIGSERIAL PRIMARY KEY,
    cs_code VARCHAR(20) NOT NULL,
    startup_id BIGINT NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ,
    UNIQUE(cs_code, startup_id)
);

-- 5. Create indexes for performance
CREATE INDEX idx_cs_assignment_requests_cs_code ON cs_assignment_requests(cs_code);
CREATE INDEX idx_cs_assignment_requests_startup_id ON cs_assignment_requests(startup_id);
CREATE INDEX idx_cs_assignment_requests_status ON cs_assignment_requests(status);
CREATE INDEX idx_cs_assignments_cs_code ON cs_assignments(cs_code);
CREATE INDEX idx_cs_assignments_startup_id ON cs_assignments(startup_id);

-- 6. Enable RLS and create policies for cs_assignment_requests
ALTER TABLE cs_assignment_requests ENABLE ROW LEVEL SECURITY;

-- CS can view their own requests
CREATE POLICY "cs_assignment_requests_select_own" ON cs_assignment_requests
    FOR SELECT USING (
        cs_code = (SELECT cs_code FROM auth.users WHERE id = auth.uid())
    );

-- CS can update their own requests
CREATE POLICY "cs_assignment_requests_update_own" ON cs_assignment_requests
    FOR UPDATE USING (
        cs_code = (SELECT cs_code FROM auth.users WHERE id = auth.uid())
    );

-- Startups can insert requests for any CS
CREATE POLICY "cs_assignment_requests_insert_startup" ON cs_assignment_requests
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.startups 
            WHERE id = startup_id AND user_id = auth.uid()
        )
    );

-- Startups can view their own requests
CREATE POLICY "cs_assignment_requests_select_startup" ON cs_assignment_requests
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM public.startups WHERE user_id = auth.uid()
        )
    );

-- 7. Enable RLS and create policies for cs_assignments
ALTER TABLE cs_assignments ENABLE ROW LEVEL SECURITY;

-- CS can view their own assignments
CREATE POLICY "cs_assignments_select_own" ON cs_assignments
    FOR SELECT USING (
        cs_code = (SELECT cs_code FROM auth.users WHERE id = auth.uid())
    );

-- CS can update their own assignments
CREATE POLICY "cs_assignments_update_own" ON cs_assignments
    FOR UPDATE USING (
        cs_code = (SELECT cs_code FROM auth.users WHERE id = auth.uid())
    );

-- CS can insert their own assignments
CREATE POLICY "cs_assignments_insert_own" ON cs_assignments
    FOR INSERT WITH CHECK (
        cs_code = (SELECT cs_code FROM auth.users WHERE id = auth.uid())
    );

-- Startups can view assignments for their startup
CREATE POLICY "cs_assignments_select_startup" ON cs_assignments
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM public.startups WHERE user_id = auth.uid()
        )
    );

-- 8. Recreate the create_cs_assignment_request function
DROP FUNCTION IF EXISTS create_cs_assignment_request(BIGINT, TEXT, VARCHAR(20), TEXT);

CREATE OR REPLACE FUNCTION create_cs_assignment_request(
    startup_id_param BIGINT,
    startup_name_param TEXT,
    cs_code_param VARCHAR(20),
    notes_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    cs_exists BOOLEAN;
    request_exists BOOLEAN;
BEGIN
    -- Debug logging
    RAISE NOTICE 'Creating CS assignment request: startup_id=%, startup_name=%, cs_code=%, notes=%', 
        startup_id_param, startup_name_param, cs_code_param, notes_param;
    
    -- Check if CS code exists in auth.users
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE cs_code = cs_code_param AND role = 'CS') INTO cs_exists;
    IF NOT cs_exists THEN
        RAISE NOTICE 'CS code % not found or user is not a CS', cs_code_param;
        RETURN FALSE;
    END IF;
    
    -- Check if request already exists
    SELECT EXISTS(
        SELECT 1 FROM public.cs_assignment_requests 
        WHERE startup_id = startup_id_param 
        AND cs_code = cs_code_param 
        AND status = 'pending'
    ) INTO request_exists;
    
    IF request_exists THEN
        RAISE NOTICE 'Request already exists for startup % and CS %', startup_id_param, cs_code_param;
        RETURN FALSE;
    END IF;
    
    -- Create the request
    INSERT INTO public.cs_assignment_requests (
        startup_id, startup_name, cs_code, notes
    ) VALUES (
        startup_id_param, startup_name_param, cs_code_param, notes_param
    );
    
    RAISE NOTICE 'CS assignment request created successfully';
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating CS assignment request: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Grant execute permissions
GRANT EXECUTE ON FUNCTION create_cs_assignment_request(BIGINT, TEXT, VARCHAR(20), TEXT) TO authenticated;

-- 10. Test the function
DO $$
DECLARE
    test_startup_id BIGINT;
    test_cs_code VARCHAR;
    result BOOLEAN;
BEGIN
    RAISE NOTICE '=== Testing Fixed CS Request Creation ===';
    
    -- Get a startup ID
    SELECT id INTO test_startup_id FROM startups LIMIT 1;
    
    -- Get the CS code from auth.users
    SELECT cs_code INTO test_cs_code FROM auth.users WHERE email = 'network@startupnationindia.com';
    
    IF test_startup_id IS NOT NULL AND test_cs_code IS NOT NULL THEN
        RAISE NOTICE 'Testing with startup ID: %, CS code: %', test_startup_id, test_cs_code;
        
        -- Test the function
        SELECT create_cs_assignment_request(test_startup_id, 'Test Startup', test_cs_code, 'Test request from script') INTO result;
        
        RAISE NOTICE 'Request creation result: %', result;
        
        -- Check if request was created
        IF EXISTS (SELECT 1 FROM cs_assignment_requests WHERE startup_id = test_startup_id AND cs_code = test_cs_code) THEN
            RAISE NOTICE '✅ Request successfully created!';
        ELSE
            RAISE NOTICE '❌ Request was not created';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ Missing startup ID or CS code for testing';
        RAISE NOTICE 'Startup ID: %, CS Code: %', test_startup_id, test_cs_code;
    END IF;
    
    RAISE NOTICE '=== Test Complete ===';
END $$;

