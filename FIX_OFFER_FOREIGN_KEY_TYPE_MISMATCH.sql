-- FIX_OFFER_FOREIGN_KEY_TYPE_MISMATCH.sql
-- Fix the type mismatch between investment_id (integer) and fundraising_details.id (uuid)

-- 1. First, let's check the current table structures
SELECT 
    table_name, 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name IN ('investment_offers', 'fundraising_details', 'new_investments')
ORDER BY table_name, column_name;

-- 2. Drop the existing foreign key constraint
ALTER TABLE investment_offers 
DROP CONSTRAINT IF EXISTS investment_offers_investment_id_fkey;

-- 3. Since investment_id is integer and fundraising_details.id is uuid,
-- we need to reference new_investments.id which should be integer
-- Let's check if new_investments table exists and has the right structure
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'new_investments'
) as new_investments_exists;

-- 4. If new_investments doesn't exist, create it
CREATE TABLE IF NOT EXISTS new_investments (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    investment_type TEXT,
    investment_value DECIMAL(15,2),
    equity_allocation DECIMAL(5,2),
    sector TEXT,
    total_funding DECIMAL(15,2),
    total_revenue DECIMAL(15,2),
    registration_date DATE,
    compliance_status TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create dummy records in new_investments for each startup
-- This will allow the foreign key constraint to work
INSERT INTO new_investments (id, name, investment_type, investment_value, equity_allocation, sector, total_funding, total_revenue, registration_date, compliance_status)
SELECT 
    s.id,
    s.name,
    'Seed',
    1000000.00,
    10.00,
    s.sector,
    0.00,
    0.00,
    s.registration_date,
    s.compliance_status
FROM startups s
WHERE NOT EXISTS (
    SELECT 1 FROM new_investments ni WHERE ni.id = s.id
)
ON CONFLICT (id) DO NOTHING;

-- 6. Re-add the foreign key constraint to reference new_investments
ALTER TABLE investment_offers 
ADD CONSTRAINT investment_offers_investment_id_fkey 
FOREIGN KEY (investment_id) REFERENCES new_investments(id) ON DELETE CASCADE;

-- 7. Verify the fix
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

-- 8. Test the constraint
SELECT COUNT(*) as total_new_investments FROM new_investments;
SELECT COUNT(*) as total_investment_offers FROM investment_offers;
