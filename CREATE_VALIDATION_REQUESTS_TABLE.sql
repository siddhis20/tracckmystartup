-- CREATE_VALIDATION_REQUESTS_TABLE.sql
-- Create table for startup validation requests

-- 1. Create validation_requests table
CREATE TABLE IF NOT EXISTS validation_requests (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    startup_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Add validation fields to startups table
ALTER TABLE startups 
ADD COLUMN IF NOT EXISTS startup_nation_validated BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS validation_date TIMESTAMP WITH TIME ZONE;

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_validation_requests_startup_id ON validation_requests(startup_id);
CREATE INDEX IF NOT EXISTS idx_validation_requests_status ON validation_requests(status);
CREATE INDEX IF NOT EXISTS idx_validation_requests_created_at ON validation_requests(created_at);

-- 4. Enable RLS on validation_requests table
ALTER TABLE validation_requests ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies
-- Allow authenticated users to create validation requests
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'validation_requests' 
        AND policyname = 'validation_requests_insert_authenticated'
    ) THEN
        CREATE POLICY validation_requests_insert_authenticated ON validation_requests
        FOR INSERT TO authenticated
        WITH CHECK (true);
    END IF;
END $$;

-- Allow users to read their own validation requests
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'validation_requests' 
        AND policyname = 'validation_requests_select_owner'
    ) THEN
        CREATE POLICY validation_requests_select_owner ON validation_requests
        FOR SELECT TO authenticated
        USING (true);
    END IF;
END $$;

-- Allow admins to update validation requests
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'validation_requests' 
        AND policyname = 'validation_requests_update_admin'
    ) THEN
        CREATE POLICY validation_requests_update_admin ON validation_requests
        FOR UPDATE TO authenticated
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;

-- 6. Grant permissions
GRANT ALL ON validation_requests TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE validation_requests_id_seq TO authenticated;

-- 7. Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_validation_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_update_validation_requests_updated_at'
    ) THEN
        CREATE TRIGGER trigger_update_validation_requests_updated_at
            BEFORE UPDATE ON validation_requests
            FOR EACH ROW
            EXECUTE FUNCTION update_validation_requests_updated_at();
    END IF;
END $$;

-- 8. Verify the setup
SELECT 
    table_name, 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name IN ('validation_requests', 'startups')
AND column_name IN ('startup_nation_validated', 'validation_date', 'status', 'startup_id')
ORDER BY table_name, column_name;

-- 9. Test insert (optional - uncomment to test)
-- INSERT INTO validation_requests (startup_id, startup_name, status) 
-- VALUES (1, 'Test Startup', 'pending');
