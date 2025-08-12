-- =====================================================
-- ROBUST FIX FOR USER_ID ISSUE
-- =====================================================
-- This script provides detailed diagnostics and robust fixes

-- Step 1: Diagnostic - Check current state
SELECT '=== DIAGNOSTIC START ===' as step;

-- Check if user_id column exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'startups' AND column_name = 'user_id'
        ) THEN 'user_id column EXISTS'
        ELSE 'user_id column DOES NOT EXIST'
    END as column_status;

-- Count startups
SELECT COUNT(*) as total_startups FROM public.startups;

-- Count users
SELECT COUNT(*) as total_users FROM public.users;

-- Check user roles
SELECT role, COUNT(*) as count 
FROM public.users 
GROUP BY role 
ORDER BY count DESC;

-- Check startups with null user_id
SELECT COUNT(*) as startups_with_null_user_id 
FROM public.startups 
WHERE user_id IS NULL;

-- Step 2: Add user_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'startups' AND column_name = 'user_id'
    ) THEN
        RAISE NOTICE 'Adding user_id column...';
        ALTER TABLE public.startups 
        ADD COLUMN user_id UUID REFERENCES public.users(id) ON DELETE CASCADE;
    ELSE
        RAISE NOTICE 'user_id column already exists';
    END IF;
END $$;

-- Step 3: Check if we have any users to assign
DO $$
DECLARE
    user_count INTEGER;
    admin_count INTEGER;
    startup_count INTEGER;
    null_startup_count INTEGER;
BEGIN
    -- Count users
    SELECT COUNT(*) INTO user_count FROM public.users;
    SELECT COUNT(*) INTO admin_count FROM public.users WHERE role = 'Admin';
    SELECT COUNT(*) INTO startup_count FROM public.startups;
    SELECT COUNT(*) INTO null_startup_count FROM public.startups WHERE user_id IS NULL;
    
    RAISE NOTICE 'Users: %, Admins: %, Startups: %, Null user_id startups: %', 
                 user_count, admin_count, startup_count, null_startup_count;
    
    -- If no users exist, we can't proceed
    IF user_count = 0 THEN
        RAISE EXCEPTION 'No users found in the system. Please create at least one user before running this migration.';
    END IF;
    
    -- If there are startups with null user_id, assign them
    IF null_startup_count > 0 THEN
        RAISE NOTICE 'Assigning user_id to % startups...', null_startup_count;
        
        -- Try to assign to admin first
        UPDATE public.startups 
        SET user_id = (
            SELECT id FROM public.users 
            WHERE role = 'Admin' 
            LIMIT 1
        )
        WHERE user_id IS NULL;
        
        -- Check if any were updated
        GET DIAGNOSTICS null_startup_count = ROW_COUNT;
        RAISE NOTICE 'Assigned % startups to admin users', null_startup_count;
        
        -- If still have null values, assign to any user
        SELECT COUNT(*) INTO null_startup_count FROM public.startups WHERE user_id IS NULL;
        IF null_startup_count > 0 THEN
            RAISE NOTICE 'Assigning remaining % startups to any user...', null_startup_count;
            
            UPDATE public.startups 
            SET user_id = (SELECT id FROM public.users LIMIT 1)
            WHERE user_id IS NULL;
            
            GET DIAGNOSTICS null_startup_count = ROW_COUNT;
            RAISE NOTICE 'Assigned % more startups to users', null_startup_count;
        END IF;
    END IF;
    
    -- Final check
    SELECT COUNT(*) INTO null_startup_count FROM public.startups WHERE user_id IS NULL;
    IF null_startup_count > 0 THEN
        RAISE EXCEPTION 'Still have % startups with null user_id. Manual intervention required.', null_startup_count;
    END IF;
    
    RAISE NOTICE 'All startups now have user_id assigned';
END $$;

-- Step 4: Make user_id NOT NULL
ALTER TABLE public.startups ALTER COLUMN user_id SET NOT NULL;

-- Step 5: Create index
CREATE INDEX IF NOT EXISTS idx_startups_user_id ON public.startups(user_id);

-- Step 6: Update RLS policies
DROP POLICY IF EXISTS "Anyone can view startups" ON public.startups;
DROP POLICY IF EXISTS "Authenticated users can create startups" ON public.startups;
DROP POLICY IF EXISTS "Authenticated users can update startups" ON public.startups;
DROP POLICY IF EXISTS "Users can view their own startups" ON public.startups;
DROP POLICY IF EXISTS "Users can insert their own startups" ON public.startups;
DROP POLICY IF EXISTS "Users can update their own startups" ON public.startups;
DROP POLICY IF EXISTS "Users can delete their own startups" ON public.startups;

-- Create new user-specific policies
CREATE POLICY "Users can view their own startups" ON public.startups
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own startups" ON public.startups
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own startups" ON public.startups
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own startups" ON public.startups
    FOR DELETE USING (auth.uid() = user_id);

-- Step 7: Enable RLS
ALTER TABLE public.startups ENABLE ROW LEVEL SECURITY;

-- Step 8: Final verification
SELECT '=== FINAL VERIFICATION ===' as step;

SELECT COUNT(*) as total_startups, 
       COUNT(user_id) as startups_with_user_id,
       COUNT(*) - COUNT(user_id) as startups_without_user_id
FROM public.startups;

-- Show sample of startups with their user assignments
SELECT s.id, s.name, s.user_id, u.email, u.role
FROM public.startups s
LEFT JOIN public.users u ON s.user_id = u.id
LIMIT 5;

SELECT 'Migration completed successfully!' as status;
