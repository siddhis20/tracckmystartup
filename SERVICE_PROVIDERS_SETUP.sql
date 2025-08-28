-- =====================================================
-- SERVICE PROVIDERS TABLE SETUP
-- =====================================================

-- Create service_providers table
CREATE TABLE IF NOT EXISTS service_providers (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(10) NOT NULL CHECK (type IN ('ca', 'cs')),
    license_url TEXT,
    country VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_service_providers_code ON service_providers(code);
CREATE INDEX IF NOT EXISTS idx_service_providers_type ON service_providers(type);
CREATE INDEX IF NOT EXISTS idx_service_providers_country ON service_providers(country);

-- Add RLS policies
ALTER TABLE service_providers ENABLE ROW LEVEL SECURITY;

-- Policy: Allow all authenticated users to read service providers
CREATE POLICY "Allow authenticated users to read service providers" ON service_providers
    FOR SELECT USING (auth.role() = 'authenticated');

-- Policy: Allow admins to manage service providers
CREATE POLICY "Allow admins to manage service providers" ON service_providers
    FOR ALL USING (auth.role() = 'service_role');

-- Insert sample service providers
INSERT INTO service_providers (code, name, type, license_url, country) VALUES
-- CA Service Providers
('CA001', 'Deloitte LLP (US)', 'ca', 'https://example.com/licenses/deloitte-us.pdf', 'USA'),
('CA002', 'KPMG UK', 'ca', 'https://example.com/licenses/kpmg-uk.pdf', 'UK'),
('CA003', 'PwC India', 'ca', 'https://example.com/licenses/pwc-india.pdf', 'India'),
('CA004', 'EY Singapore', 'ca', 'https://example.com/licenses/ey-singapore.pdf', 'Singapore'),
('CA005', 'BDO Germany', 'ca', 'https://example.com/licenses/bdo-germany.pdf', 'Germany'),

-- CS Service Providers
('CS001', 'Corporation Service Company (US)', 'cs', 'https://example.com/licenses/csc-us.pdf', 'USA'),
('CS002', 'Companies House (UK)', 'cs', 'https://example.com/licenses/companies-house-uk.pdf', 'UK'),
('CS003', 'MCA India', 'cs', 'https://example.com/licenses/mca-india.pdf', 'India'),
('CS004', 'ACRA Singapore', 'cs', 'https://example.com/licenses/acra-singapore.pdf', 'Singapore'),
('CS005', 'Handelsregister Germany', 'cs', 'https://example.com/licenses/handelsregister-germany.pdf', 'Germany')
ON CONFLICT (code) DO NOTHING;

-- Update subsidiaries table to include service provider codes
ALTER TABLE subsidiaries 
ADD COLUMN IF NOT EXISTS ca_service_code VARCHAR(50) REFERENCES service_providers(code),
ADD COLUMN IF NOT EXISTS cs_service_code VARCHAR(50) REFERENCES service_providers(code);

-- Add indexes for subsidiary service provider codes
CREATE INDEX IF NOT EXISTS idx_subsidiaries_ca_service_code ON subsidiaries(ca_service_code);
CREATE INDEX IF NOT EXISTS idx_subsidiaries_cs_service_code ON subsidiaries(cs_service_code);

-- Update startups table to include service provider codes (if not already present)
ALTER TABLE startups 
ADD COLUMN IF NOT EXISTS ca_service_code VARCHAR(50) REFERENCES service_providers(code),
ADD COLUMN IF NOT EXISTS cs_service_code VARCHAR(50) REFERENCES service_providers(code);

-- Add indexes for startup service provider codes
CREATE INDEX IF NOT EXISTS idx_startups_ca_service_code ON startups(ca_service_code);
CREATE INDEX IF NOT EXISTS idx_startups_cs_service_code ON startups(cs_service_code);

-- Create function to get service provider by code and type
CREATE OR REPLACE FUNCTION get_service_provider(provider_code VARCHAR(50), provider_type VARCHAR(10))
RETURNS TABLE (
    name VARCHAR(255),
    code VARCHAR(50),
    license_url TEXT,
    country VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sp.name,
        sp.code,
        sp.license_url,
        sp.country
    FROM service_providers sp
    WHERE sp.code = provider_code 
    AND sp.type = provider_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT SELECT ON service_providers TO authenticated;
GRANT ALL ON service_providers TO service_role;
GRANT EXECUTE ON FUNCTION get_service_provider TO authenticated;

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_service_providers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_service_providers_updated_at
    BEFORE UPDATE ON service_providers
    FOR EACH ROW
    EXECUTE FUNCTION update_service_providers_updated_at();

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if service_providers table exists and has data
SELECT 'Service Providers Table Check' as check_name, 
       COUNT(*) as record_count 
FROM service_providers;

-- Check subsidiaries table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'subsidiaries' 
AND column_name IN ('ca_service_code', 'cs_service_code');

-- Check startups table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name IN ('ca_service_code', 'cs_service_code');

-- Test the get_service_provider function
SELECT * FROM get_service_provider('CA001', 'ca');
SELECT * FROM get_service_provider('CS001', 'cs');
