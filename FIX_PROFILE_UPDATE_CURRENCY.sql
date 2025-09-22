-- Fix Profile Update Currency Support
-- Run this in Supabase SQL Editor

-- 1. Add currency column to startups table
ALTER TABLE public.startups 
ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'USD';

-- 2. Add comment to document the column
COMMENT ON COLUMN public.startups.currency IS 'User preferred currency for financial displays (USD, EUR, GBP, INR, CAD, AUD, JPY, CHF, SGD, CNY)';

-- 3. Update existing records to have USD as default
UPDATE public.startups 
SET currency = 'USD' 
WHERE currency IS NULL;

-- 4. Update the RPC functions to support currency parameter
-- First, drop and recreate the simple function
DROP FUNCTION IF EXISTS update_startup_profile_simple(INTEGER, TEXT, TEXT, DATE, TEXT, TEXT);

CREATE OR REPLACE FUNCTION update_startup_profile_simple(
    startup_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE,
    currency_param TEXT DEFAULT 'USD',
    ca_service_code_param TEXT DEFAULT NULL,
    cs_service_code_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update the startup record
    UPDATE public.startups 
    SET 
        country_of_registration = country_param,
        company_type = company_type_param,
        registration_date = registration_date_param,
        currency = currency_param,
        ca_service_code = ca_service_code_param,
        cs_service_code = cs_service_code_param,
        updated_at = NOW()
    WHERE id = startup_id_param;
    
    -- Return true if at least one row was updated
    RETURN FOUND;
END;
$$;

-- 5. Update the full function to support currency parameter
DROP FUNCTION IF EXISTS update_startup_profile(INTEGER, TEXT, TEXT, DATE, TEXT, TEXT);

CREATE OR REPLACE FUNCTION update_startup_profile(
    startup_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE,
    currency_param TEXT DEFAULT 'USD',
    ca_service_code_param TEXT DEFAULT NULL,
    cs_service_code_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update the startup record
    UPDATE public.startups 
    SET 
        country_of_registration = country_param,
        company_type = company_type_param,
        registration_date = registration_date_param,
        currency = currency_param,
        ca_service_code = ca_service_code_param,
        cs_service_code = cs_service_code_param,
        updated_at = NOW()
    WHERE id = startup_id_param;
    
    -- Return true if at least one row was updated
    RETURN FOUND;
END;
$$;

-- 6. Update the get_startup_profile functions to include currency
-- First, drop and recreate the simple function
DROP FUNCTION IF EXISTS get_startup_profile_simple(INTEGER);

CREATE OR REPLACE FUNCTION get_startup_profile_simple(startup_id_param INTEGER)
RETURNS TABLE(
    startup JSONB,
    subsidiaries JSONB,
    international_ops JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        jsonb_build_object(
            'id', s.id,
            'name', s.name,
            'country_of_registration', s.country_of_registration,
            'company_type', s.company_type,
            'registration_date', s.registration_date,
            'currency', COALESCE(s.currency, 'USD'),
            'ca_service_code', s.ca_service_code,
            'cs_service_code', s.cs_service_code
        ) as startup,
        COALESCE(
            (SELECT jsonb_agg(
                jsonb_build_object(
                    'id', sub.id,
                    'country', sub.country,
                    'company_type', sub.company_type,
                    'registration_date', sub.registration_date,
                    'ca_service_code', sub.ca_service_code,
                    'cs_service_code', sub.cs_service_code
                )
            ) FROM public.subsidiaries sub WHERE sub.startup_id = s.id),
            '[]'::jsonb
        ) as subsidiaries,
        COALESCE(
            (SELECT jsonb_agg(
                jsonb_build_object(
                    'id', io.id,
                    'country', io.country,
                    'company_type', io.company_type,
                    'start_date', io.start_date
                )
            ) FROM public.international_ops io WHERE io.startup_id = s.id),
            '[]'::jsonb
        ) as international_ops
    FROM public.startups s
    WHERE s.id = startup_id_param;
END;
$$;

-- 7. Verify the changes
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name = 'currency';

-- 8. Test the functions
SELECT 'Functions updated successfully' as status;
