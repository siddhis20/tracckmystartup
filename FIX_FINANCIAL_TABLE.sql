-- =====================================================
-- QUICK FIX FOR FINANCIAL RECORDS TABLE
-- =====================================================

-- Check current table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'financial_records' 
ORDER BY ordinal_position;

-- Add missing record_type column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'record_type'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN record_type VARCHAR(20) NOT NULL DEFAULT 'expense';
        ALTER TABLE financial_records ADD CONSTRAINT check_record_type CHECK (record_type IN ('expense', 'revenue'));
        RAISE NOTICE 'Added record_type column to financial_records table';
    ELSE
        RAISE NOTICE 'record_type column already exists';
    END IF;
END $$;

-- Add other missing columns if needed
DO $$
BEGIN
    -- Add startup_id if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'startup_id'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN startup_id INTEGER NOT NULL DEFAULT 1;
        RAISE NOTICE 'Added startup_id column to financial_records table';
    END IF;
    
    -- Add funding_source if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'funding_source'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN funding_source VARCHAR(100);
        RAISE NOTICE 'Added funding_source column to financial_records table';
    END IF;
    
    -- Add cogs if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'cogs'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN cogs DECIMAL(15,2);
        RAISE NOTICE 'Added cogs column to financial_records table';
    END IF;
    
    -- Add attachment_url if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'financial_records' AND column_name = 'attachment_url'
    ) THEN
        ALTER TABLE financial_records ADD COLUMN attachment_url TEXT;
        RAISE NOTICE 'Added attachment_url column to financial_records table';
    END IF;
END $$;

-- Verify the fix worked
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'financial_records' 
ORDER BY ordinal_position;

-- Test the table structure
SELECT 'Table structure verified successfully' as status;
