-- Add database constraints to prevent multiple diligence approvals
-- This ensures data integrity at the database level

-- 1. Add a partial unique index to prevent multiple approved diligence records
-- This ensures only one approved diligence per startup-opportunity combination
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'unique_approved_diligence_idx'
    ) THEN
        CREATE UNIQUE INDEX unique_approved_diligence_idx 
        ON public.opportunity_applications (startup_id, opportunity_id) 
        WHERE diligence_status = 'approved';
    END IF;
END $$;

-- 2. Add a check constraint to ensure diligence_status values are valid
DO $$ 
BEGIN
    -- Drop existing constraint if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'valid_diligence_status' 
        AND table_name = 'opportunity_applications'
    ) THEN
        ALTER TABLE public.opportunity_applications DROP CONSTRAINT valid_diligence_status;
    END IF;
    
    -- Add the constraint
    ALTER TABLE public.opportunity_applications 
    ADD CONSTRAINT valid_diligence_status 
    CHECK (diligence_status IN ('none', 'requested', 'approved'));
END $$;

-- 3. Create a function to safely update diligence status
CREATE OR REPLACE FUNCTION safe_update_diligence_status(
    p_application_id UUID,
    p_new_status TEXT,
    p_expected_current_status TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    current_status TEXT;
    update_count INTEGER;
BEGIN
    -- Get current status
    SELECT diligence_status INTO current_status
    FROM opportunity_applications
    WHERE id = p_application_id;
    
    -- If no record found, return false
    IF current_status IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- If expected current status is provided, check it matches
    IF p_expected_current_status IS NOT NULL AND current_status != p_expected_current_status THEN
        RAISE NOTICE 'Expected status % but found %', p_expected_current_status, current_status;
        RETURN FALSE;
    END IF;
    
    -- Prevent updating if already approved
    IF current_status = 'approved' AND p_new_status = 'approved' THEN
        RAISE NOTICE 'Diligence already approved for application %', p_application_id;
        RETURN FALSE;
    END IF;
    
    -- Update the status
    UPDATE opportunity_applications
    SET diligence_status = p_new_status,
        updated_at = NOW()
    WHERE id = p_application_id
    AND diligence_status != 'approved'; -- Prevent overwriting approved status
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    
    RETURN update_count > 0;
END;
$$ LANGUAGE plpgsql;

-- 4. Create a trigger to log diligence status changes
CREATE TABLE IF NOT EXISTS public.diligence_status_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    application_id UUID NOT NULL REFERENCES public.opportunity_applications(id) ON DELETE CASCADE,
    old_status TEXT,
    new_status TEXT NOT NULL,
    changed_by UUID REFERENCES public.users(id),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);

-- 5. Create function to log diligence changes
CREATE OR REPLACE FUNCTION log_diligence_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if status actually changed
    IF OLD.diligence_status IS DISTINCT FROM NEW.diligence_status THEN
        INSERT INTO public.diligence_status_log (
            application_id,
            old_status,
            new_status,
            changed_by
        ) VALUES (
            NEW.id,
            OLD.diligence_status,
            NEW.diligence_status,
            auth.uid()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Create trigger for logging
DROP TRIGGER IF EXISTS diligence_status_change_log ON public.opportunity_applications;
CREATE TRIGGER diligence_status_change_log
    AFTER UPDATE ON public.opportunity_applications
    FOR EACH ROW
    EXECUTE FUNCTION log_diligence_status_change();

-- 7. Add index for performance on diligence status queries
CREATE INDEX IF NOT EXISTS idx_opportunity_applications_diligence_status 
ON public.opportunity_applications(diligence_status) 
WHERE diligence_status IN ('requested', 'approved');

-- 8. Show the constraints and functions
SELECT 'DILIGENCE CONSTRAINTS ADDED' as status;
SELECT 
    'Constraints and indexes created:' as info,
    'unique_approved_diligence_idx' as unique_index,
    'valid_diligence_status' as check_constraint;

SELECT 
    'Functions created:' as info,
    'safe_update_diligence_status' as function_name,
    'log_diligence_status_change' as trigger_function;

-- 9. Test the safe update function
SELECT 'Testing safe update function:' as test_step;
SELECT 
    'Function exists' as test,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'safe_update_diligence_status'
        ) THEN '✅ Function created successfully'
        ELSE '❌ Function creation failed'
    END as status;

-- 10. Show current diligence status distribution
SELECT 'Current diligence status distribution:' as info;
SELECT 
    diligence_status,
    COUNT(*) as count,
    CASE 
        WHEN diligence_status = 'none' THEN 'No diligence requested'
        WHEN diligence_status = 'requested' THEN 'Diligence requested - waiting for startup'
        WHEN diligence_status = 'approved' THEN 'Diligence approved - facilitator has access'
        ELSE 'Unknown status'
    END as description
FROM opportunity_applications
GROUP BY diligence_status
ORDER BY diligence_status;
