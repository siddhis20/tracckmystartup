-- =====================================================
-- FINAL SUPABASE SETUP FOR STARTUP NATION APP
-- =====================================================
-- Run this in your Supabase SQL Editor to set up the complete database

-- =====================================================
-- STEP 1: CLEAN UP EXISTING DATA (if any)
-- =====================================================

-- Drop all existing tables (if they exist)
DROP TABLE IF EXISTS public.investment_offers CASCADE;
DROP TABLE IF EXISTS public.verification_requests CASCADE;
DROP TABLE IF EXISTS public.startup_addition_requests CASCADE;
DROP TABLE IF EXISTS public.new_investments CASCADE;
DROP TABLE IF EXISTS public.investment_records CASCADE;
DROP TABLE IF EXISTS public.employees CASCADE;
DROP TABLE IF EXISTS public.financial_records CASCADE;
DROP TABLE IF EXISTS public.international_ops CASCADE;
DROP TABLE IF EXISTS public.subsidiaries CASCADE;
DROP TABLE IF EXISTS public.founders CASCADE;
DROP TABLE IF EXISTS public.startups CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Drop all existing types
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS investment_type CASCADE;
DROP TYPE IF EXISTS compliance_status CASCADE;
DROP TYPE IF EXISTS investor_type CASCADE;
DROP TYPE IF EXISTS investment_round_type CASCADE;
DROP TYPE IF EXISTS esop_allocation_type CASCADE;
DROP TYPE IF EXISTS offer_status CASCADE;

-- =====================================================
-- STEP 2: CREATE ENUM TYPES (matching your types.ts exactly)
-- =====================================================

-- User roles (matching UserRole type)
CREATE TYPE user_role AS ENUM (
    'Investor',
    'Startup', 
    'CA',
    'CS',
    'Admin',
    'Startup Facilitation Center'
);

-- Investment types (matching InvestmentType enum)
CREATE TYPE investment_type AS ENUM (
    'Pre-Seed',
    'Seed',
    'Series A',
    'Series B',
    'Bridge'
);

-- Compliance status (matching ComplianceStatus enum)
CREATE TYPE compliance_status AS ENUM (
    'Compliant',
    'Pending',
    'Non-Compliant'
);

-- Investor types (matching InvestorType enum)
CREATE TYPE investor_type AS ENUM (
    'Angel',
    'VC Firm',
    'Corporate',
    'Government'
);

-- Investment round types (matching InvestmentRoundType enum)
CREATE TYPE investment_round_type AS ENUM (
    'Equity',
    'Debt',
    'Grant'
);

-- ESOP allocation types (matching your Employee interface)
CREATE TYPE esop_allocation_type AS ENUM (
    'one-time',
    'annually',
    'quarterly',
    'monthly'
);

-- Offer status (matching InvestmentOffer interface)
CREATE TYPE offer_status AS ENUM (
    'pending',
    'approved',
    'rejected'
);

-- =====================================================
-- STEP 3: CREATE TABLES (matching your interfaces exactly)
-- =====================================================

-- Users table (matching User interface)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'Investor',
    registration_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Startups table (matching Startup interface)
CREATE TABLE public.startups (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    investment_type investment_type NOT NULL,
    investment_value DECIMAL(15,2) NOT NULL,
    equity_allocation DECIMAL(5,2) NOT NULL,
    current_valuation DECIMAL(15,2) NOT NULL,
    compliance_status compliance_status DEFAULT 'Pending',
    sector TEXT NOT NULL,
    total_funding DECIMAL(15,2) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    registration_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Founders table (matching Founder interface)
CREATE TABLE public.founders (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER REFERENCES public.startups(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subsidiaries table (matching Subsidiary interface)
CREATE TABLE public.subsidiaries (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER REFERENCES public.startups(id) ON DELETE CASCADE,
    country TEXT NOT NULL,
    company_type TEXT NOT NULL,
    registration_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- International operations table (matching InternationalOp interface)
CREATE TABLE public.international_ops (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER REFERENCES public.startups(id) ON DELETE CASCADE,
    country TEXT NOT NULL,
    start_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Financial records table (matching FinancialRecord interface)
CREATE TABLE public.financial_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER REFERENCES public.startups(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    entity TEXT NOT NULL,
    description TEXT NOT NULL,
    vertical TEXT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    funding_source TEXT,
    cogs DECIMAL(15,2),
    attachment_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Employees table (matching Employee interface)
CREATE TABLE public.employees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER REFERENCES public.startups(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    joining_date DATE NOT NULL,
    entity TEXT NOT NULL,
    department TEXT NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    esop_allocation DECIMAL(10,2) DEFAULT 0,
    allocation_type esop_allocation_type DEFAULT 'one-time',
    esop_per_allocation DECIMAL(10,2) DEFAULT 0,
    contract_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Investment records table (matching InvestmentRecord interface)
CREATE TABLE public.investment_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER REFERENCES public.startups(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    investor_type investor_type NOT NULL,
    investment_type investment_round_type NOT NULL,
    investor_name TEXT NOT NULL,
    investor_code TEXT,
    amount DECIMAL(15,2) NOT NULL,
    equity_allocated DECIMAL(5,2) NOT NULL,
    pre_money_valuation DECIMAL(15,2) NOT NULL,
    proof_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- New investments table (matching NewInvestment interface)
CREATE TABLE public.new_investments (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    investment_type investment_type NOT NULL,
    investment_value DECIMAL(15,2) NOT NULL,
    equity_allocation DECIMAL(5,2) NOT NULL,
    sector TEXT NOT NULL,
    total_funding DECIMAL(15,2) NOT NULL,
    total_revenue DECIMAL(15,2) NOT NULL,
    registration_date DATE NOT NULL,
    pitch_deck_url TEXT,
    pitch_video_url TEXT,
    compliance_status compliance_status DEFAULT 'Pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Startup addition requests table (matching StartupAdditionRequest interface)
CREATE TABLE public.startup_addition_requests (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    investment_type investment_type NOT NULL,
    investment_value DECIMAL(15,2) NOT NULL,
    equity_allocation DECIMAL(5,2) NOT NULL,
    sector TEXT NOT NULL,
    total_funding DECIMAL(15,2) NOT NULL,
    total_revenue DECIMAL(15,2) NOT NULL,
    registration_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Verification requests table (matching VerificationRequest interface)
CREATE TABLE public.verification_requests (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER REFERENCES public.startups(id) ON DELETE CASCADE,
    startup_name TEXT NOT NULL,
    request_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Investment offers table (matching InvestmentOffer interface)
CREATE TABLE public.investment_offers (
    id SERIAL PRIMARY KEY,
    investor_email TEXT NOT NULL,
    startup_name TEXT NOT NULL,
    investment_id INTEGER REFERENCES public.new_investments(id) ON DELETE CASCADE,
    offer_amount DECIMAL(15,2) NOT NULL,
    equity_percentage DECIMAL(5,2) NOT NULL,
    status offer_status DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 4: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Users indexes
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role);

-- Startups indexes
CREATE INDEX idx_startups_sector ON public.startups(sector);
CREATE INDEX idx_startups_compliance_status ON public.startups(compliance_status);
CREATE INDEX idx_startups_investment_type ON public.startups(investment_type);

-- Founders indexes
CREATE INDEX idx_founders_startup_id ON public.founders(startup_id);

-- Subsidiaries indexes
CREATE INDEX idx_subsidiaries_startup_id ON public.subsidiaries(startup_id);

-- International ops indexes
CREATE INDEX idx_international_ops_startup_id ON public.international_ops(startup_id);

-- Financial records indexes
CREATE INDEX idx_financial_records_startup_id ON public.financial_records(startup_id);
CREATE INDEX idx_financial_records_date ON public.financial_records(date);

-- Employees indexes
CREATE INDEX idx_employees_startup_id ON public.employees(startup_id);

-- Investment records indexes
CREATE INDEX idx_investment_records_startup_id ON public.investment_records(startup_id);

-- New investments indexes
CREATE INDEX idx_new_investments_compliance_status ON public.new_investments(compliance_status);
CREATE INDEX idx_new_investments_sector ON public.new_investments(sector);

-- Investment offers indexes
CREATE INDEX idx_investment_offers_status ON public.investment_offers(status);
CREATE INDEX idx_investment_offers_investor_email ON public.investment_offers(investor_email);

-- =====================================================
-- STEP 5: CREATE TRIGGERS
-- =====================================================

-- Updated timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_startups_updated_at 
    BEFORE UPDATE ON public.startups 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- STEP 6: ENABLE ROW LEVEL SECURITY
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.startups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.founders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subsidiaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.international_ops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.new_investments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.startup_addition_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investment_offers ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 7: CREATE RLS POLICIES
-- =====================================================

-- Users policies
CREATE POLICY "Users can manage their own profile" ON public.users
    FOR ALL USING (auth.uid() = id);

-- Startups policies (anyone can view, authenticated users can create)
CREATE POLICY "Anyone can view startups" ON public.startups
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create startups" ON public.startups
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update startups" ON public.startups
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Founders policies
CREATE POLICY "Anyone can view founders" ON public.founders
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage founders" ON public.founders
    FOR ALL USING (auth.role() = 'authenticated');

-- Subsidiaries policies
CREATE POLICY "Anyone can view subsidiaries" ON public.subsidiaries
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage subsidiaries" ON public.subsidiaries
    FOR ALL USING (auth.role() = 'authenticated');

-- International ops policies
CREATE POLICY "Anyone can view international ops" ON public.international_ops
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage international ops" ON public.international_ops
    FOR ALL USING (auth.role() = 'authenticated');

-- Financial records policies
CREATE POLICY "Anyone can view financial records" ON public.financial_records
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage financial records" ON public.financial_records
    FOR ALL USING (auth.role() = 'authenticated');

-- Employees policies
CREATE POLICY "Anyone can view employees" ON public.employees
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage employees" ON public.employees
    FOR ALL USING (auth.role() = 'authenticated');

-- Investment records policies
CREATE POLICY "Anyone can view investment records" ON public.investment_records
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage investment records" ON public.investment_records
    FOR ALL USING (auth.role() = 'authenticated');

-- New investments policies (anyone can view)
CREATE POLICY "Anyone can view new investments" ON public.new_investments
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create new investments" ON public.new_investments
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Investment offers policies
CREATE POLICY "Users can manage their own offers" ON public.investment_offers
    FOR ALL USING (
        investor_email = (SELECT email FROM public.users WHERE id = auth.uid())
    );

-- Verification requests policies
CREATE POLICY "Anyone can manage verification requests" ON public.verification_requests
    FOR ALL USING (true);

-- Startup addition requests policies
CREATE POLICY "Anyone can manage startup addition requests" ON public.startup_addition_requests
    FOR ALL USING (true);

-- =====================================================
-- STEP 8: VERIFICATION QUERIES
-- =====================================================

-- Verify all tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Verify all types were created
SELECT typname 
FROM pg_type 
WHERE typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
AND typtype = 'e'
ORDER BY typname;

-- Verify RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- =====================================================
-- STEP 9: SAMPLE DATA (OPTIONAL)
-- =====================================================

-- Insert a sample admin user (optional - for testing)
-- INSERT INTO public.users (id, email, name, role) 
-- VALUES (
--     gen_random_uuid(), 
--     'admin@startupnation.com', 
--     'Admin User', 
--     'Admin'
-- );

-- =====================================================
-- STEP 10: STORAGE BUCKETS SETUP
-- =====================================================

-- Create storage buckets for file uploads
-- Note: These commands need to be run in the Supabase Dashboard Storage section
-- or via the Supabase CLI

-- Bucket: verification-documents
-- Purpose: Store government IDs, licenses, and other verification documents
-- Command to run in Supabase Dashboard: Create bucket named 'verification-documents'

-- Bucket: startup-documents
-- Purpose: Store startup-related documents
-- Command to run in Supabase Dashboard: Create bucket named 'startup-documents'

-- Bucket: pitch-decks
-- Purpose: Store pitch deck presentations
-- Command to run in Supabase Dashboard: Create bucket named 'pitch-decks'

-- Bucket: pitch-videos
-- Purpose: Store pitch videos
-- Command to run in Supabase Dashboard: Create bucket named 'pitch-videos'

-- Bucket: financial-documents
-- Purpose: Store financial records and documents
-- Command to run in Supabase Dashboard: Create bucket named 'financial-documents'

-- Bucket: employee-contracts
-- Purpose: Store employee contracts and agreements
-- Command to run in Supabase Dashboard: Create bucket named 'employee-contracts'

-- =====================================================
-- STEP 11: STORAGE POLICIES SETUP
-- =====================================================

-- Storage policies for verification-documents bucket
-- Allow authenticated users to upload files
-- Policy: "Allow authenticated users to upload verification documents"
-- Command: INSERT INTO storage.policies (name, bucket_id, definition) VALUES (...);

-- Allow public access to uploaded files
-- Policy: "Allow public access to verification documents"
-- Command: INSERT INTO storage.policies (name, bucket_id, definition) VALUES (...);

-- Repeat similar policies for other buckets
-- Note: These policies need to be configured in the Supabase Dashboard Storage section
