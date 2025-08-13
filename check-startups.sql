-- =====================================================
-- CHECK EXISTING STARTUPS
-- =====================================================

-- Check what startups exist in the database
SELECT 'Available startups in database:' as info;
SELECT 
    id,
    name,
    sector,
    total_funding,
    registration_date,
    country_of_registration,
    company_type,
    ca_service_code,
    cs_service_code
FROM startups 
ORDER BY id;

-- Check if the startups table has the new profile columns
SELECT 'Startups table structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if profile functions exist
SELECT 'Profile functions available:' as info;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%profile%'
ORDER BY routine_name;

-- Check if profile tables exist
SELECT 'Profile tables available:' as info;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%profile%'
ORDER BY table_name;
