-- =====================================================
-- TEST FACILITATOR CODE SYSTEM
-- =====================================================

-- 1. Check if facilitator_code column exists
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'facilitator_code';

-- 2. Check current facilitators
SELECT 
    id,
    name,
    email,
    role,
    facilitator_code
FROM users 
WHERE role = 'Startup Facilitation Center'
ORDER BY name;

-- 3. Test code generation function
SELECT generate_facilitator_code() as new_code;

-- 4. Test assigning code to a facilitator (replace with actual facilitator ID)
-- SELECT assign_facilitator_code('your-facilitator-id-here');

-- 5. Check if compliance_access table exists
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'compliance_access'
ORDER BY ordinal_position;

-- 6. Test RPC functions exist
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN (
    'generate_facilitator_code',
    'assign_facilitator_code',
    'get_facilitator_code',
    'get_facilitator_by_code',
    'grant_compliance_access',
    'has_compliance_access'
)
ORDER BY routine_name;
