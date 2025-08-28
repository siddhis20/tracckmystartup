-- =====================================================
-- ADD UPDATED_AT COLUMN TO FINANCIAL_RECORDS
-- =====================================================

-- Add updated_at column if it doesn't exist
ALTER TABLE financial_records 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create trigger function for updated_at if it doesn't exist
CREATE OR REPLACE FUNCTION update_financial_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if it doesn't exist
DROP TRIGGER IF EXISTS update_financial_records_updated_at ON financial_records;
CREATE TRIGGER update_financial_records_updated_at
    BEFORE UPDATE ON financial_records
    FOR EACH ROW
    EXECUTE FUNCTION update_financial_records_updated_at();

-- Update existing records to have updated_at = created_at
UPDATE financial_records 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- Verify the changes
SELECT 
    'VERIFICATION' as check_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN updated_at IS NOT NULL THEN 1 END) as records_with_updated_at
FROM financial_records;

