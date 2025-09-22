-- =====================================================
-- IP/TRADEMARK TABLE SETUP
-- =====================================================
-- This script creates the necessary table for IP/trademark records
-- in the compliance system

-- Create IP/trademark records table
CREATE TABLE IF NOT EXISTS public.ip_trademark_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('Trademark', 'Patent', 'Copyright', 'Trade Secret', 'Domain Name', 'Other')),
    name TEXT NOT NULL,
    description TEXT,
    registration_number TEXT,
    registration_date DATE,
    expiry_date DATE,
    jurisdiction TEXT NOT NULL, -- Country or region where registered
    status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Pending', 'Expired', 'Abandoned', 'Cancelled')),
    owner TEXT, -- Who owns the IP (company name or individual)
    filing_date DATE,
    priority_date DATE,
    renewal_date DATE,
    estimated_value DECIMAL(15,2), -- Estimated monetary value
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create IP/trademark document uploads table
CREATE TABLE IF NOT EXISTS public.ip_trademark_documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ip_record_id UUID NOT NULL REFERENCES public.ip_trademark_records(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    document_type TEXT NOT NULL CHECK (document_type IN ('Registration Certificate', 'Application Form', 'Renewal Document', 'Assignment Agreement', 'License Agreement', 'Other')),
    uploaded_by TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ip_trademark_records_startup_id ON public.ip_trademark_records(startup_id);
CREATE INDEX IF NOT EXISTS idx_ip_trademark_records_type ON public.ip_trademark_records(type);
CREATE INDEX IF NOT EXISTS idx_ip_trademark_records_status ON public.ip_trademark_records(status);
CREATE INDEX IF NOT EXISTS idx_ip_trademark_records_jurisdiction ON public.ip_trademark_records(jurisdiction);
CREATE INDEX IF NOT EXISTS idx_ip_trademark_documents_ip_record_id ON public.ip_trademark_documents(ip_record_id);

-- Enable Row Level Security
ALTER TABLE public.ip_trademark_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ip_trademark_documents ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (adjust based on your existing auth setup)
-- These policies allow users to access records for startups they have access to
CREATE POLICY "Users can view IP records for their startups" ON public.ip_trademark_records
    FOR SELECT USING (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert IP records for their startups" ON public.ip_trademark_records
    FOR INSERT WITH CHECK (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update IP records for their startups" ON public.ip_trademark_records
    FOR UPDATE USING (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete IP records for their startups" ON public.ip_trademark_records
    FOR DELETE USING (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

-- Similar policies for documents table
CREATE POLICY "Users can view IP documents for their startups" ON public.ip_trademark_documents
    FOR SELECT USING (
        ip_record_id IN (
            SELECT id FROM public.ip_trademark_records 
            WHERE startup_id IN (
                SELECT id FROM public.startups 
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can insert IP documents for their startups" ON public.ip_trademark_documents
    FOR INSERT WITH CHECK (
        ip_record_id IN (
            SELECT id FROM public.ip_trademark_records 
            WHERE startup_id IN (
                SELECT id FROM public.startups 
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can update IP documents for their startups" ON public.ip_trademark_documents
    FOR UPDATE USING (
        ip_record_id IN (
            SELECT id FROM public.ip_trademark_records 
            WHERE startup_id IN (
                SELECT id FROM public.startups 
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can delete IP documents for their startups" ON public.ip_trademark_documents
    FOR DELETE USING (
        ip_record_id IN (
            SELECT id FROM public.ip_trademark_records 
            WHERE startup_id IN (
                SELECT id FROM public.startups 
                WHERE user_id = auth.uid()
            )
        )
    );

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_ip_trademark_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ip_trademark_updated_at
    BEFORE UPDATE ON public.ip_trademark_records
    FOR EACH ROW
    EXECUTE FUNCTION update_ip_trademark_updated_at();

