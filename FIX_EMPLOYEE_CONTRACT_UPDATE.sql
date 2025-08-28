-- Fix Employee Contract URL Update Issue
-- This script adds the missing UPDATE policy for employees table and ensures contract_url column exists

-- 1. Ensure contract_url column exists
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS contract_url TEXT;

-- 2. Add updated_at column if it doesn't exist (fixes trigger function error)
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. Add UPDATE policy for employees (allows startup owners to update their employees)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='employees' AND policyname='employees_update_owner'
  ) THEN
    CREATE POLICY employees_update_owner ON public.employees
    FOR UPDATE TO authenticated
    USING (EXISTS (
      SELECT 1 FROM public.startups s
      WHERE s.id = employees.startup_id AND s.user_id = auth.uid()
    ))
    WITH CHECK (EXISTS (
      SELECT 1 FROM public.startups s
      WHERE s.id = employees.startup_id AND s.user_id = auth.uid()
    ));
  END IF;
END $$;

-- 4. Verify the policy was created
SELECT 
  policyname,
  cmd AS command,
  roles,
  qual AS "using",
  with_check
FROM pg_policies 
WHERE schemaname='public' AND tablename='employees' AND policyname='employees_update_owner';

-- 5. Check current employee contract status (FIXED LOGIC)
SELECT 
  id,
  name,
  department,
  contract_url,
  CASE 
    WHEN contract_url IS NOT NULL AND contract_url != '' THEN 'Has Contract'
    ELSE 'No Contract'
  END as contract_status
FROM public.employees 
WHERE startup_id = 11  -- Replace with your actual startup ID
ORDER BY name;

-- 6. Test UPDATE functionality (optional - uncomment to test)
-- UPDATE public.employees 
-- SET contract_url = 'https://test-contract-url.com/example.pdf'
-- WHERE id = 'b322376d-d688-418d-991b-8d51a77d6816' AND startup_id = 11;
