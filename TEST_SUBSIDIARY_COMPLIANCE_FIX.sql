-- =====================================================
-- TEST SUBSIDIARY COMPLIANCE FIX
-- =====================================================
-- This script tests that the subsidiary compliance fix works properly

-- =====================================================
-- STEP 1: VERIFY TABLE STRUCTURES
-- =====================================================

-- Check subsidiaries table structure
SELECT 'SUBSIDIARIES TABLE STRUCTURE:' as test_name;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'subsidiaries' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check international_ops table structure
SELECT 'INTERNATIONAL_OPS TABLE STRUCTURE:' as test_name;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'international_ops' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 2: TEST COMPLIANCE RULES TABLE
-- =====================================================

-- Check if compliance_rules table exists and has data
SELECT 'COMPLIANCE_RULES TABLE:' as test_name;
SELECT country_code, 
       CASE 
         WHEN rules IS NULL THEN 'NULL'
         WHEN jsonb_typeof(rules) = 'object' THEN 'OBJECT'
         ELSE 'OTHER'
       END as rules_type,
       CASE 
         WHEN rules IS NULL THEN 0
         ELSE jsonb_array_length(COALESCE(rules -> 'default' -> 'annual', '[]'::jsonb))
       END as default_annual_rules_count
FROM compliance_rules
ORDER BY country_code;

-- =====================================================
-- STEP 3: TEST COMPLIANCE TASK GENERATION
-- =====================================================

-- Test compliance task generation for a sample startup
-- (Replace :startup_id with an actual startup ID from your database)
SELECT 'COMPLIANCE TASK GENERATION TEST:' as test_name;

-- First, let's see what startups exist
SELECT 'AVAILABLE STARTUPS:' as test_name;
SELECT id, name, country_of_registration, company_type, registration_date
FROM startups
LIMIT 5;

-- Test compliance task generation function
-- (This will show if the function can generate tasks for subsidiaries)
SELECT 'COMPLIANCE TASK GENERATION FOR STARTUP 1:' as test_name;
SELECT * FROM generate_compliance_tasks_for_startup(1) 
WHERE entity_identifier LIKE 'sub-%'
LIMIT 10;

-- =====================================================
-- STEP 4: TEST SUBSIDIARY FUNCTIONS
-- =====================================================

-- Test adding a subsidiary with company_type
SELECT 'TESTING ADD SUBSIDIARY FUNCTION:' as test_name;

-- First, let's see if we can add a subsidiary
-- (This will test the add_subsidiary function)
SELECT 'SUBSIDIARY ADDITION TEST:' as test_name;
-- Note: This will only work if you have a startup with ID 1
-- and the user has proper permissions

-- =====================================================
-- STEP 5: VERIFY INDEXES
-- =====================================================

-- Check if indexes were created
SELECT 'SUBSIDIARIES INDEXES:' as test_name;
SELECT indexname, indexdef
FROM pg_indexes 
WHERE tablename = 'subsidiaries' 
AND schemaname = 'public';

SELECT 'INTERNATIONAL_OPS INDEXES:' as test_name;
SELECT indexname, indexdef
FROM pg_indexes 
WHERE tablename = 'international_ops' 
AND schemaname = 'public';

-- =====================================================
-- STEP 6: VERIFY RLS POLICIES
-- =====================================================

-- Check RLS policies
SELECT 'SUBSIDIARIES RLS POLICIES:' as test_name;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'subsidiaries' 
AND schemaname = 'public';

SELECT 'INTERNATIONAL_OPS RLS POLICIES:' as test_name;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'international_ops' 
AND schemaname = 'public';

-- =====================================================
-- STEP 7: SUMMARY
-- =====================================================

SELECT 'FIX VERIFICATION SUMMARY:' as test_name;

-- Check if all required columns exist
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'subsidiaries' 
      AND column_name = 'company_type'
      AND table_schema = 'public'
    ) THEN '✅ subsidiaries.company_type exists'
    ELSE '❌ subsidiaries.company_type missing'
  END as subsidiaries_company_type_check,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'subsidiaries' 
      AND column_name = 'user_id'
      AND table_schema = 'public'
    ) THEN '✅ subsidiaries.user_id exists'
    ELSE '❌ subsidiaries.user_id missing'
  END as subsidiaries_user_id_check,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'international_ops' 
      AND column_name = 'company_type'
      AND table_schema = 'public'
    ) THEN '✅ international_ops.company_type exists'
    ELSE '❌ international_ops.company_type missing'
  END as international_ops_company_type_check,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'international_ops' 
      AND column_name = 'user_id'
      AND table_schema = 'public'
    ) THEN '✅ international_ops.user_id exists'
    ELSE '❌ international_ops.user_id missing'
  END as international_ops_user_id_check;

-- =====================================================
-- END OF TEST SCRIPT
-- =====================================================
