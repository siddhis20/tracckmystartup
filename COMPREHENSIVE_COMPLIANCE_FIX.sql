-- =====================================================
-- COMPREHENSIVE COMPLIANCE FIX
-- =====================================================
-- This script fixes all compliance-related database issues
-- Run this in your Supabase SQL Editor

-- =====================================================
-- STEP 1: CHECK CURRENT DATABASE STRUCTURE
-- =====================================================

-- Check if startups table has compliance_status column
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name = 'compliance_status';

-- =====================================================
-- STEP 2: ADD COMPLIANCE STATUS COLUMN IF MISSING
-- =====================================================

-- Add compliance_status column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'startups' AND column_name = 'compliance_status'
    ) THEN
        ALTER TABLE public.startups ADD COLUMN compliance_status VARCHAR(20) DEFAULT 'Pending';
        RAISE NOTICE 'Added compliance_status column to startups table';
    ELSE
        RAISE NOTICE 'compliance_status column already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 3: UPDATE EXISTING RECORDS
-- =====================================================

-- Update existing startups to have a compliance status if they don't have one
UPDATE public.startups 
SET compliance_status = 'Pending' 
WHERE compliance_status IS NULL;

-- =====================================================
-- STEP 4: CHECK CA ASSIGNMENTS TABLE
-- =====================================================

-- Check if ca_assignments table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'ca_assignments'
) as ca_assignments_exists;

-- =====================================================
-- STEP 5: CREATE CA ASSIGNMENTS TABLE IF MISSING
-- =====================================================

CREATE TABLE IF NOT EXISTS public.ca_assignments (
    id SERIAL PRIMARY KEY,
    ca_code VARCHAR(50) NOT NULL,
    startup_id INTEGER NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    assignment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(ca_code, startup_id)
);

-- =====================================================
-- STEP 6: CREATE CA ASSIGNMENT REQUESTS TABLE IF MISSING
-- =====================================================

CREATE TABLE IF NOT EXISTS public.ca_assignment_requests (
    id SERIAL PRIMARY KEY,
    ca_code VARCHAR(50) NOT NULL,
    startup_id INTEGER NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    notes TEXT,
    rejection_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 7: CREATE NECESSARY FUNCTIONS
-- =====================================================

-- Function to get CA startups
CREATE OR REPLACE FUNCTION public.get_ca_startups(ca_code_param VARCHAR(50))
RETURNS TABLE (
    startup_id INTEGER,
    startup_name TEXT,
    assignment_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ca.startup_id,
        s.name as startup_name,
        ca.assignment_date,
        ca.status
    FROM public.ca_assignments ca
    JOIN public.startups s ON ca.startup_id = s.id
    WHERE ca.ca_code = ca_code_param
    AND ca.status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to assign CA to startup
CREATE OR REPLACE FUNCTION public.assign_ca_to_startup(
    ca_code_param VARCHAR(50),
    startup_id_param INTEGER,
    notes_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO public.ca_assignments (ca_code, startup_id, notes)
    VALUES (ca_code_param, startup_id_param, notes_param)
    ON CONFLICT (ca_code, startup_id) 
    DO UPDATE SET 
        status = 'active',
        notes = COALESCE(notes_param, ca_assignments.notes),
        updated_at = NOW();
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove CA assignment
CREATE OR REPLACE FUNCTION public.remove_ca_assignment(
    ca_code_param VARCHAR(50),
    startup_id_param INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.ca_assignments 
    SET status = 'inactive', updated_at = NOW()
    WHERE ca_code = ca_code_param AND startup_id = startup_id_param;
    
    RETURN FOUND;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get CA assignment requests
CREATE OR REPLACE FUNCTION public.get_ca_assignment_requests(ca_code_param VARCHAR(50))
RETURNS TABLE (
    id INTEGER,
    startup_id INTEGER,
    startup_name TEXT,
    request_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20),
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        car.id,
        car.startup_id,
        s.name as startup_name,
        car.request_date,
        car.status,
        car.notes
    FROM public.ca_assignment_requests car
    JOIN public.startups s ON car.startup_id = s.id
    WHERE car.ca_code = ca_code_param
    AND car.status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to approve CA assignment request
CREATE OR REPLACE FUNCTION public.approve_ca_assignment_request(
    request_id_param INTEGER,
    ca_code_param VARCHAR(50)
)
RETURNS BOOLEAN AS $$
DECLARE
    startup_id_val INTEGER;
BEGIN
    -- Get the startup ID from the request
    SELECT startup_id INTO startup_id_val
    FROM public.ca_assignment_requests
    WHERE id = request_id_param AND ca_code = ca_code_param;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Update the request status
    UPDATE public.ca_assignment_requests 
    SET status = 'approved', updated_at = NOW()
    WHERE id = request_id_param;
    
    -- Create the assignment
    INSERT INTO public.ca_assignments (ca_code, startup_id, status)
    VALUES (ca_code_param, startup_id_val, 'active')
    ON CONFLICT (ca_code, startup_id) 
    DO UPDATE SET status = 'active', updated_at = NOW();
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reject CA assignment request
CREATE OR REPLACE FUNCTION public.reject_ca_assignment_request(
    request_id_param INTEGER,
    ca_code_param VARCHAR(50),
    rejection_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.ca_assignment_requests 
    SET status = 'rejected', rejection_notes = rejection_notes, updated_at = NOW()
    WHERE id = request_id_param AND ca_code = ca_code_param;
    
    RETURN FOUND;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 8: SET UP RLS POLICIES
-- =====================================================

-- Enable RLS on ca_assignments
ALTER TABLE public.ca_assignments ENABLE ROW LEVEL SECURITY;

-- Policy for CA assignments (CAs can see their own assignments)
CREATE POLICY "CAs can view their own assignments" ON public.ca_assignments
    FOR SELECT USING (
        ca_code IN (
            SELECT ca_code FROM public.users 
            WHERE id = auth.uid()
        )
    );

-- Policy for CA assignments (CAs can insert their own assignments)
CREATE POLICY "CAs can create their own assignments" ON public.ca_assignments
    FOR INSERT WITH CHECK (
        ca_code IN (
            SELECT ca_code FROM public.users 
            WHERE id = auth.uid()
        )
    );

-- Policy for CA assignments (CAs can update their own assignments)
CREATE POLICY "CAs can update their own assignments" ON public.ca_assignments
    FOR UPDATE USING (
        ca_code IN (
            SELECT ca_code FROM public.users 
            WHERE id = auth.uid()
        )
    );

-- Enable RLS on ca_assignment_requests
ALTER TABLE public.ca_assignment_requests ENABLE ROW LEVEL SECURITY;

-- Policy for CA assignment requests (CAs can see requests for them)
CREATE POLICY "CAs can view requests for them" ON public.ca_assignment_requests
    FOR SELECT USING (
        ca_code IN (
            SELECT ca_code FROM public.users 
            WHERE id = auth.uid()
        )
    );

-- Policy for CA assignment requests (CAs can update requests for them)
CREATE POLICY "CAs can update requests for them" ON public.ca_assignment_requests
    FOR UPDATE USING (
        ca_code IN (
            SELECT ca_code FROM public.users 
            WHERE id = auth.uid()
        )
    );

-- =====================================================
-- STEP 9: VERIFY THE FIX
-- =====================================================

-- Check the final state
SELECT 
    'Startups with compliance status' as check_type,
    COUNT(*) as count
FROM public.startups 
WHERE compliance_status IS NOT NULL

UNION ALL

SELECT 
    'CA assignments' as check_type,
    COUNT(*) as count
FROM public.ca_assignments

UNION ALL

SELECT 
    'CA assignment requests' as check_type,
    COUNT(*) as count
FROM public.ca_assignment_requests;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT '✅ Comprehensive Compliance Fix Complete!' as status;
