-- Check the actual column types in the startups table
-- This will help us create the correct function signature

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups' 
ORDER BY ordinal_position;
