-- =====================================================
-- CA CODE SYSTEM SETUP FOR STARTUP NATION APP
-- =====================================================
-- This script sets up the CA code system similar to investor codes
-- Run this in your Supabase SQL Editor

-- =====================================================
-- STEP 1: ADD CA CODE COLUMN TO USERS TABLE
-- =====================================================

-- Add ca_code column to users table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'ca_code'
    ) THEN
        ALTER TABLE public.users ADD COLUMN ca_code VARCHAR(20) UNIQUE;
    END IF;
END $$;

-- =====================================================
-- STEP 2: CREATE CA CODE GENERATION FUNCTION
-- =====================================================

-- Function to generate unique CA code
CREATE OR REPLACE FUNCTION generate_ca_code()
RETURNS VARCHAR(20) AS $$
DECLARE
    new_code VARCHAR(20);
    counter INTEGER := 1;
BEGIN
    LOOP
        -- Generate code in format CA-XXXXXX (6 random alphanumeric characters)
        new_code := 'CA-' || upper(substring(md5(random()::text) from 1 for 6));
        
        -- Check if code already exists
        IF NOT EXISTS (SELECT 1 FROM public.users WHERE ca_code = new_code) THEN
            RETURN new_code;
        END IF;
        
        counter := counter + 1;
        IF counter > 100 THEN
            RAISE EXCEPTION 'Unable to generate unique CA code after 100 attempts';
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 3: CREATE TRIGGER TO AUTO-GENERATE CA CODE
-- =====================================================

-- Function to handle CA code generation on user creation
CREATE OR REPLACE FUNCTION handle_ca_code_generation()
RETURNS TRIGGER AS $$
BEGIN
    -- Only generate CA code for users with CA role
    IF NEW.role = 'CA' AND NEW.ca_code IS NULL THEN
        NEW.ca_code := generate_ca_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for CA code generation
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_generate_ca_code'
    ) THEN
        CREATE TRIGGER trigger_generate_ca_code
            BEFORE INSERT ON public.users
            FOR EACH ROW
            EXECUTE FUNCTION handle_ca_code_generation();
    END IF;
END $$;

-- =====================================================
-- STEP 4: CREATE CA ASSIGNMENT TABLE
-- =====================================================

-- Table to track CA assignments to startups
CREATE TABLE IF NOT EXISTS ca_assignments (
    id SERIAL PRIMARY KEY,
    ca_code VARCHAR(20) NOT NULL REFERENCES public.users(ca_code),
    startup_id INTEGER NOT NULL REFERENCES public.startups(id),
    assignment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(ca_code, startup_id)
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ca_assignments_ca_code ON ca_assignments(ca_code);
CREATE INDEX IF NOT EXISTS idx_ca_assignments_startup_id ON ca_assignments(startup_id);
CREATE INDEX IF NOT EXISTS idx_ca_assignments_status ON ca_assignments(status);

-- =====================================================
-- STEP 5: ENABLE RLS ON CA ASSIGNMENTS TABLE
-- =====================================================

ALTER TABLE ca_assignments ENABLE ROW LEVEL SECURITY;

-- Policy: CA users can see their own assignments
CREATE POLICY "ca_assignments_select_own" ON ca_assignments
    FOR SELECT USING (
        ca_code = (SELECT ca_code FROM public.users WHERE id = auth.uid())
    );

-- Policy: CA users can update their own assignments
CREATE POLICY "ca_assignments_update_own" ON ca_assignments
    FOR UPDATE USING (
        ca_code = (SELECT ca_code FROM public.users WHERE id = auth.uid())
    );

-- Policy: Admins can manage all assignments
CREATE POLICY "ca_assignments_admin_all" ON ca_assignments
    FOR ALL USING (
        (SELECT role FROM public.users WHERE id = auth.uid()) = 'Admin'
    );

-- Policy: Startups can see assignments for their startup
CREATE POLICY "ca_assignments_startup_view" ON ca_assignments
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- STEP 6: CREATE HELPER FUNCTIONS
-- =====================================================

-- Function to get startups assigned to a CA
CREATE OR REPLACE FUNCTION get_ca_startups(ca_code_param VARCHAR(20))
RETURNS TABLE (
    startup_id INTEGER,
    startup_name VARCHAR(255),
    assignment_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        ca.assignment_date,
        ca.status
    FROM ca_assignments ca
    JOIN public.startups s ON ca.startup_id = s.id
    WHERE ca.ca_code = ca_code_param
    ORDER BY ca.assignment_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to assign CA to startup
CREATE OR REPLACE FUNCTION assign_ca_to_startup(
    ca_code_param VARCHAR(20),
    startup_id_param INTEGER,
    notes_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO ca_assignments (ca_code, startup_id, notes)
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
CREATE OR REPLACE FUNCTION remove_ca_assignment(
    ca_code_param VARCHAR(20),
    startup_id_param INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE ca_assignments 
    SET status = 'inactive', updated_at = NOW()
    WHERE ca_code = ca_code_param AND startup_id = startup_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 7: UPDATE EXISTING CA USERS WITH CODES
-- =====================================================

-- Generate CA codes for existing CA users who don't have one
UPDATE public.users 
SET ca_code = generate_ca_code()
WHERE role = 'CA' AND ca_code IS NULL;

-- =====================================================
-- STEP 8: VERIFICATION QUERIES
-- =====================================================

-- Test CA code generation
SELECT 'CA Code Generation Test' as test_name, generate_ca_code() as generated_code;

-- Check existing CA users and their codes
SELECT 
    name,
    email,
    role,
    ca_code,
    CASE 
        WHEN ca_code IS NOT NULL THEN '✅ Has CA Code'
        ELSE '❌ Missing CA Code'
    END as status
FROM public.users 
WHERE role = 'CA'
ORDER BY name;

-- Check CA assignments table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'ca_assignments'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 9: SAMPLE DATA (OPTIONAL)
-- =====================================================

-- Insert sample CA assignments (uncomment if needed)
/*
INSERT INTO ca_assignments (ca_code, startup_id, notes) VALUES
('CA-A1B2C3', 1, 'Primary CA for financial compliance'),
('CA-A1B2C3', 2, 'Secondary assignment for audit support'),
('CA-D4E5F6', 3, 'Tax compliance specialist');
*/

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT '✅ CA Code System Setup Complete!' as status;
