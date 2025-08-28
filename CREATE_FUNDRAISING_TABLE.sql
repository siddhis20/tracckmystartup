-- CREATE_FUNDRAISING_TABLE.sql
-- This script creates the fundraising_details table if it doesn't exist

-- Create the fundraising_details table
CREATE TABLE IF NOT EXISTS fundraising_details (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    active BOOLEAN DEFAULT false,
    type TEXT NOT NULL CHECK (type IN ('Pre-Seed', 'Seed', 'Series A', 'Series B', 'Bridge')),
    value DECIMAL(15,2) NOT NULL,
    equity DECIMAL(5,2) NOT NULL, -- Percentage
    validation_requested BOOLEAN DEFAULT false,
    pitch_deck_url TEXT,
    pitch_video_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_fundraising_details_startup_id ON fundraising_details(startup_id);
CREATE INDEX IF NOT EXISTS idx_fundraising_details_active ON fundraising_details(active);
CREATE INDEX IF NOT EXISTS idx_fundraising_details_type ON fundraising_details(type);

-- Create a trigger to update the updated_at column
CREATE OR REPLACE FUNCTION update_fundraising_details_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_fundraising_details_updated_at
    BEFORE UPDATE ON fundraising_details
    FOR EACH ROW
    EXECUTE FUNCTION update_fundraising_details_updated_at();

-- Verify the table was created
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name = 'fundraising_details';

-- Show the table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'fundraising_details'
ORDER BY ordinal_position;

