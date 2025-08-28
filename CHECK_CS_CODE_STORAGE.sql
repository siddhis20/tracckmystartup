-- Check CS code storage in database
-- This script will help debug where CS codes are being stored

-- Check startups table for CS codes
SELECT 
    id,
    name,
    cs_service_code,
    ca_service_code,
    country_of_registration,
    company_type,
    registration_date,
    updated_at
FROM public.startups 
ORDER BY updated_at DESC;

-- Check if CS codes exist in startups table
SELECT 
    'Startups with CS codes' as check_type,
    COUNT(*) as count,
    COUNT(cs_service_code) as cs_codes_count,
    COUNT(ca_service_code) as ca_codes_count
FROM public.startups;

-- Check specific startup (replace with your startup name)
SELECT 
    id,
    name,
    cs_service_code,
    ca_service_code,
    country_of_registration,
    company_type,
    registration_date,
    updated_at
FROM public.startups 
WHERE name LIKE '%Mulsetu%' OR name LIKE '%Test%'
ORDER BY updated_at DESC;

-- Check cs_assignment_requests table
SELECT 
    id,
    startup_id,
    startup_name,
    cs_code,
    status,
    request_date,
    notes
FROM public.cs_assignment_requests 
ORDER BY request_date DESC;

-- Check if there are any CS assignment requests
SELECT 
    'CS Assignment Requests' as check_type,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
    COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_requests,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_requests
FROM public.cs_assignment_requests;

-- Check cs_assignments table
SELECT 
    id,
    startup_id,
    cs_code,
    status,
    assignment_date,
    notes
FROM public.cs_assignments 
ORDER BY assignment_date DESC;

-- Check if there are any CS assignments
SELECT 
    'CS Assignments' as check_type,
    COUNT(*) as total_assignments,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_assignments,
    COUNT(CASE WHEN status = 'inactive' THEN 1 END) as inactive_assignments
FROM public.cs_assignments;
