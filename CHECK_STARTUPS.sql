-- =====================================================
-- CHECK EXISTING STARTUPS AND FIX FOREIGN KEY ISSUE
-- =====================================================

-- Check what startups exist in the database
SELECT 
    id,
    name,
    user_id,
    total_funding,
    created_at
FROM startups 
ORDER BY id;

-- Check if there are any startups at all
SELECT COUNT(*) as total_startups FROM startups;

-- If no startups exist, create a default one
INSERT INTO startups (name, user_id, total_funding, description, industry, stage, founded_date) 
VALUES 
    ('Default Startup', 
     (SELECT id FROM auth.users LIMIT 1), 
     1000000.00, 
     'Default startup for testing financials', 
     'Technology', 
     'Seed', 
     '2024-01-01')
ON CONFLICT DO NOTHING;

-- Get the startup ID to use for financial records
SELECT id as startup_id_to_use FROM startups ORDER BY id LIMIT 1;

-- Now let's update the financial records to use the correct startup ID
-- First, let's see what startup ID we should use
SELECT 'Use this startup ID for financial records:' as instruction, id as startup_id FROM startups ORDER BY id LIMIT 1;
