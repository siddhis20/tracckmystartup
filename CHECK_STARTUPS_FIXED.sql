-- =====================================================
-- CHECK STARTUPS TABLE STRUCTURE AND FIX FOREIGN KEY ISSUE
-- =====================================================

-- First, let's see what columns actually exist in the startups table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups' 
ORDER BY ordinal_position;

-- Check what startups exist in the database
SELECT 
    id,
    name,
    user_id,
    total_funding,
    created_at
FROM startups 
ORDER BY id;

-- Check if there are any startups at all
SELECT COUNT(*) as total_startups FROM startups;

-- Create a default startup with only the columns that exist
-- We'll use a dynamic approach based on what columns are available
DO $$
DECLARE
    has_description BOOLEAN;
    has_industry BOOLEAN;
    has_stage BOOLEAN;
    has_founded_date BOOLEAN;
    default_startup_id INTEGER;
BEGIN
    -- Check which columns exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'startups' AND column_name = 'description'
    ) INTO has_description;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'startups' AND column_name = 'industry'
    ) INTO has_industry;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'startups' AND column_name = 'stage'
    ) INTO has_stage;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'startups' AND column_name = 'founded_date'
    ) INTO has_founded_date;
    
    -- Check if we need to create a startup
    SELECT id INTO default_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF default_startup_id IS NULL THEN
        -- Create startup with only existing columns
        IF has_description AND has_industry AND has_stage AND has_founded_date THEN
            INSERT INTO startups (name, user_id, total_funding, description, industry, stage, founded_date) 
            VALUES 
                ('Default Startup', 
                 (SELECT id FROM auth.users LIMIT 1), 
                 1000000.00, 
                 'Default startup for testing financials', 
                 'Technology', 
                 'Seed', 
                 '2024-01-01')
            RETURNING id INTO default_startup_id;
        ELSIF has_description AND has_industry AND has_stage THEN
            INSERT INTO startups (name, user_id, total_funding, description, industry, stage) 
            VALUES 
                ('Default Startup', 
                 (SELECT id FROM auth.users LIMIT 1), 
                 1000000.00, 
                 'Default startup for testing financials', 
                 'Technology', 
                 'Seed')
            RETURNING id INTO default_startup_id;
        ELSIF has_description AND has_industry THEN
            INSERT INTO startups (name, user_id, total_funding, description, industry) 
            VALUES 
                ('Default Startup', 
                 (SELECT id FROM auth.users LIMIT 1), 
                 1000000.00, 
                 'Default startup for testing financials', 
                 'Technology')
            RETURNING id INTO default_startup_id;
        ELSIF has_description THEN
            INSERT INTO startups (name, user_id, total_funding, description) 
            VALUES 
                ('Default Startup', 
                 (SELECT id FROM auth.users LIMIT 1), 
                 1000000.00, 
                 'Default startup for testing financials')
            RETURNING id INTO default_startup_id;
        ELSE
            -- Basic insert with only required columns
            INSERT INTO startups (name, user_id, total_funding) 
            VALUES 
                ('Default Startup', 
                 (SELECT id FROM auth.users LIMIT 1), 
                 1000000.00)
            RETURNING id INTO default_startup_id;
        END IF;
        
        RAISE NOTICE 'Created default startup with ID: %', default_startup_id;
    ELSE
        RAISE NOTICE 'Startup already exists with ID: %', default_startup_id;
    END IF;
END $$;

-- Get the startup ID to use for financial records
SELECT id as startup_id_to_use FROM startups ORDER BY id LIMIT 1;

-- Show the startup we'll use for financial records
SELECT 'Use this startup ID for financial records:' as instruction, id as startup_id FROM startups ORDER BY id LIMIT 1;
