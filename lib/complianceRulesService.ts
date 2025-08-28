import { supabase } from './supabase';

export type DbComplianceRulesRow = {
  id: number;
  country_code: string;
  rules: any; // JSONB structure: { [companyType or 'default']: { annual: Rule[]; firstYear: Rule[] } }
  created_at: string;
  updated_at: string;
};

export type Rule = {
  id: string;
  name: string;
  caRequired: boolean;
  csRequired: boolean;
};

class ComplianceRulesService {
  async listAll(): Promise<DbComplianceRulesRow[]> {
    const { data, error } = await supabase
      .from('compliance_rules')
      .select('*')
      .order('country_code');
    if (error) throw error;
    return (data || []) as DbComplianceRulesRow[];
  }

  async getByCountry(countryCode: string): Promise<DbComplianceRulesRow | null> {
    const { data, error } = await supabase
      .from('compliance_rules')
      .select('*')
      .eq('country_code', countryCode)
      .maybeSingle();
    if (error && error.code !== 'PGRST116') throw error;
    return (data || null) as DbComplianceRulesRow | null;
  }

  async upsertCountryRules(countryCode: string, rulesJson: any): Promise<DbComplianceRulesRow> {
    const { data, error } = await supabase
      .from('compliance_rules')
      .upsert({ country_code: countryCode, rules: rulesJson }, { onConflict: 'country_code' })
      .select('*')
      .single();
    if (error) throw error;
    return data as DbComplianceRulesRow;
  }

  async deleteCountry(countryCode: string): Promise<boolean> {
    const { error } = await supabase
      .from('compliance_rules')
      .delete()
      .eq('country_code', countryCode);
    if (error) throw error;
    return true;
  }
}

export const complianceRulesService = new ComplianceRulesService();


