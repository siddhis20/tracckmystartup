-- =====================================================
-- FIX MISSING UPDATED_AT COLUMNS
-- =====================================================

-- Add updated_at column to subsidiaries table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'subsidiaries' 
                   AND column_name = 'updated_at') THEN
        ALTER TABLE public.subsidiaries 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to subsidiaries table';
    ELSE
        RAISE NOTICE 'updated_at column already exists in subsidiaries table';
    END IF;
END $$;

-- Add updated_at column to international_ops table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'international_ops' 
                   AND column_name = 'updated_at') THEN
        ALTER TABLE public.international_ops 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to international_ops table';
    ELSE
        RAISE NOTICE 'updated_at column already exists in international_ops table';
    END IF;
END $$;

-- Now recreate the update functions with the correct columns
CREATE OR REPLACE FUNCTION update_subsidiary(
    subsidiary_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.subsidiaries 
    SET 
        country = country_param,
        company_type = company_type_param,
        registration_date = registration_date_param,
        updated_at = NOW()
    WHERE id = subsidiary_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION update_international_op(
    op_id_param INTEGER,
    country_param TEXT,
    start_date_param DATE
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.international_ops 
    SET 
        country = country_param,
        start_date = start_date_param,
        updated_at = NOW()
    WHERE id = op_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the functions
DO $$
DECLARE
    subsidiary_id_val INTEGER;
    update_result BOOLEAN;
BEGIN
    -- Get first subsidiary
    SELECT id INTO subsidiary_id_val FROM subsidiaries ORDER BY id LIMIT 1;
    
    IF subsidiary_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing update_subsidiary with ID: %', subsidiary_id_val;
        
        -- Test update subsidiary
        SELECT update_subsidiary(
            subsidiary_id_val,
            'India',
            'Private Limited Company',
            '2025-01-20'::DATE
        ) INTO update_result;
        
        RAISE NOTICE 'update_subsidiary result: %', update_result;
        
        -- Show the updated data
        PERFORM id, startup_id, country, company_type, registration_date, updated_at
        FROM subsidiaries WHERE id = subsidiary_id_val;
    ELSE
        RAISE NOTICE 'No subsidiaries found for testing';
    END IF;
END $$;
