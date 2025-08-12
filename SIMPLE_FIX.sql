-- =====================================================
-- SIMPLE FIX - ADD USER_ID COLUMN FROM SCRATCH
-- =====================================================
-- Since user_id column doesn't exist, we can add it cleanly

-- Step 1: Check current state
SELECT '=== CURRENT STATE ===' as step;

SELECT COUNT(*) as total_startups FROM public.startups;
SELECT COUNT(*) as total_users FROM public.users;

-- Show sample users
SELECT id, email, role FROM public.users LIMIT 5;

-- Step 2: Add user_id column (nullable initially)
ALTER TABLE public.startups 
ADD COLUMN user_id UUID REFERENCES public.users(id) ON DELETE CASCADE;

-- Step 3: Assign user_id to existing startups
-- First try to assign to admin users
UPDATE public.startups 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'Admin' 
    LIMIT 1
);

-- If no admin users, assign to any user
UPDATE public.startups 
SET user_id = (SELECT id FROM public.users LIMIT 1)
WHERE user_id IS NULL;

-- Step 4: Make user_id NOT NULL
ALTER TABLE public.startups 
ALTER COLUMN user_id SET NOT NULL;

-- Step 5: Create index
CREATE INDEX idx_startups_user_id ON public.startups(user_id);

-- Step 6: Update RLS policies
-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view startups" ON public.startups;
DROP POLICY IF EXISTS "Authenticated users can create startups" ON public.startups;
DROP POLICY IF EXISTS "Authenticated users can update startups" ON public.startups;

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

-- Step 8: Verification
SELECT '=== VERIFICATION ===' as step;

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
