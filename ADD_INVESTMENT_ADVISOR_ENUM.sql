-- Quick fix: Add Investment Advisor to user_role enum
-- Run this first if you're getting the enum error

DO $$ 
BEGIN
    -- Add 'Investment Advisor' to the user_role enum if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'Investment Advisor' 
        AND enumtypid = (
            SELECT oid FROM pg_type WHERE typname = 'user_role'
        )
    ) THEN
        ALTER TYPE user_role ADD VALUE 'Investment Advisor';
        RAISE NOTICE 'Successfully added "Investment Advisor" to user_role enum';
    ELSE
        RAISE NOTICE '"Investment Advisor" already exists in user_role enum';
    END IF;
END $$;
