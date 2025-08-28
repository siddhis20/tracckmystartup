-- =====================================================
-- INCUBATION & ACCELERATION PROGRAMS BACKEND SETUP
-- =====================================================
-- This script sets up the backend for incubation and acceleration programs

-- Create incubation_programs table
CREATE TABLE IF NOT EXISTS incubation_programs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    program_name TEXT NOT NULL,
    program_type TEXT NOT NULL CHECK (program_type IN ('Incubation', 'Acceleration', 'Mentorship', 'Bootcamp')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Completed', 'Dropped')),
    description TEXT,
    mentor_name TEXT,
    mentor_email TEXT,
    program_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_incubation_programs_startup_id ON incubation_programs(startup_id);
CREATE INDEX IF NOT EXISTS idx_incubation_programs_program_type ON incubation_programs(program_type);
CREATE INDEX IF NOT EXISTS idx_incubation_programs_status ON incubation_programs(status);
CREATE INDEX IF NOT EXISTS idx_incubation_programs_dates ON incubation_programs(start_date, end_date);

-- Create updated_at trigger
DROP TRIGGER IF EXISTS update_incubation_programs_updated_at ON incubation_programs;
CREATE TRIGGER update_incubation_programs_updated_at
    BEFORE UPDATE ON incubation_programs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE incubation_programs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own startup's incubation programs" ON incubation_programs;
CREATE POLICY "Users can view their own startup's incubation programs" ON incubation_programs
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

DROP POLICY IF EXISTS "Startup users can manage their own incubation programs" ON incubation_programs;
CREATE POLICY "Startup users can manage their own incubation programs" ON incubation_programs
    FOR ALL USING (
        startup_id IN (
            SELECT id FROM startups 
            WHERE name IN (
                SELECT startup_name FROM users 
                WHERE email = auth.jwt() ->> 'email'
            )
        )
    );

-- Create RPC functions for incubation programs
CREATE OR REPLACE FUNCTION get_incubation_programs(p_startup_id INTEGER)
RETURNS TABLE (
    id UUID,
    program_name TEXT,
    program_type TEXT,
    start_date DATE,
    end_date DATE,
    status TEXT,
    description TEXT,
    mentor_name TEXT,
    mentor_email TEXT,
    program_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ip.id,
        ip.program_name,
        ip.program_type,
        ip.start_date,
        ip.end_date,
        ip.status,
        ip.description,
        ip.mentor_name,
        ip.mentor_email,
        ip.program_url,
        ip.created_at
    FROM incubation_programs ip
    WHERE ip.startup_id = p_startup_id
    ORDER BY ip.start_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION add_incubation_program(
    p_startup_id INTEGER,
    p_program_name TEXT,
    p_program_type TEXT,
    p_start_date DATE,
    p_end_date DATE,
    p_description TEXT DEFAULT NULL,
    p_mentor_name TEXT DEFAULT NULL,
    p_mentor_email TEXT DEFAULT NULL,
    p_program_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_id UUID;
BEGIN
    INSERT INTO incubation_programs (
        startup_id,
        program_name,
        program_type,
        start_date,
        end_date,
        description,
        mentor_name,
        mentor_email,
        program_url
    ) VALUES (
        p_startup_id,
        p_program_name,
        p_program_type,
        p_start_date,
        p_end_date,
        p_description,
        p_mentor_name,
        p_mentor_email,
        p_program_url
    ) RETURNING id INTO new_id;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION update_incubation_program(
    p_id UUID,
    p_program_name TEXT,
    p_program_type TEXT,
    p_start_date DATE,
    p_end_date DATE,
    p_status TEXT,
    p_description TEXT DEFAULT NULL,
    p_mentor_name TEXT DEFAULT NULL,
    p_mentor_email TEXT DEFAULT NULL,
    p_program_url TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE incubation_programs SET
        program_name = p_program_name,
        program_type = p_program_type,
        start_date = p_start_date,
        end_date = p_end_date,
        status = p_status,
        description = p_description,
        mentor_name = p_mentor_name,
        mentor_email = p_mentor_email,
        program_url = p_program_url,
        updated_at = NOW()
    WHERE id = p_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION delete_incubation_program(p_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM incubation_programs WHERE id = p_id;
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert sample data (only if no programs exist for the startup)
DO $$
DECLARE
    sample_startup_id INTEGER;
BEGIN
    -- Get a startup ID for sample data
    SELECT id INTO sample_startup_id FROM startups LIMIT 1;
    
    IF sample_startup_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM incubation_programs WHERE startup_id = sample_startup_id
    ) THEN
        INSERT INTO incubation_programs (
            startup_id,
            program_name,
            program_type,
            start_date,
            end_date,
            status,
            description,
            mentor_name,
            mentor_email
        ) VALUES 
        (
            sample_startup_id,
            'Y Combinator',
            'Acceleration',
            '2024-01-10',
            '2024-04-10',
            'Active',
            'Intensive 3-month acceleration program',
            'Paul Graham',
            'paul@ycombinator.com'
        ),
        (
            sample_startup_id,
            'Techstars',
            'Acceleration',
            '2024-03-01',
            '2024-06-01',
            'Active',
            'Global startup accelerator',
            'David Cohen',
            'david@techstars.com'
        ),
        (
            sample_startup_id,
            '500 Global',
            'Acceleration',
            '2024-02-15',
            '2024-05-15',
            'Completed',
            'Early-stage startup accelerator',
            'Christine Tsai',
            'christine@500.co'
        );
        
        RAISE NOTICE 'Sample incubation programs added for startup ID: %', sample_startup_id;
    END IF;
END
$$;
