import { complianceRulesComprehensiveService } from './complianceRulesComprehensiveService';

export interface CountryComplianceInfo {
  country_code: string;
  country_name: string;
  ca_type: string | null;
  cs_type: string | null;
}

export interface UserComplianceProfile {
  country: string;
  ca_type: string | null;
  cs_type: string | null;
  company_type: string;
  compliance_rules: any[];
}

class UserComplianceService {
  // Get all available countries with their CA and CS types
  async getAvailableCountries(): Promise<CountryComplianceInfo[]> {
    try {
      const countries = await complianceRulesComprehensiveService.getCountries();
      const countryInfo: CountryComplianceInfo[] = [];

      for (const country of countries) {
        const [caType, csType] = await Promise.all([
          complianceRulesComprehensiveService.getCATypeByCountry(country.country_code),
          complianceRulesComprehensiveService.getCSTypeByCountry(country.country_code)
        ]);

        countryInfo.push({
          country_code: country.country_code,
          country_name: country.country_name,
          ca_type: caType,
          cs_type: csType
        });
      }

      return countryInfo;
    } catch (error) {
      console.error('Error fetching available countries:', error);
      return [];
    }
  }

  // Get CA and CS types for a specific country
  async getCountryComplianceInfo(countryCode: string): Promise<CountryComplianceInfo | null> {
    try {
      const countries = await complianceRulesComprehensiveService.getCountries();
      const country = countries.find(c => c.country_code === countryCode);
      
      if (!country) return null;

      const [caType, csType] = await Promise.all([
        complianceRulesComprehensiveService.getCATypeByCountry(countryCode),
        complianceRulesComprehensiveService.getCSTypeByCountry(countryCode)
      ]);

      return {
        country_code: countryCode,
        country_name: country.country_name,
        ca_type: caType,
        cs_type: csType
      };
    } catch (error) {
      console.error('Error fetching country compliance info:', error);
      return null;
    }
  }

  // Get compliance rules for a specific country and company type
  async getComplianceRulesForUser(countryCode: string, companyType: string): Promise<any[]> {
    try {
      const rules = await complianceRulesComprehensiveService.getRulesByCountryAndCompanyType(countryCode, companyType);
      return rules;
    } catch (error) {
      console.error('Error fetching compliance rules for user:', error);
      return [];
    }
  }

  // Get company types available for a specific country
  async getCompanyTypesForCountry(countryCode: string): Promise<string[]> {
    try {
      return await complianceRulesComprehensiveService.getCompanyTypesByCountry(countryCode);
    } catch (error) {
      console.error('Error fetching company types for country:', error);
      return [];
    }
  }

  // Validate user compliance profile
  async validateUserComplianceProfile(profile: {
    country: string;
    company_type: string;
    ca_type?: string;
    cs_type?: string;
  }): Promise<{ valid: boolean; errors: string[] }> {
    const errors: string[] = [];

    try {
      // Check if country exists
      const countryInfo = await this.getCountryComplianceInfo(profile.country);
      if (!countryInfo) {
        errors.push('Invalid country selected');
        return { valid: false, errors };
      }

      // Check if company type exists for this country
      const companyTypes = await this.getCompanyTypesForCountry(profile.country);
      if (!companyTypes.includes(profile.company_type)) {
        errors.push('Invalid company type for selected country');
      }

      // Check CA type if provided
      if (profile.ca_type && countryInfo.ca_type && profile.ca_type !== countryInfo.ca_type) {
        errors.push(`CA type must be "${countryInfo.ca_type}" for ${countryInfo.country_name}`);
      }

      // Check CS type if provided
      if (profile.cs_type && countryInfo.cs_type && profile.cs_type !== countryInfo.cs_type) {
        errors.push(`CS type must be "${countryInfo.cs_type}" for ${countryInfo.country_name}`);
      }

      return { valid: errors.length === 0, errors };
    } catch (error) {
      console.error('Error validating user compliance profile:', error);
      return { valid: false, errors: ['Error validating compliance profile'] };
    }
  }

  // Get user's compliance dashboard data
  async getUserComplianceDashboard(userProfile: {
    country: string;
    company_type: string;
  }): Promise<{
    compliance_rules: any[];
    ca_type: string | null;
    cs_type: string | null;
    country_name: string;
  }> {
    try {
      const [countryInfo, complianceRules] = await Promise.all([
        this.getCountryComplianceInfo(userProfile.country),
        this.getComplianceRulesForUser(userProfile.country, userProfile.company_type)
      ]);

      return {
        compliance_rules: complianceRules,
        ca_type: countryInfo?.ca_type || null,
        cs_type: countryInfo?.cs_type || null,
        country_name: countryInfo?.country_name || userProfile.country
      };
    } catch (error) {
      console.error('Error fetching user compliance dashboard:', error);
      return {
        compliance_rules: [],
        ca_type: null,
        cs_type: null,
        country_name: userProfile.country
      };
    }
  }
}

export const userComplianceService = new UserComplianceService();
