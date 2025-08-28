-- Find the actual CS code that exists
-- We know there's 1 CS code, let's see what it is

-- 1. Show the CS user with their code
SELECT 
  'CS User with code' as info,
  id,
  email,
  role,
  name,
  cs_code
FROM public.users 
WHERE role = 'CS' 
  AND cs_code IS NOT NULL;

-- 2. Show all users with their codes for context
SELECT 
  'All users with codes' as info,
  id,
  email,
  role,
  name,
  cs_code
FROM public.users 
WHERE cs_code IS NOT NULL
ORDER BY role, name;

-- 3. Show all CS users (with or without codes)
SELECT 
  'All CS users' as info,
  id,
  email,
  role,
  name,
  cs_code
FROM public.users 
WHERE role = 'CS'
ORDER BY name;

