-- =====================================================
-- CLEANUP AND FIX SCRIPT
-- =====================================================
-- Run this if the user_id column already exists but has issues

-- Step 1: Check if user_id column exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'startups' AND column_name = 'user_id'
    ) THEN
        RAISE NOTICE 'user_id column already exists';
        
        -- Check if there are null values
        IF EXISTS (SELECT 1 FROM public.startups WHERE user_id IS NULL) THEN
            RAISE NOTICE 'Found startups with null user_id, fixing...';
            
            -- Get the first available user
            UPDATE public.startups 
            SET user_id = (
                SELECT id FROM public.users 
                WHERE role = 'Admin' 
                LIMIT 1
            )
            WHERE user_id IS NULL;
            
            -- If no admin user, use any user
            IF NOT FOUND THEN
                UPDATE public.startups 
                SET user_id = (SELECT id FROM public.users LIMIT 1)
                WHERE user_id IS NULL;
            END IF;
        END IF;
        
        -- Make sure it's NOT NULL
        ALTER TABLE public.startups ALTER COLUMN user_id SET NOT NULL;
        
    ELSE
        RAISE NOTICE 'user_id column does not exist, creating...';
        
        -- Add the column
        ALTER TABLE public.startups 
        ADD COLUMN user_id UUID REFERENCES public.users(id) ON DELETE CASCADE;
        
        -- Assign user_id to existing startups
        UPDATE public.startups 
        SET user_id = (
            SELECT id FROM public.users 
            WHERE role = 'Admin' 
            LIMIT 1
        )
        WHERE user_id IS NULL;
        
        -- If no admin user, use any user
        IF NOT FOUND THEN
            UPDATE public.startups 
            SET user_id = (SELECT id FROM public.users LIMIT 1)
            WHERE user_id IS NULL;
        END IF;
        
        -- Make it NOT NULL
        ALTER TABLE public.startups ALTER COLUMN user_id SET NOT NULL;
    END IF;
END $$;

-- Step 2: Create index if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_startups_user_id ON public.startups(user_id);

-- Step 3: Update RLS policies
DROP POLICY IF EXISTS "Anyone can view startups" ON public.startups;
DROP POLICY IF EXISTS "Authenticated users can manage startups" ON public.startups;
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

-- Step 4: Enable RLS
ALTER TABLE public.startups ENABLE ROW LEVEL SECURITY;

-- Step 5: Verification
SELECT 'Migration completed successfully!' as status;

-- Check final state
SELECT COUNT(*) as total_startups, 
       COUNT(user_id) as startups_with_user_id,
       COUNT(*) - COUNT(user_id) as startups_without_user_id
FROM public.startups;
