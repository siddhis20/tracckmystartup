-- =====================================================
-- CHECK AND FIX FINANCIAL RECORDS TABLE
-- =====================================================

-- First, let's check if the table exists and what columns it has
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'financial_records' 
ORDER BY ordinal_position;

-- Check if the table exists at all
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'financial_records'
) as table_exists;

-- If the table doesn't exist, create it
CREATE TABLE IF NOT EXISTS financial_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
    record_type VARCHAR(20) NOT NULL CHECK (record_type IN ('expense', 'revenue')),
    date DATE NOT NULL,
    entity VARCHAR(100) NOT NULL,
    description TEXT,
    vertical VARCHAR(100) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    funding_source VARCHAR(100), -- For expenses
    cogs DECIMAL(15,2), -- For revenue (Cost of Goods Sold)
    attachment_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- If the table exists but is missing the record_type column, add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'record_type'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN record_type VARCHAR(20) NOT NULL DEFAULT 'expense';
        ALTER TABLE financial_records ADD CONSTRAINT check_record_type CHECK (record_type IN ('expense', 'revenue'));
    END IF;
END $$;

-- If the table exists but is missing other columns, add them
DO $$
BEGIN
    -- Add startup_id if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'startup_id'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN startup_id INTEGER NOT NULL DEFAULT 1;
        ALTER TABLE financial_records ADD CONSTRAINT fk_financial_records_startup 
            FOREIGN KEY (startup_id) REFERENCES startups(id) ON DELETE CASCADE;
    END IF;
    
    -- Add funding_source if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'funding_source'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN funding_source VARCHAR(100);
    END IF;
    
    -- Add cogs if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'cogs'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN cogs DECIMAL(15,2);
    END IF;
    
    -- Add attachment_url if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'attachment_url'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN attachment_url TEXT;
    END IF;
    
    -- Add created_at if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add updated_at if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_financial_records_startup_id ON financial_records(startup_id);
CREATE INDEX IF NOT EXISTS idx_financial_records_date ON financial_records(date);
CREATE INDEX IF NOT EXISTS idx_financial_records_type ON financial_records(record_type);
CREATE INDEX IF NOT EXISTS idx_financial_records_entity ON financial_records(entity);
CREATE INDEX IF NOT EXISTS idx_financial_records_vertical ON financial_records(vertical);

-- Create updated_at trigger if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_financial_records_updated_at ON financial_records;
CREATE TRIGGER update_financial_records_updated_at 
    BEFORE UPDATE ON financial_records 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE financial_records ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own financial records" ON financial_records;
DROP POLICY IF EXISTS "Users can insert their own financial records" ON financial_records;
DROP POLICY IF EXISTS "Users can update their own financial records" ON financial_records;
DROP POLICY IF EXISTS "Users can delete their own financial records" ON financial_records;
DROP POLICY IF EXISTS "Admins can view all financial records" ON financial_records;
DROP POLICY IF EXISTS "CA can view all financial records" ON financial_records;
DROP POLICY IF EXISTS "CS can view all financial records" ON financial_records;

-- Create RLS policies
CREATE POLICY "Users can view their own financial records" ON financial_records
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own financial records" ON financial_records
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own financial records" ON financial_records
    FOR UPDATE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own financial records" ON financial_records
    FOR DELETE USING (
        startup_id IN (
            SELECT id FROM startups WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all financial records" ON financial_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role = 'Admin'
        )
    );

CREATE POLICY "CA can view all financial records" ON financial_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role = 'CA'
        )
    );

CREATE POLICY "CS can view all financial records" ON financial_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users WHERE id = auth.uid() AND role = 'CS'
        )
    );

-- Now let's verify the table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'financial_records' 
ORDER BY ordinal_position;

-- Test inserting a sample record
INSERT INTO financial_records (startup_id, record_type, date, entity, description, vertical, amount, funding_source, cogs, attachment_url) 
VALUES (1, 'expense', '2024-01-15', 'Parent Company', 'AWS Services', 'Infrastructure', 2500.00, 'Series A', NULL, NULL)
ON CONFLICT DO NOTHING;

-- Verify the insert worked
SELECT * FROM financial_records LIMIT 5;
