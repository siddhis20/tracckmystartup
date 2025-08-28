-- Create table to store facilitator-startup relationships
-- This will persist the data even after refresh

-- Create the facilitator_startups table
CREATE TABLE IF NOT EXISTS public.facilitator_startups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    facilitator_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    startup_id INTEGER NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    recognition_record_id INTEGER NOT NULL REFERENCES public.recognition_records(id) ON DELETE CASCADE,
    access_granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'revoked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique facilitator-startup combinations
    UNIQUE(facilitator_id, startup_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_facilitator_startups_facilitator_id 
ON public.facilitator_startups(facilitator_id);

CREATE INDEX IF NOT EXISTS idx_facilitator_startups_startup_id 
ON public.facilitator_startups(startup_id);

CREATE INDEX IF NOT EXISTS idx_facilitator_startups_status 
ON public.facilitator_startups(status);

-- Enable RLS
ALTER TABLE public.facilitator_startups ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Facilitators can only see their own startup relationships
CREATE POLICY "Facilitators can view their own startup relationships" ON public.facilitator_startups
    FOR SELECT USING (auth.uid() = facilitator_id);

-- Facilitators can insert their own startup relationships
CREATE POLICY "Facilitators can insert their own startup relationships" ON public.facilitator_startups
    FOR INSERT WITH CHECK (auth.uid() = facilitator_id);

-- Facilitators can update their own startup relationships
CREATE POLICY "Facilitators can update their own startup relationships" ON public.facilitator_startups
    FOR UPDATE USING (auth.uid() = facilitator_id);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_facilitator_startups_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_facilitator_startups_updated_at
    BEFORE UPDATE ON public.facilitator_startups
    FOR EACH ROW
    EXECUTE FUNCTION update_facilitator_startups_updated_at();

-- Verify the table was created
SELECT '=== FACILITATOR STARTUPS TABLE CREATED ===' as info;
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'facilitator_startups'
ORDER BY ordinal_position;
