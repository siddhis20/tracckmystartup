-- FIX_INVESTMENT_OFFERS_FOREIGN_KEY.sql
-- Fix the foreign key constraint in investment_offers table

-- 1. Drop the existing foreign key constraint
ALTER TABLE investment_offers 
DROP CONSTRAINT IF EXISTS investment_offers_investment_id_fkey;

-- 2. Add new foreign key constraint to reference fundraising_details
ALTER TABLE investment_offers 
ADD CONSTRAINT investment_offers_investment_id_fkey 
FOREIGN KEY (investment_id) REFERENCES fundraising_details(id) ON DELETE CASCADE;

-- 3. Update the column name to be more descriptive
ALTER TABLE investment_offers 
RENAME COLUMN investment_id TO fundraising_id;

-- 4. Update the constraint name
ALTER TABLE investment_offers 
DROP CONSTRAINT IF EXISTS investment_offers_investment_id_fkey;

ALTER TABLE investment_offers 
ADD CONSTRAINT investment_offers_fundraising_id_fkey 
FOREIGN KEY (fundraising_id) REFERENCES fundraising_details(id) ON DELETE CASCADE;

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
