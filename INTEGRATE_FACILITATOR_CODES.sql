-- =====================================================
-- INTEGRATE FACILITATOR CODES INTO OPPORTUNITIES SYSTEM
-- =====================================================
-- This script integrates the unique facilitator codes into the existing opportunities logic

-- 1. Update incubation_opportunities to include facilitator_code
ALTER TABLE public.incubation_opportunities 
ADD COLUMN IF NOT EXISTS facilitator_code VARCHAR(10);

-- 2. Create function to automatically set facilitator_code when posting opportunities
CREATE OR REPLACE FUNCTION set_facilitator_code_on_opportunity()
RETURNS TRIGGER AS $$
BEGIN
    -- Get the facilitator code for the posting facilitator
    SELECT facilitator_code INTO NEW.facilitator_code
    FROM users 
    WHERE id = NEW.facilitator_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create trigger to automatically set facilitator_code
DROP TRIGGER IF EXISTS auto_set_facilitator_code ON public.incubation_opportunities;
CREATE TRIGGER auto_set_facilitator_code
    BEFORE INSERT ON public.incubation_opportunities
    FOR EACH ROW
    EXECUTE FUNCTION set_facilitator_code_on_opportunity();

-- 4. Update existing opportunities with facilitator codes
UPDATE public.incubation_opportunities 
SET facilitator_code = (
    SELECT u.facilitator_code 
    FROM users u 
    WHERE u.id = incubation_opportunities.facilitator_id
)
WHERE facilitator_code IS NULL;

-- 5. Create function to get opportunities with facilitator codes
CREATE OR REPLACE FUNCTION get_opportunities_with_codes()
RETURNS TABLE (
    id UUID,
    facilitator_id UUID,
    facilitator_code VARCHAR(10),
    facilitator_name TEXT,
    program_name TEXT,
    description TEXT,
    deadline DATE,
    poster_url TEXT,
    video_url TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        io.id,
        io.facilitator_id,
        io.facilitator_code,
        u.name as facilitator_name,
        io.program_name,
        io.description,
        io.deadline,
        io.poster_url,
        io.video_url,
        io.created_at
    FROM public.incubation_opportunities io
    LEFT JOIN users u ON io.facilitator_id = u.id
    ORDER BY io.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create function to get applications with facilitator codes
CREATE OR REPLACE FUNCTION get_applications_with_codes()
RETURNS TABLE (
    id UUID,
    opportunity_id UUID,
    startup_id BIGINT,
    startup_name TEXT,
    facilitator_code VARCHAR(10),
    facilitator_name TEXT,
    program_name TEXT,
    status TEXT,
    diligence_status TEXT,
    agreement_url TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        oa.id,
        oa.opportunity_id,
        oa.startup_id,
        s.name as startup_name,
        io.facilitator_code,
        u.name as facilitator_name,
        io.program_name,
        oa.status,
        oa.diligence_status,
        oa.agreement_url,
        oa.created_at
    FROM public.opportunity_applications oa
    JOIN public.incubation_opportunities io ON oa.opportunity_id = io.id
    JOIN public.startups s ON oa.startup_id = s.id
    LEFT JOIN users u ON io.facilitator_id = u.id
    ORDER BY oa.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Grant permissions
GRANT EXECUTE ON FUNCTION get_opportunities_with_codes() TO authenticated;
GRANT EXECUTE ON FUNCTION get_applications_with_codes() TO authenticated;

-- 8. Show current opportunities with facilitator codes
SELECT 'CURRENT OPPORTUNITIES WITH FACILITATOR CODES:' as info;
SELECT 
    io.id,
    io.program_name,
    io.facilitator_code,
    u.name as facilitator_name,
    io.created_at
FROM public.incubation_opportunities io
LEFT JOIN users u ON io.facilitator_id = u.id
ORDER BY io.created_at DESC;

-- 9. Show current applications with facilitator codes
SELECT 'CURRENT APPLICATIONS WITH FACILITATOR CODES:' as info;
SELECT 
    oa.id,
    s.name as startup_name,
    io.program_name,
    io.facilitator_code,
    oa.status,
    oa.diligence_status
FROM public.opportunity_applications oa
JOIN public.incubation_opportunities io ON oa.opportunity_id = io.id
JOIN public.startups s ON oa.startup_id = s.id
ORDER BY oa.created_at DESC;

-- 10. Summary
SELECT 'FACILITATOR CODES INTEGRATED INTO OPPORTUNITIES SYSTEM' as summary;
SELECT 
    '✅ Opportunities now include facilitator codes' as feature_1,
    '✅ Applications show facilitator codes' as feature_2,
    '✅ All existing logic preserved' as feature_3,
    '✅ Ready for frontend integration' as status;
