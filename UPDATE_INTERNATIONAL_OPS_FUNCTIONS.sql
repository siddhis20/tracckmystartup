-- Update international operations functions to include company_type field
-- This allows international operations to have specific compliance rules based on company type

-- Update the add_international_op function
CREATE OR REPLACE FUNCTION add_international_op(
    startup_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    start_date_param DATE
)
RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO public.international_ops (
        startup_id,
        country,
        company_type,
        start_date,
        created_at,
        updated_at
    ) VALUES (
        startup_id_param,
        country_param,
        company_type_param,
        start_date_param,
        NOW(),
        NOW()
    ) RETURNING id INTO new_id;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the update_international_op function
CREATE OR REPLACE FUNCTION update_international_op(
    op_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    start_date_param DATE
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.international_ops 
    SET 
        country = country_param,
        company_type = company_type_param,
        start_date = start_date_param,
        updated_at = NOW()
    WHERE id = op_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the add_international_op_simple function (for backward compatibility)
CREATE OR REPLACE FUNCTION add_international_op_simple(
    startup_id_param INTEGER,
    country_param TEXT,
    start_date_param DATE
)
RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO public.international_ops (
        startup_id,
        country,
        company_type,
        start_date,
        created_at,
        updated_at
    ) VALUES (
        startup_id_param,
        country_param,
        'default', -- Default company type for simple function
        start_date_param,
        NOW(),
        NOW()
    ) RETURNING id INTO new_id;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add company_type column to international_ops table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'international_ops' 
        AND column_name = 'company_type'
    ) THEN
        ALTER TABLE public.international_ops 
        ADD COLUMN company_type TEXT DEFAULT 'default';
    END IF;
END $$;
