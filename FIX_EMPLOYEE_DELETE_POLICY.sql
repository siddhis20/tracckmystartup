-- Fix Employee Delete Policy
-- This script adds the missing DELETE policy for employees table

-- 1. Add DELETE policy for employees (allows startup owners to delete their employees)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='employees' AND policyname='employees_delete_owner'
  ) THEN
    CREATE POLICY employees_delete_owner ON public.employees
    FOR DELETE TO authenticated
    USING (EXISTS (
      SELECT 1 FROM public.startups s
      WHERE s.id = employees.startup_id AND s.user_id = auth.uid()
    ));
  END IF;
END $$;

-- 2. Verify the policy was created
SELECT 
  policyname,
  cmd AS command,
  roles,
  qual AS "using"
FROM pg_policies 
WHERE schemaname='public' AND tablename='employees' AND policyname='employees_delete_owner';

-- 3. Check current employees (for reference)
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
WHERE startup_id = 11
ORDER BY name;

-- 4. Test DELETE functionality (optional - uncomment to test)
-- DELETE FROM public.employees 
-- WHERE id = 'b322376d-d688-418d-991b-8d51a77d6816' AND startup_id = 11;

