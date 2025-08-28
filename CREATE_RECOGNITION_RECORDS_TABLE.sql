-- CREATE_RECOGNITION_RECORDS_TABLE.sql
-- This script creates the recognition_records table for storing startup recognition and incubation data

-- Step 1: Create the recognition_records table
CREATE TABLE IF NOT EXISTS public.recognition_records (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER NOT NULL,
    program_name VARCHAR(255) NOT NULL,
    facilitator_name VARCHAR(255) NOT NULL,
    facilitator_code VARCHAR(50) NOT NULL,
    incubation_type VARCHAR(100) NOT NULL,
    fee_type VARCHAR(50) NOT NULL,
    fee_amount DECIMAL(15,2),
    equity_allocated DECIMAL(5,2),
    pre_money_valuation DECIMAL(15,2),
    signed_agreement_url TEXT,
    date_added DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Add foreign key constraint to startups table
ALTER TABLE public.recognition_records 
ADD CONSTRAINT fk_recognition_records_startup_id 
FOREIGN KEY (startup_id) REFERENCES public.startups(id) ON DELETE CASCADE;

-- Step 3: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_recognition_records_startup_id ON public.recognition_records(startup_id);
CREATE INDEX IF NOT EXISTS idx_recognition_records_facilitator_code ON public.recognition_records(facilitator_code);
CREATE INDEX IF NOT EXISTS idx_recognition_records_date_added ON public.recognition_records(date_added);

-- Step 4: Add RLS (Row Level Security) policies
ALTER TABLE public.recognition_records ENABLE ROW LEVEL SECURITY;

-- Policy for startups to view their own records
CREATE POLICY "Startups can view own recognition records" ON public.recognition_records
    FOR SELECT USING (startup_id IN (
        SELECT s.id FROM public.startups s 
        JOIN public.users u ON s.name = u.startup_name 
        WHERE u.id = auth.uid()
    ));

-- Policy for startups to insert their own records
CREATE POLICY "Startups can insert own recognition records" ON public.recognition_records
    FOR INSERT WITH CHECK (startup_id IN (
        SELECT s.id FROM public.startups s 
        JOIN public.users u ON s.name = u.startup_name 
        WHERE u.id = auth.uid()
    ));

-- Policy for startups to update their own records
CREATE POLICY "Startups can update own recognition records" ON public.recognition_records
    FOR UPDATE USING (startup_id IN (
        SELECT s.id FROM public.startups s 
        JOIN public.users u ON s.name = u.startup_name 
        WHERE u.id = auth.uid()
    ));

-- Policy for startups to delete their own records
CREATE POLICY "Startups can delete own recognition records" ON public.recognition_records
    FOR DELETE USING (startup_id IN (
        SELECT s.id FROM public.startups s 
        JOIN public.users u ON s.name = u.startup_name 
        WHERE u.id = auth.uid()
    ));

-- Policy for facilitators to view records where they are the facilitator
CREATE POLICY "Facilitators can view records where they are facilitator" ON public.recognition_records
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users u 
            WHERE u.facilitator_code = recognition_records.facilitator_code 
            AND u.id = auth.uid()
        )
    );

-- Step 5: Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_recognition_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create trigger to automatically update updated_at
CREATE TRIGGER trigger_update_recognition_records_updated_at
    BEFORE UPDATE ON public.recognition_records
    FOR EACH ROW
    EXECUTE FUNCTION update_recognition_records_updated_at();

-- Step 7: Verify the table structure
SELECT '=== RECOGNITION_RECORDS TABLE STRUCTURE ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'recognition_records'
ORDER BY ordinal_position;

-- Step 8: Test the table with sample data
SELECT '=== TESTING TABLE WITH SAMPLE DATA ===' as info;

-- Insert a sample record (this will be removed after testing)
INSERT INTO public.recognition_records (
    startup_id, 
    program_name, 
    facilitator_name, 
    facilitator_code, 
    incubation_type, 
    fee_type, 
    date_added
) VALUES (
    11, -- Assuming startup ID 11 exists
    'Sample Incubation Program',
    'Sample Facilitator',
    'FAC-SAMPLE',
    'Incubation Center',
    'Free',
    CURRENT_DATE
);

-- Verify the sample data
SELECT * FROM public.recognition_records WHERE facilitator_code = 'FAC-SAMPLE';

-- Clean up sample data
DELETE FROM public.recognition_records WHERE facilitator_code = 'FAC-SAMPLE';

SELECT '=== RECOGNITION_RECORDS TABLE SETUP COMPLETE ===' as info;
