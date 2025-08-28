-- =====================================================
-- CA ASSIGNMENT REQUEST SYSTEM SETUP
-- =====================================================
-- This script sets up CA assignment requests similar to investor startup requests
-- Run this in your Supabase SQL Editor

-- =====================================================
-- STEP 1: CREATE CA ASSIGNMENT REQUESTS TABLE
-- =====================================================

-- Table to track CA assignment requests from startups
CREATE TABLE IF NOT EXISTS ca_assignment_requests (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES public.startups(id),
    startup_name VARCHAR(255) NOT NULL,
    ca_code VARCHAR(20) NOT NULL REFERENCES public.users(ca_code),
    request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(startup_id, ca_code, status)
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ca_assignment_requests_ca_code ON ca_assignment_requests(ca_code);
CREATE INDEX IF NOT EXISTS idx_ca_assignment_requests_startup_id ON ca_assignment_requests(startup_id);
CREATE INDEX IF NOT EXISTS idx_ca_assignment_requests_status ON ca_assignment_requests(status);

-- =====================================================
-- STEP 2: ENABLE RLS ON CA ASSIGNMENT REQUESTS TABLE
-- =====================================================

ALTER TABLE ca_assignment_requests ENABLE ROW LEVEL SECURITY;

-- Policy: CA users can see requests for their CA code
CREATE POLICY "ca_assignment_requests_select_own" ON ca_assignment_requests
    FOR SELECT USING (
        ca_code = (SELECT ca_code FROM public.users WHERE id = auth.uid())
    );

-- Policy: CA users can update requests for their CA code
CREATE POLICY "ca_assignment_requests_update_own" ON ca_assignment_requests
    FOR UPDATE USING (
        ca_code = (SELECT ca_code FROM public.users WHERE id = auth.uid())
    );

-- Policy: Startups can insert requests for their startup
CREATE POLICY "ca_assignment_requests_insert_startup" ON ca_assignment_requests
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Startups can see their own requests
CREATE POLICY "ca_assignment_requests_select_startup" ON ca_assignment_requests
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Admins can manage all requests
CREATE POLICY "ca_assignment_requests_admin_all" ON ca_assignment_requests
    FOR ALL USING (
        (SELECT role FROM public.users WHERE id = auth.uid()) = 'Admin'
    );

-- =====================================================
-- STEP 3: CREATE HELPER FUNCTIONS
-- =====================================================

-- Function to create CA assignment request
CREATE OR REPLACE FUNCTION create_ca_assignment_request(
    startup_id_param INTEGER,
    ca_code_param VARCHAR(20),
    notes_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    startup_name_val VARCHAR(255);
BEGIN
    -- Get startup name
    SELECT name INTO startup_name_val 
    FROM public.startups 
    WHERE id = startup_id_param;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Insert the request
    INSERT INTO ca_assignment_requests (startup_id, startup_name, ca_code, notes)
    VALUES (startup_id_param, startup_name_val, ca_code_param, notes_param)
    ON CONFLICT (startup_id, ca_code, status) 
    DO UPDATE SET 
        notes = COALESCE(notes_param, ca_assignment_requests.notes),
        updated_at = NOW();
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to approve CA assignment request
CREATE OR REPLACE FUNCTION approve_ca_assignment_request(
    request_id_param INTEGER,
    ca_code_param VARCHAR(20)
)
RETURNS BOOLEAN AS $$
DECLARE
    request_record RECORD;
BEGIN
    -- Get the request
    SELECT * INTO request_record 
    FROM ca_assignment_requests 
    WHERE id = request_id_param AND ca_code = ca_code_param AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Update request status to approved
    UPDATE ca_assignment_requests 
    SET status = 'approved', updated_at = NOW()
    WHERE id = request_id_param;
    
    -- Create the actual assignment
    INSERT INTO ca_assignments (ca_code, startup_id, notes, status)
    VALUES (ca_code_param, request_record.startup_id, request_record.notes, 'active')
    ON CONFLICT (ca_code, startup_id) 
    DO UPDATE SET 
        status = 'active',
        notes = COALESCE(request_record.notes, ca_assignments.notes),
        updated_at = NOW();
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reject CA assignment request
CREATE OR REPLACE FUNCTION reject_ca_assignment_request(
    request_id_param INTEGER,
    ca_code_param VARCHAR(20),
    rejection_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE ca_assignment_requests 
    SET status = 'rejected', notes = COALESCE(rejection_notes, notes), updated_at = NOW()
    WHERE id = request_id_param AND ca_code = ca_code_param AND status = 'pending';
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending CA assignment requests for a CA
CREATE OR REPLACE FUNCTION get_ca_assignment_requests(ca_code_param VARCHAR(20))
RETURNS TABLE (
    id INTEGER,
    startup_id INTEGER,
    startup_name VARCHAR(255),
    request_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20),
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        car.id,
        car.startup_id,
        car.startup_name,
        car.request_date,
        car.status,
        car.notes
    FROM ca_assignment_requests car
    WHERE car.ca_code = ca_code_param
    ORDER BY car.request_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 4: CREATE TRIGGER FOR CA CODE ASSIGNMENT
-- =====================================================

-- Function to handle CA code assignment when startup updates profile
CREATE OR REPLACE FUNCTION handle_ca_code_assignment()
RETURNS TRIGGER AS $$
BEGIN
    -- If CA service code is being set and it's different from before
    IF NEW.ca_service_code IS NOT NULL AND 
       (OLD.ca_service_code IS NULL OR NEW.ca_service_code != OLD.ca_service_code) THEN
        
        -- Create assignment request
        PERFORM create_ca_assignment_request(
            NEW.id, 
            NEW.ca_service_code, 
            'CA assignment requested via startup profile update'
        );
        
        RAISE NOTICE 'CA assignment request created for startup % with CA code %', NEW.name, NEW.ca_service_code;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for CA code assignment
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_ca_code_assignment'
    ) THEN
        CREATE TRIGGER trigger_ca_code_assignment
            AFTER UPDATE ON public.startups
            FOR EACH ROW
            EXECUTE FUNCTION handle_ca_code_assignment();
    END IF;
END $$;

-- =====================================================
-- STEP 5: VERIFICATION QUERIES
-- =====================================================

-- Check CA assignment requests table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'ca_assignment_requests'
ORDER BY ordinal_position;

-- Test CA assignment request creation
SELECT 'CA Assignment Request System Setup Complete!' as status;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT '✅ CA Assignment Request System Setup Complete!' as status;
