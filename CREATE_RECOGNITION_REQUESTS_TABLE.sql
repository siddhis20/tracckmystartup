-- Create table to store recognition requests from startup dashboard
-- This will be the source of truth for the Recognition & Incubation Requests table

-- Create the recognition_requests table
CREATE TABLE IF NOT EXISTS public.recognition_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    facilitator_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    program_name VARCHAR(255) NOT NULL,
    incubation_type VARCHAR(100) NOT NULL,
    fee_type VARCHAR(50) NOT NULL,
    fee_amount DECIMAL(15,2),
    equity_allocated DECIMAL(5,2),
    pre_money_valuation DECIMAL(15,2),
    signed_agreement_url TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approval_date TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique startup-facilitator combinations for the same program
    UNIQUE(startup_id, facilitator_id, program_name)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_recognition_requests_startup_id 
ON public.recognition_requests(startup_id);

CREATE INDEX IF NOT EXISTS idx_recognition_requests_facilitator_id 
ON public.recognition_requests(facilitator_id);

CREATE INDEX IF NOT EXISTS idx_recognition_requests_status 
ON public.recognition_requests(status);

CREATE INDEX IF NOT EXISTS idx_recognition_requests_request_date 
ON public.recognition_requests(request_date);

-- Enable RLS
ALTER TABLE public.recognition_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Facilitators can view their own recognition requests
CREATE POLICY "Facilitators can view their own recognition requests" ON public.recognition_requests
    FOR SELECT USING (auth.uid() = facilitator_id);

-- Facilitators can update their own recognition requests
CREATE POLICY "Facilitators can update their own recognition requests" ON public.recognition_requests
    FOR UPDATE USING (auth.uid() = facilitator_id);

-- Startups can view their own recognition requests
CREATE POLICY "Startups can view their own recognition requests" ON public.recognition_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.startups 
            WHERE startups.id = recognition_requests.startup_id 
            AND startups.user_id = auth.uid()
        )
    );

-- Startups can insert their own recognition requests
CREATE POLICY "Startups can insert their own recognition requests" ON public.recognition_requests
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.startups 
            WHERE startups.id = recognition_requests.startup_id 
            AND startups.user_id = auth.uid()
        )
    );

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_recognition_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_recognition_requests_updated_at
    BEFORE UPDATE ON public.recognition_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_recognition_requests_updated_at();

-- Verify the table was created
SELECT '=== RECOGNITION REQUESTS TABLE CREATED ===' as info;
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'recognition_requests'
ORDER BY ordinal_position;
