-- Script to create missing startup records for users
-- Run this if users have startup_name but no corresponding startup record

-- First, let's see what users have startup_name but no startup record
SELECT 
  u.id as user_id,
  u.email,
  u.name as user_name,
  u.startup_name,
  s.id as startup_id,
  s.name as startup_name_in_startups
FROM users u
LEFT JOIN startups s ON u.startup_name = s.name
WHERE u.role = 'Startup' AND u.startup_name IS NOT NULL
ORDER BY u.email;

-- Create missing startup records
INSERT INTO startups (
  name,
  investment_type,
  investment_value,
  equity_allocation,
  current_valuation,
  compliance_status,
  sector,
  total_funding,
  total_revenue,
  registration_date
)
SELECT 
  u.startup_name,
  'Seed',
  0,
  0,
  0,
  'Pending',
  'Technology',
  0,
  0,
  u.registration_date
FROM users u
LEFT JOIN startups s ON u.startup_name = s.name
WHERE u.role = 'Startup' 
  AND u.startup_name IS NOT NULL 
  AND s.id IS NULL;

-- Verify the fix
SELECT 
  u.email,
  u.startup_name,
  s.name as startup_name_in_startups,
  CASE 
    WHEN s.id IS NOT NULL THEN '✅ Startup record exists'
    ELSE '❌ No startup record'
  END as status
FROM users u
LEFT JOIN startups s ON u.startup_name = s.name
WHERE u.role = 'Startup' AND u.startup_name IS NOT NULL
ORDER BY u.email;
