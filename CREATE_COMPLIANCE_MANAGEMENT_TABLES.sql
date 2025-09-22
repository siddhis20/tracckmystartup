-- Create tables for the new compliance management system

-- Auditor Types table
CREATE TABLE IF NOT EXISTS auditor_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Governance Types table
CREATE TABLE IF NOT EXISTS governance_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Company Types table
CREATE TABLE IF NOT EXISTS company_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    country_code VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name, country_code)
);

-- New Compliance Rules table (separate from the old one)
CREATE TABLE IF NOT EXISTS compliance_rules_new (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('first-year', 'monthly', 'quarterly', 'annual')),
    validation_required VARCHAR(20) NOT NULL CHECK (validation_required IN ('auditor', 'governance', 'both')),
    country_code VARCHAR(10) NOT NULL,
    company_type_id INTEGER NOT NULL REFERENCES company_types(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_types_country ON company_types(country_code);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_country ON compliance_rules_new(country_code);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_company_type ON compliance_rules_new(company_type_id);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_frequency ON compliance_rules_new(frequency);

-- Insert default auditor types
INSERT INTO auditor_types (name, description) VALUES
('CA', 'Chartered Accountant'),
('CFA', 'Chartered Financial Analyst'),
('Auditor', 'Certified Auditor'),
('CPA', 'Certified Public Accountant')
ON CONFLICT (name) DO NOTHING;

-- Insert default governance types
INSERT INTO governance_types (name, description) VALUES
('CS', 'Company Secretary'),
('Director', 'Board Director'),
('Legal', 'Legal Counsel'),
('Compliance Officer', 'Compliance Officer')
ON CONFLICT (name) DO NOTHING;

-- Insert some default company types for common countries
INSERT INTO company_types (name, description, country_code) VALUES
-- India
('Private Limited Company', 'Private Limited Company under Companies Act 2013', 'IN'),
('Public Limited Company', 'Public Limited Company under Companies Act 2013', 'IN'),
('Limited Liability Partnership', 'Limited Liability Partnership under LLP Act 2008', 'IN'),
('One Person Company', 'One Person Company under Companies Act 2013', 'IN'),

-- United States
('C-Corporation', 'C-Corporation under US Corporate Law', 'US'),
('S-Corporation', 'S-Corporation under US Corporate Law', 'US'),
('Limited Liability Company', 'Limited Liability Company under US State Law', 'US'),
('Partnership', 'General Partnership under US State Law', 'US'),

-- United Kingdom
('Private Limited Company', 'Private Limited Company under UK Companies Act', 'UK'),
('Public Limited Company', 'Public Limited Company under UK Companies Act', 'UK'),
('Limited Liability Partnership', 'Limited Liability Partnership under UK LLP Act', 'UK'),

-- Canada
('Corporation', 'Corporation under Canada Business Corporations Act', 'CA'),
('Limited Liability Company', 'Limited Liability Company under Provincial Law', 'CA'),

-- Australia
('Proprietary Limited Company', 'Proprietary Limited Company under Corporations Act', 'AU'),
('Public Company', 'Public Company under Corporations Act', 'AU'),
('Limited Liability Partnership', 'Limited Liability Partnership under State Law', 'AU')
ON CONFLICT (name, country_code) DO NOTHING;

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update the updated_at column
CREATE TRIGGER update_auditor_types_updated_at BEFORE UPDATE ON auditor_types FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_governance_types_updated_at BEFORE UPDATE ON governance_types FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_company_types_updated_at BEFORE UPDATE ON company_types FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_compliance_rules_new_updated_at BEFORE UPDATE ON compliance_rules_new FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions (adjust as needed for your setup)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_app_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_app_user;
