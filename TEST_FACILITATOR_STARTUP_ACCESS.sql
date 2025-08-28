-- Test script to verify facilitator startup access system
-- Run this after creating the facilitator_startups table

-- 1. Check if the facilitator_startups table exists
SELECT '=== FACILITATOR STARTUPS TABLE ===' as info;
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'facilitator_startups'
ORDER BY ordinal_position;

-- 2. Check if there are any existing facilitator-startup relationships
SELECT '=== EXISTING FACILITATOR-STARTUP RELATIONSHIPS ===' as info;
SELECT 
    fs.id,
    fs.facilitator_id,
    fs.startup_id,
    fs.recognition_record_id,
    fs.status,
    fs.access_granted_at,
    u.email as facilitator_email,
    s.name as startup_name
FROM public.facilitator_startups fs
JOIN public.users u ON fs.facilitator_id = u.id
JOIN public.startups s ON fs.startup_id = s.id
ORDER BY fs.created_at DESC;

-- 3. Check recognition records that are approved
SELECT '=== APPROVED RECOGNITION RECORDS ===' as info;
SELECT 
    rr.id,
    rr.startup_id,
    rr.program_name,
    rr.facilitator_code,
    rr.status,
    s.name as startup_name,
    s.current_valuation,
    s.compliance_status
FROM public.recognition_records rr
JOIN public.startups s ON rr.startup_id = s.id
WHERE rr.status = 'approved'
ORDER BY rr.created_at DESC;

-- 4. Test the data that would be fetched for portfolio
SELECT '=== PORTFOLIO DATA TEST ===' as info;
SELECT 
    s.id,
    s.name,
    s.sector,
    s.current_valuation,
    s.compliance_status,
    s.total_funding,
    s.total_revenue,
    s.registration_date
FROM public.startups s
WHERE s.id IN (
    SELECT DISTINCT startup_id 
    FROM public.facilitator_startups 
    WHERE status = 'active'
)
ORDER BY s.name;

-- 5. Check cap table data for current valuation
SELECT '=== CAP TABLE DATA FOR VALUATION ===' as info;
SELECT 
    ct.startup_id,
    s.name as startup_name,
    ct.post_money_valuation,
    ct.created_at,
    ROW_NUMBER() OVER (PARTITION BY ct.startup_id ORDER BY ct.created_at DESC) as rn
FROM public.cap_table ct
JOIN public.startups s ON ct.startup_id = s.id
WHERE ct.startup_id IN (
    SELECT DISTINCT startup_id 
    FROM public.facilitator_startups 
    WHERE status = 'active'
)
ORDER BY ct.startup_id, ct.created_at DESC;

-- 6. Check compliance tasks for overall status
SELECT '=== COMPLIANCE TASKS FOR STATUS ===' as info;
SELECT 
    ct.startup_id,
    s.name as startup_name,
    ct.status as task_status,
    ct.due_date,
    COUNT(*) OVER (PARTITION BY ct.startup_id) as total_tasks,
    COUNT(*) FILTER (WHERE ct.status = 'completed') OVER (PARTITION BY ct.startup_id) as completed_tasks,
    COUNT(*) FILTER (WHERE ct.status = 'pending') OVER (PARTITION BY ct.startup_id) as pending_tasks
FROM public.compliance_tasks ct
JOIN public.startups s ON ct.startup_id = s.id
WHERE ct.startup_id IN (
    SELECT DISTINCT startup_id 
    FROM public.facilitator_startups 
    WHERE status = 'active'
)
ORDER BY ct.startup_id, ct.due_date;

-- 7. Check if RLS policies are working
SELECT '=== RLS POLICIES CHECK ===' as info;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'facilitator_startups';
