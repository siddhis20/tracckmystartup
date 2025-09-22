-- =====================================================
-- CREATE INTERNATIONAL OPERATIONS TABLE
-- =====================================================
-- This script creates the international_operations table if it doesn't exist

-- Create international_operations table
CREATE TABLE IF NOT EXISTS international_operations (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    country TEXT NOT NULL,
    company_type TEXT,
    start_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_international_operations_startup_id ON international_operations(startup_id);
CREATE INDEX IF NOT EXISTS idx_international_operations_country ON international_operations(country);

-- Enable RLS
ALTER TABLE international_operations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own international operations" ON international_operations;
CREATE POLICY "Users can view their own international operations" ON international_operations
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert their own international operations" ON international_operations;
CREATE POLICY "Users can insert their own international operations" ON international_operations
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update their own international operations" ON international_operations;
CREATE POLICY "Users can update their own international operations" ON international_operations
    FOR UPDATE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete their own international operations" ON international_operations;
CREATE POLICY "Users can delete their own international operations" ON international_operations
    FOR DELETE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_international_operations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_international_operations_updated_at ON international_operations;
CREATE TRIGGER update_international_operations_updated_at
    BEFORE UPDATE ON international_operations
    FOR EACH ROW
    EXECUTE FUNCTION update_international_operations_updated_at();

-- Verify table creation
SELECT 
    'International operations table created successfully:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'international_operations'
ORDER BY ordinal_position;


