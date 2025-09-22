import { supabase } from './supabase';

// Types for the comprehensive compliance rules system
export interface ComplianceRuleComprehensive {
  id: number;
  country_code: string;
  country_name: string;
  ca_type?: string;
  cs_type?: string;
  company_type: string;
  compliance_name: string;
  compliance_description?: string;
  frequency: 'first-year' | 'monthly' | 'quarterly' | 'annual';
  verification_required: 'CA' | 'CS' | 'both';
  created_at: string;
  updated_at: string;
}

export interface ComplianceRuleFormData {
  country_code: string;
  country_name: string;
  ca_type?: string;
  cs_type?: string;
  company_type: string;
  compliance_name: string;
  compliance_description?: string;
  frequency: 'first-year' | 'monthly' | 'quarterly' | 'annual';
  verification_required: 'CA' | 'CS' | 'both';
}

class ComplianceRulesComprehensiveService {
  // Get all compliance rules
  async getAllRules(): Promise<ComplianceRuleComprehensive[]> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('*')
      .order('country_name', { ascending: true })
      .order('company_type', { ascending: true })
      .order('compliance_name', { ascending: true });
    if (error) throw error;
    return data || [];
  }

  // Get rules filtered by country
  async getRulesByCountry(countryCode: string): Promise<ComplianceRuleComprehensive[]> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('*')
      .eq('country_code', countryCode)
      .order('company_type', { ascending: true })
      .order('compliance_name', { ascending: true });
    if (error) throw error;
    return data || [];
  }

  // Get rules filtered by company type
  async getRulesByCompanyType(companyType: string): Promise<ComplianceRuleComprehensive[]> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('*')
      .eq('company_type', companyType)
      .order('country_name', { ascending: true })
      .order('compliance_name', { ascending: true });
    if (error) throw error;
    return data || [];
  }

  // Get rules filtered by country and company type
  async getRulesByCountryAndCompanyType(countryCode: string, companyType: string): Promise<ComplianceRuleComprehensive[]> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('*')
      .eq('country_code', countryCode)
      .eq('company_type', companyType)
      .order('compliance_name', { ascending: true });
    if (error) throw error;
    return data || [];
  }

  // Add new compliance rule
  async addRule(ruleData: ComplianceRuleFormData): Promise<ComplianceRuleComprehensive> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .insert(ruleData)
      .select('*')
      .single();
    if (error) throw error;
    return data;
  }

  // Update existing compliance rule
  async updateRule(id: number, ruleData: Partial<ComplianceRuleFormData>): Promise<ComplianceRuleComprehensive> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .update({ ...ruleData, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select('*')
      .single();
    if (error) throw error;
    return data;
  }

  // Delete compliance rule
  async deleteRule(id: number): Promise<boolean> {
    const { error } = await supabase
      .from('compliance_rules_comprehensive')
      .delete()
      .eq('id', id);
    if (error) throw error;
    return true;
  }

  // Get unique countries
  async getCountries(): Promise<{ country_code: string; country_name: string }[]> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('country_code, country_name')
      .order('country_name');
    if (error) throw error;
    
    // Remove duplicates
    const uniqueCountries = data?.reduce((acc, current) => {
      const exists = acc.find(item => item.country_code === current.country_code);
      if (!exists) {
        acc.push(current);
      }
      return acc;
    }, [] as { country_code: string; country_name: string }[]) || [];
    
    return uniqueCountries;
  }

  // Get unique company types
  async getCompanyTypes(): Promise<string[]> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('company_type')
      .order('company_type');
    if (error) throw error;
    
    // Remove duplicates
    const uniqueCompanyTypes = [...new Set(data?.map(item => item.company_type) || [])];
    return uniqueCompanyTypes;
  }

  // Get unique CA types
  async getCATypes(): Promise<string[]> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('ca_type')
      .not('ca_type', 'is', null)
      .order('ca_type');
    if (error) throw error;
    
    // Remove duplicates
    const uniqueCATypes = [...new Set(data?.map(item => item.ca_type).filter(Boolean) || [])];
    return uniqueCATypes;
  }

  // Get unique CS types
  async getCSTypes(): Promise<string[]> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('cs_type')
      .not('cs_type', 'is', null)
      .order('cs_type');
    if (error) throw error;
    
    // Remove duplicates
    const uniqueCSTypes = [...new Set(data?.map(item => item.cs_type).filter(Boolean) || [])];
    return uniqueCSTypes;
  }

  // Get company types for a specific country
  async getCompanyTypesByCountry(countryCode: string): Promise<string[]> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('company_type')
      .eq('country_code', countryCode)
      .order('company_type');
    if (error) throw error;
    
    // Remove duplicates
    const uniqueCompanyTypes = [...new Set(data?.map(item => item.company_type) || [])];
    return uniqueCompanyTypes;
  }

  // Get single CA type for a specific country
  async getCATypeByCountry(countryCode: string): Promise<string | null> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('ca_type')
      .eq('country_code', countryCode)
      .not('ca_type', 'is', null)
      .limit(1);
    if (error) throw error;
    
    return data?.[0]?.ca_type || null;
  }

  // Get single CS type for a specific country
  async getCSTypeByCountry(countryCode: string): Promise<string | null> {
    const { data, error } = await supabase
      .from('compliance_rules_comprehensive')
      .select('cs_type')
      .eq('country_code', countryCode)
      .not('cs_type', 'is', null)
      .limit(1);
    if (error) throw error;
    
    return data?.[0]?.cs_type || null;
  }

  // Get CA types for a specific country (for backward compatibility)
  async getCATypesByCountry(countryCode: string): Promise<string[]> {
    const caType = await this.getCATypeByCountry(countryCode);
    return caType ? [caType] : [];
  }

  // Get CS types for a specific country (for backward compatibility)
  async getCSTypesByCountry(countryCode: string): Promise<string[]> {
    const csType = await this.getCSTypeByCountry(countryCode);
    return csType ? [csType] : [];
  }

  // Add country with CA and CS types (creates a setup entry)
  async addCountryWithTypes(countryData: {
    country_code: string;
    country_name: string;
    ca_types: string[];
    cs_types: string[];
  }): Promise<void> {
    const { country_code, country_name, ca_types, cs_types } = countryData;
    
    // Create setup entries for each CA type
    for (const caType of ca_types) {
      await this.addRule({
        country_code,
        country_name,
        ca_type: caType,
        company_type: 'Country Setup - CA Type',
        compliance_name: 'Country Setup - CA Type',
        compliance_description: `Setup entry for CA type: ${caType} in ${country_name}`,
        frequency: 'annual',
        verification_required: 'CA'
      });
    }
    
    // Create setup entries for each CS type
    for (const csType of cs_types) {
      await this.addRule({
        country_code,
        country_name,
        cs_type: csType,
        company_type: 'Country Setup - CS Type',
        compliance_name: 'Country Setup - CS Type',
        compliance_description: `Setup entry for CS type: ${csType} in ${country_name}`,
        frequency: 'annual',
        verification_required: 'CS'
      });
    }
  }

  // Bulk upload compliance rules from Excel data
  async bulkUploadRules(rulesData: ComplianceRuleFormData[]): Promise<{
    success: number;
    errors: Array<{ row: number; error: string; data: any }>;
  }> {
    const errors: Array<{ row: number; error: string; data: any }> = [];
    let success = 0;

    for (let i = 0; i < rulesData.length; i++) {
      try {
        console.log(`Processing row ${i + 1}:`, rulesData[i]);
        await this.addRule(rulesData[i]);
        success++;
        console.log(`Row ${i + 1} processed successfully`);
      } catch (error) {
        console.error(`Error processing row ${i + 1}:`, error);
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        errors.push({
          row: i + 1,
          error: errorMessage,
          data: rulesData[i]
        });
      }
    }

    console.log('bulkUploadRules returning:', { success, errors });
    return { success, errors };
  }
}

export const complianceRulesComprehensiveService = new ComplianceRulesComprehensiveService();
