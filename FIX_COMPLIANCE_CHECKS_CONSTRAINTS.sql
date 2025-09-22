-- =====================================================
-- FIX COMPLIANCE_CHECKS TABLE CONSTRAINTS
-- =====================================================
-- This script fixes the database constraint issues in the compliance_checks table
-- that are causing the ON CONFLICT errors

-- =====================================================
-- STEP 1: ADD MISSING UNIQUE CONSTRAINT
-- =====================================================

-- Add unique constraint on startup_id and task_id to prevent duplicates
-- This will allow the upsert operations to work properly
ALTER TABLE public.compliance_checks 
ADD CONSTRAINT IF NOT EXISTS compliance_checks_startup_task_unique 
UNIQUE (startup_id, task_id);

-- =====================================================
-- STEP 2: ADD INDEXES FOR PERFORMANCE
-- =====================================================

-- Add index on startup_id for faster queries
CREATE INDEX IF NOT EXISTS idx_compliance_checks_startup_id 
ON public.compliance_checks(startup_id);

-- Add index on task_id for faster queries
CREATE INDEX IF NOT EXISTS idx_compliance_checks_task_id 
ON public.compliance_checks(task_id);

-- Add index on entity_identifier for faster queries
CREATE INDEX IF NOT EXISTS idx_compliance_checks_entity_identifier 
ON public.compliance_checks(entity_identifier);

-- =====================================================
-- STEP 3: UPDATE EXISTING DATA (if needed)
-- =====================================================

-- Remove any duplicate entries that might exist
-- This will keep the most recent entry for each startup_id, task_id combination
WITH duplicates AS (
  SELECT id, 
         ROW_NUMBER() OVER (PARTITION BY startup_id, task_id ORDER BY created_at DESC) as rn
  FROM public.compliance_checks
)
DELETE FROM public.compliance_checks 
WHERE id IN (
  SELECT id FROM duplicates WHERE rn > 1
);

-- =====================================================
-- STEP 4: VERIFY CONSTRAINTS
-- =====================================================

-- Check that the constraint was added successfully
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.compliance_checks'::regclass
AND conname = 'compliance_checks_startup_task_unique';

-- =====================================================
-- STEP 5: TEST THE FIX
-- =====================================================

-- Test that upsert operations now work without errors
-- This is just a test - you can remove this section after verification

-- Example upsert that should now work:
/*
INSERT INTO public.compliance_checks (
    startup_id, 
    task_id, 
    task_name, 
    entity_identifier, 
    entity_display_name, 
    year, 
    ca_required, 
    cs_required, 
    ca_status, 
    cs_status
) VALUES (
    1, 
    'test_task_1', 
    'Test Task', 
    'startup', 
    'Test Company', 
    2024, 
    true, 
    true, 
    'pending', 
    'pending'
) ON CONFLICT (startup_id, task_id) 
DO UPDATE SET 
    updated_at = NOW(),
    task_name = EXCLUDED.task_name,
    entity_identifier = EXCLUDED.entity_identifier,
    entity_display_name = EXCLUDED.entity_display_name,
    year = EXCLUDED.year,
    ca_required = EXCLUDED.ca_required,
    cs_required = EXCLUDED.cs_required,
    ca_status = EXCLUDED.ca_status,
    cs_status = EXCLUDED.cs_status;
*/

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Compliance checks table constraints fixed successfully!';
    RAISE NOTICE '✅ Unique constraint added on (startup_id, task_id)';
    RAISE NOTICE '✅ Performance indexes added';
    RAISE NOTICE '✅ Duplicate entries cleaned up';
    RAISE NOTICE '✅ Upsert operations should now work without errors';
END $$;
