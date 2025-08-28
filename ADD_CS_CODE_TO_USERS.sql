-- Add CS Code Column to Users Table
-- This script adds the missing cs_code column to the users table

-- 1. Add cs_code column to auth.users table
ALTER TABLE auth.users 
ADD COLUMN IF NOT EXISTS cs_code VARCHAR(20);

-- 2. Add ca_code column to auth.users table (for consistency)
ALTER TABLE auth.users 
ADD COLUMN IF NOT EXISTS ca_code VARCHAR(20);

-- 3. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_cs_code ON auth.users(cs_code);
CREATE INDEX IF NOT EXISTS idx_users_ca_code ON auth.users(ca_code);
CREATE INDEX IF NOT EXISTS idx_users_role ON auth.users(role);

-- 4. Update existing CS users with generated codes
UPDATE auth.users 
SET cs_code = 'CS-' || LPAD(CAST(id AS TEXT), 6, '0')
WHERE role = 'CS' AND cs_code IS NULL;

-- 5. Update existing CA users with generated codes
UPDATE auth.users 
SET ca_code = 'CA-' || LPAD(CAST(id AS TEXT), 6, '0')
WHERE role = 'CA' AND ca_code IS NULL;

-- 6. Show the updated table structure
SELECT 
  'Updated auth.users structure' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'auth' 
  AND table_name = 'users'
  AND column_name IN ('id', 'email', 'role', 'name', 'cs_code', 'ca_code')
ORDER BY ordinal_position;

-- 7. Show CS users with their codes
SELECT 
  'CS Users with Codes' as info,
  id,
  email,
  role,
  name,
  cs_code
FROM auth.users 
WHERE role = 'CS'
ORDER BY cs_code;

-- 8. Show the specific user
SELECT 
  'Specific User' as info,
  id,
  email,
  role,
  name,
  cs_code,
  ca_code
FROM auth.users 
WHERE email = 'network@startupnationindia.com';

