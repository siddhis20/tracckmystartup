-- CS Test Setup: Create test CS users and assignments

-- 1) Create test CS users (if they don't exist)
INSERT INTO public.users (id, email, name, role, cs_code, registration_date)
VALUES 
  ('550e8400-e29b-41d4-a716-446655440001', 'cs1@test.com', 'Test CS User 1', 'CS', 'CS-TEST01', '2024-01-01'),
  ('550e8400-e29b-41d4-a716-446655440002', 'cs2@test.com', 'Test CS User 2', 'CS', 'CS-TEST02', '2024-01-01')
ON CONFLICT (id) DO NOTHING;

-- 2) Create some test startups (if they don't exist)
INSERT INTO public.startups (name, investment_type, investment_value, equity_allocation, current_valuation, compliance_status, sector, total_funding, total_revenue, registration_date, user_id)
VALUES 
  ('TechStart Alpha', 'Seed', 500000, 10, 5000000, 'Pending', 'Technology', 1000000, 500000, '2024-01-15', '550e8400-e29b-41d4-a716-446655440003'),
  ('GreenEnergy Corp', 'Series A', 2000000, 15, 15000000, 'Pending', 'Clean Energy', 5000000, 2000000, '2024-02-01', '550e8400-e29b-41d4-a716-446655440004'),
  ('HealthTech Solutions', 'Seed', 750000, 12, 7500000, 'Pending', 'Healthcare', 1500000, 750000, '2024-02-15', '550e8400-e29b-41d4-a716-446655440005'),
  ('FinTech Innovations', 'Series A', 3000000, 20, 20000000, 'Pending', 'Financial Services', 8000000, 3000000, '2024-03-01', '550e8400-e29b-41d4-a716-446655440006')
ON CONFLICT (name) DO NOTHING;

-- 3) Create CS assignments for testing
INSERT INTO public.cs_assignments (cs_code, startup_id, status, notes, assignment_date)
SELECT 
  u.cs_code,
  s.id,
  'active',
  'Test assignment for CS functionality',
  now()
FROM public.users u
CROSS JOIN public.startups s
WHERE u.role = 'CS' 
  AND u.cs_code IN ('CS-TEST01', 'CS-TEST02')
  AND s.name IN ('TechStart Alpha', 'GreenEnergy Corp')
ON CONFLICT (cs_code, startup_id) DO NOTHING;

-- 4) Test the get_cs_startups function
DO $$
DECLARE 
  test_cs_code VARCHAR(20);
  test_result RECORD;
BEGIN
  -- Get a test CS code
  SELECT cs_code INTO test_cs_code 
  FROM public.users 
  WHERE role = 'CS' AND cs_code IS NOT NULL 
  LIMIT 1;
  
  IF test_cs_code IS NOT NULL THEN
    RAISE NOTICE 'Testing get_cs_startups with CS code: %', test_cs_code;
    
    -- Test the function
    FOR test_result IN 
      SELECT * FROM public.get_cs_startups(test_cs_code)
    LOOP
      RAISE NOTICE 'Found assignment: startup_id=%, startup_name=%, status=%', 
        test_result.startup_id, test_result.startup_name, test_result.status;
    END LOOP;
  ELSE
    RAISE NOTICE 'No CS users found for testing';
  END IF;
END$$;

-- 5) Show current CS assignments
SELECT 
  u.name as cs_name,
  u.cs_code,
  s.name as startup_name,
  ca.status,
  ca.assignment_date
FROM public.cs_assignments ca
JOIN public.users u ON u.cs_code = ca.cs_code
JOIN public.startups s ON s.id = ca.startup_id
WHERE u.role = 'CS'
ORDER BY u.cs_code, s.name;


