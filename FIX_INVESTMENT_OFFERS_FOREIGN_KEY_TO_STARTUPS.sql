-- FIX_INVESTMENT_OFFERS_FOREIGN_KEY_TO_STARTUPS.sql
-- Fix the foreign key constraint in investment_offers table to reference startups table

-- 1. Drop the existing foreign key constraint
ALTER TABLE investment_offers 
DROP CONSTRAINT IF EXISTS investment_offers_investment_id_fkey;

-- 2. Rename the column to be more descriptive
ALTER TABLE investment_offers 
RENAME COLUMN investment_id TO startup_id;

-- 3. Add new foreign key constraint to reference startups table
ALTER TABLE investment_offers 
ADD CONSTRAINT investment_offers_startup_id_fkey 
FOREIGN KEY (startup_id) REFERENCES startups(id) ON DELETE CASCADE;

-- 4. Update the constraint name
ALTER TABLE investment_offers 
DROP CONSTRAINT IF EXISTS investment_offers_investment_id_fkey;

ALTER TABLE investment_offers 
ADD CONSTRAINT investment_offers_startup_id_fkey 
FOREIGN KEY (startup_id) REFERENCES startups(id) ON DELETE CASCADE;

-- 5. Verify the changes
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name='investment_offers';

-- 6. Show the updated table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'investment_offers'
ORDER BY ordinal_position;
