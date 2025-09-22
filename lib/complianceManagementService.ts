import { supabase } from './supabase';

// Types for the new compliance management system
export interface AuditorType {
  id: number;
  name: string;
  description: string;
  created_at: string;
  updated_at: string;
}

export interface GovernanceType {
  id: number;
  name: string;
  description: string;
  created_at: string;
  updated_at: string;
}

export interface CompanyType {
  id: number;
  name: string;
  description: string;
  country_code: string;
  created_at: string;
  updated_at: string;
}

export interface ComplianceRule {
  id: number;
  name: string;
  description: string;
  frequency: 'first-year' | 'monthly' | 'quarterly' | 'annual';
  validation_required: 'auditor' | 'governance' | 'both';
  country_code: string;
  company_type_id: number;
  created_at: string;
  updated_at: string;
}

class ComplianceManagementService {
  // Auditor Types Management
  async getAuditorTypes(): Promise<AuditorType[]> {
    const { data, error } = await supabase
      .from('auditor_types')
      .select('*')
      .order('name');
    if (error) throw error;
    return data || [];
  }

  async addAuditorType(name: string, description: string): Promise<AuditorType> {
    const { data, error } = await supabase
      .from('auditor_types')
      .insert({ name, description })
      .select('*')
      .single();
    if (error) throw error;
    return data;
  }

  async updateAuditorType(id: number, name: string, description: string): Promise<AuditorType> {
    const { data, error } = await supabase
      .from('auditor_types')
      .update({ name, description, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select('*')
      .single();
    if (error) throw error;
    return data;
  }

  async deleteAuditorType(id: number): Promise<boolean> {
    const { error } = await supabase
      .from('auditor_types')
      .delete()
      .eq('id', id);
    if (error) throw error;
    return true;
  }

  // Governance Types Management
  async getGovernanceTypes(): Promise<GovernanceType[]> {
    const { data, error } = await supabase
      .from('governance_types')
      .select('*')
      .order('name');
    if (error) throw error;
    return data || [];
  }

  async addGovernanceType(name: string, description: string): Promise<GovernanceType> {
    const { data, error } = await supabase
      .from('governance_types')
      .insert({ name, description })
      .select('*')
      .single();
    if (error) throw error;
    return data;
  }

  async updateGovernanceType(id: number, name: string, description: string): Promise<GovernanceType> {
    const { data, error } = await supabase
      .from('governance_types')
      .update({ name, description, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select('*')
      .single();
    if (error) throw error;
    return data;
  }

  async deleteGovernanceType(id: number): Promise<boolean> {
    const { error } = await supabase
      .from('governance_types')
      .delete()
      .eq('id', id);
    if (error) throw error;
    return true;
  }

  // Company Types Management
  async getCompanyTypes(countryCode?: string): Promise<CompanyType[]> {
    let query = supabase
      .from('company_types')
      .select('*')
      .order('name');
    
    if (countryCode) {
      query = query.eq('country_code', countryCode);
    }
    
    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  }

  async addCompanyType(name: string, description: string, countryCode: string): Promise<CompanyType> {
    const { data, error } = await supabase
      .from('company_types')
      .insert({ name, description, country_code: countryCode })
      .select('*')
      .single();
    if (error) throw error;
    return data;
  }

  async updateCompanyType(id: number, name: string, description: string): Promise<CompanyType> {
    const { data, error } = await supabase
      .from('company_types')
      .update({ name, description, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select('*')
      .single();
    if (error) throw error;
    return data;
  }

  async deleteCompanyType(id: number): Promise<boolean> {
    const { error } = await supabase
      .from('company_types')
      .delete()
      .eq('id', id);
    if (error) throw error;
    return true;
  }

  // Compliance Rules Management
  async getComplianceRules(countryCode?: string, companyTypeId?: number): Promise<ComplianceRule[]> {
    let query = supabase
      .from('compliance_rules_new')
      .select(`
        *,
        company_types!inner(name)
      `)
      .order('name');
    
    if (countryCode) {
      query = query.eq('country_code', countryCode);
    }
    
    if (companyTypeId) {
      query = query.eq('company_type_id', companyTypeId);
    }
    
    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  }

  async addComplianceRule(
    name: string,
    description: string,
    frequency: 'first-year' | 'monthly' | 'quarterly' | 'annual',
    validationRequired: 'auditor' | 'governance' | 'both',
    countryCode: string,
    companyTypeId: number
  ): Promise<ComplianceRule> {
    const { data, error } = await supabase
      .from('compliance_rules_new')
      .insert({
        name,
        description,
        frequency,
        validation_required: validationRequired,
        country_code: countryCode,
        company_type_id: companyTypeId
      })
      .select('*')
      .single();
    if (error) throw error;
    return data;
  }

  async updateComplianceRule(
    id: number,
    name: string,
    description: string,
    frequency: 'first-year' | 'monthly' | 'quarterly' | 'annual',
    validationRequired: 'auditor' | 'governance' | 'both'
  ): Promise<ComplianceRule> {
    const { data, error } = await supabase
      .from('compliance_rules_new')
      .update({
        name,
        description,
        frequency,
        validation_required: validationRequired,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select('*')
      .single();
    if (error) throw error;
    return data;
  }

  async deleteComplianceRule(id: number): Promise<boolean> {
    const { error } = await supabase
      .from('compliance_rules_new')
      .delete()
      .eq('id', id);
    if (error) throw error;
    return true;
  }

}

export const complianceManagementService = new ComplianceManagementService();
