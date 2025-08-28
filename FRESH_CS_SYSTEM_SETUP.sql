-- Fresh CS System Setup
-- This creates a clean, properly designed CS assignment system

-- Step 1: Add CS code column to users table
-- =====================================================
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS cs_code VARCHAR(20) UNIQUE;

-- Step 2: Create CS assignments table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.cs_assignments (
    id SERIAL PRIMARY KEY,
    cs_code VARCHAR(20) NOT NULL REFERENCES public.users(cs_code),
    startup_id BIGINT NOT NULL REFERENCES public.startups(id),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    assignment_date TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique active assignments
    UNIQUE(cs_code, startup_id, status)
);

-- Step 3: Create CS assignment requests table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.cs_assignment_requests (
    id SERIAL PRIMARY KEY,
    startup_id BIGINT NOT NULL REFERENCES public.startups(id),
    startup_name TEXT NOT NULL,
    cs_code VARCHAR(20) NOT NULL REFERENCES public.users(cs_code),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    notes TEXT,
    request_date TIMESTAMPTZ DEFAULT NOW(),
    response_date TIMESTAMPTZ,
    response_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 4: Create indexes for performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_cs_assignments_cs_code ON public.cs_assignments(cs_code);
CREATE INDEX IF NOT EXISTS idx_cs_assignments_startup_id ON public.cs_assignments(startup_id);
CREATE INDEX IF NOT EXISTS idx_cs_assignments_status ON public.cs_assignments(status);

CREATE INDEX IF NOT EXISTS idx_cs_assignment_requests_cs_code ON public.cs_assignment_requests(cs_code);
CREATE INDEX IF NOT EXISTS idx_cs_assignment_requests_startup_id ON public.cs_assignment_requests(startup_id);
CREATE INDEX IF NOT EXISTS idx_cs_assignment_requests_status ON public.cs_assignment_requests(status);

-- Step 5: Create CS code generation function
-- =====================================================
CREATE OR REPLACE FUNCTION public.generate_cs_code()
RETURNS VARCHAR(20) AS $$
DECLARE
    new_code VARCHAR(20);
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a random 6-digit code
        new_code := 'CS-' || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM public.users WHERE cs_code = new_code) INTO code_exists;
        
        -- If code doesn't exist, return it
        IF NOT code_exists THEN
            RETURN new_code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create trigger to auto-generate CS codes
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_cs_code_generation()
RETURNS TRIGGER AS $$
BEGIN
    -- Only generate CS code if user is a CS and doesn't have one
    IF NEW.role = 'CS' AND (NEW.cs_code IS NULL OR NEW.cs_code = '') THEN
        NEW.cs_code := public.generate_cs_code();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_cs_code
    BEFORE INSERT OR UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_cs_code_generation();

-- Step 7: Create function to get CS assignments
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_cs_startups(cs_code_param VARCHAR(20))
RETURNS TABLE (
    startup_id BIGINT,
    startup_name TEXT,
    assignment_date TIMESTAMPTZ,
    status TEXT,
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ca.startup_id,
        s.name AS startup_name,
        ca.assignment_date,
        ca.status,
        ca.notes
    FROM public.cs_assignments ca
    JOIN public.startups s ON s.id = ca.startup_id
    WHERE ca.cs_code = cs_code_param
    AND ca.status = 'active'
    ORDER BY ca.assignment_date DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- Step 8: Create function to create assignment request
-- =====================================================
CREATE OR REPLACE FUNCTION public.create_cs_assignment_request(
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
    -- Check if CS code exists
    SELECT EXISTS(SELECT 1 FROM public.users WHERE cs_code = cs_code_param AND role = 'CS') INTO cs_exists;
    IF NOT cs_exists THEN
        RAISE EXCEPTION 'Invalid CS code or user is not a CS';
    END IF;
    
    -- Check if request already exists
    SELECT EXISTS(
        SELECT 1 FROM public.cs_assignment_requests 
        WHERE startup_id = startup_id_param 
        AND cs_code = cs_code_param 
        AND status = 'pending'
    ) INTO request_exists;
    
    IF request_exists THEN
        RAISE EXCEPTION 'Assignment request already exists';
    END IF;
    
    -- Create the request
    INSERT INTO public.cs_assignment_requests (
        startup_id, startup_name, cs_code, notes
    ) VALUES (
        startup_id_param, startup_name_param, cs_code_param, notes_param
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 9: Create function to get assignment requests for CS
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_cs_assignment_requests(cs_code_param VARCHAR(20))
RETURNS TABLE (
    id INTEGER,
    startup_id BIGINT,
    startup_name TEXT,
    cs_code VARCHAR(20),
    status TEXT,
    notes TEXT,
    request_date TIMESTAMPTZ,
    response_date TIMESTAMPTZ,
    response_notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        car.id,
        car.startup_id,
        car.startup_name,
        car.cs_code,
        car.status,
        car.notes,
        car.request_date,
        car.response_date,
        car.response_notes
    FROM public.cs_assignment_requests car
    WHERE car.cs_code = cs_code_param
    ORDER BY car.request_date DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- Step 10: Create function to approve assignment request
-- =====================================================
CREATE OR REPLACE FUNCTION public.approve_cs_assignment_request(
    request_id_param INTEGER,
    cs_code_param VARCHAR(20),
    response_notes_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    request_record RECORD;
BEGIN
    -- Get the request
    SELECT * INTO request_record 
    FROM public.cs_assignment_requests 
    WHERE id = request_id_param AND cs_code = cs_code_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request not found or not authorized';
    END IF;
    
    IF request_record.status != 'pending' THEN
        RAISE EXCEPTION 'Request is not pending';
    END IF;
    
    -- Update request status
    UPDATE public.cs_assignment_requests 
    SET 
        status = 'approved',
        response_date = NOW(),
        response_notes = response_notes_param
    WHERE id = request_id_param;
    
    -- Create assignment
    INSERT INTO public.cs_assignments (
        cs_code, startup_id, status, notes
    ) VALUES (
        cs_code_param, request_record.startup_id, 'active', 
        COALESCE(response_notes_param, 'Approved assignment request')
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 11: Create function to reject assignment request
-- =====================================================
CREATE OR REPLACE FUNCTION public.reject_cs_assignment_request(
    request_id_param INTEGER,
    cs_code_param VARCHAR(20),
    response_notes_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    request_record RECORD;
BEGIN
    -- Get the request
    SELECT * INTO request_record 
    FROM public.cs_assignment_requests 
    WHERE id = request_id_param AND cs_code = cs_code_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request not found or not authorized';
    END IF;
    
    IF request_record.status != 'pending' THEN
        RAISE EXCEPTION 'Request is not pending';
    END IF;
    
    -- Update request status
    UPDATE public.cs_assignment_requests 
    SET 
        status = 'rejected',
        response_date = NOW(),
        response_notes = response_notes_param
    WHERE id = request_id_param;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 12: Create function to get startup's CS requests
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_startup_cs_requests(startup_id_param BIGINT)
RETURNS TABLE (
    id INTEGER,
    startup_id BIGINT,
    startup_name TEXT,
    cs_code VARCHAR(20),
    status TEXT,
    notes TEXT,
    request_date TIMESTAMPTZ,
    response_date TIMESTAMPTZ,
    response_notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        car.id,
        car.startup_id,
        car.startup_name,
        car.cs_code,
        car.status,
        car.notes,
        car.request_date,
        car.response_date,
        car.response_notes
    FROM public.cs_assignment_requests car
    WHERE car.startup_id = startup_id_param
    ORDER BY car.request_date DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- Step 13: Set up Row Level Security (RLS)
-- =====================================================
ALTER TABLE public.cs_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cs_assignment_requests ENABLE ROW LEVEL SECURITY;

-- CS assignments policies
CREATE POLICY cs_assignments_select_own ON public.cs_assignments
    FOR SELECT USING (cs_code IN (
        SELECT cs_code FROM public.users WHERE id = auth.uid()
    ));

CREATE POLICY cs_assignments_insert_own ON public.cs_assignments
    FOR INSERT WITH CHECK (cs_code IN (
        SELECT cs_code FROM public.users WHERE id = auth.uid()
    ));

CREATE POLICY cs_assignments_update_own ON public.cs_assignments
    FOR UPDATE USING (cs_code IN (
        SELECT cs_code FROM public.users WHERE id = auth.uid()
    ));

-- CS assignment requests policies
CREATE POLICY cs_assignment_requests_select_own ON public.cs_assignment_requests
    FOR SELECT USING (
        cs_code IN (SELECT cs_code FROM public.users WHERE id = auth.uid()) OR
        startup_id IN (SELECT id FROM public.startups WHERE user_id = auth.uid())
    );

CREATE POLICY cs_assignment_requests_insert_own ON public.cs_assignment_requests
    FOR INSERT WITH CHECK (
        startup_id IN (SELECT id FROM public.startups WHERE user_id = auth.uid())
    );

CREATE POLICY cs_assignment_requests_update_own ON public.cs_assignment_requests
    FOR UPDATE USING (
        cs_code IN (SELECT cs_code FROM public.users WHERE id = auth.uid()) OR
        startup_id IN (SELECT id FROM public.startups WHERE user_id = auth.uid())
    );

-- Step 14: Grant permissions
-- =====================================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.cs_assignments TO authenticated;
GRANT ALL ON public.cs_assignment_requests TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

GRANT EXECUTE ON FUNCTION public.generate_cs_code() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_cs_code_generation() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_cs_startups(VARCHAR(20)) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_cs_assignment_request(BIGINT, TEXT, VARCHAR(20), TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_cs_assignment_requests(VARCHAR(20)) TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_cs_assignment_request(INTEGER, VARCHAR(20), TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_cs_assignment_request(INTEGER, VARCHAR(20), TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_startup_cs_requests(BIGINT) TO authenticated;

-- Step 15: Generate CS codes for existing CS users
-- =====================================================
UPDATE public.users 
SET cs_code = public.generate_cs_code()
WHERE role = 'CS' AND (cs_code IS NULL OR cs_code = '');

-- Step 16: Verification
-- =====================================================
SELECT 
    'CS System Setup Complete' as status,
    'All tables, functions, and policies have been created' as message;

-- Check what was created
SELECT 
    'Tables' as type,
    COUNT(*) as count
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('cs_assignments', 'cs_assignment_requests')
UNION ALL
SELECT 
    'Functions' as type,
    COUNT(*) as count
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%cs%';
