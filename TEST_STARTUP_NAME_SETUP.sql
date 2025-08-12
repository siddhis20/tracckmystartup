-- Test script to verify startup name setup
-- Run this after executing ADD_STARTUP_NAME_COLUMN.sql

-- Check if the column was added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'startup_name';

-- Check the constraint
SELECT constraint_name, constraint_type, check_clause
FROM information_schema.check_constraints 
WHERE constraint_name = 'chk_startup_name_role';

-- Check the index
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'users' AND indexname = 'idx_users_startup_name';

-- Test inserting a startup user with startup name
-- (This should work)
INSERT INTO users (id, email, name, role, startup_name, registration_date) 
VALUES (
  'test-startup-user-id',
  'startup@test.com',
  'Test Startup User',
  'Startup',
  'Test Startup Company',
  CURRENT_DATE
);

-- Test inserting a non-startup user with startup name
-- (This should fail due to constraint)
-- INSERT INTO users (id, email, name, role, startup_name, registration_date) 
-- VALUES (
--   'test-investor-user-id',
--   'investor@test.com',
--   'Test Investor User',
--   'Investor',
--   'Invalid Startup Name',
--   CURRENT_DATE
-- );

-- Test the function
SELECT * FROM get_startup_by_user_email('startup@test.com');

-- Test the view
SELECT * FROM user_startup_info WHERE email = 'startup@test.com';

-- Clean up test data
DELETE FROM users WHERE email = 'startup@test.com';

-- Verify the function works with real data
-- (This will show any existing startup users)
SELECT u.email, u.startup_name, s.name as startup_name_in_startups_table
FROM users u
LEFT JOIN startups s ON u.startup_name = s.name
WHERE u.role = 'Startup';
