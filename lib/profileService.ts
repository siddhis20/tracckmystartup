import { supabase } from './supabase';
import { Subsidiary, InternationalOp, ProfileData } from '../types';

// =====================================================
// PROFILE SERVICE FOR DYNAMIC PROFILE SECTION
// =====================================================

export interface ProfileNotification {
  id: string;
  notification_type: string;
  title: string;
  message: string;
  is_read: boolean;
  created_at: string;
}

export interface ProfileAuditLog {
  id: string;
  action: string;
  table_name: string;
  record_id: string;
  old_values: any;
  new_values: any;
  changed_at: string;
}

export interface ProfileTemplate {
  id: number;
  name: string;
  description: string;
  country: string;
  company_type: string;
  sector: string;
}

export const profileService = {
  // Expose supabase client for direct subscriptions
  supabase,
  // =====================================================
  // PROFILE DATA OPERATIONS
  // =====================================================

  // Get complete profile data for a startup
  async getStartupProfile(startupId: number): Promise<ProfileData | null> {
    try {
      // Try the simple function first, then fall back to the full function
      let { data, error } = await supabase
        .rpc('get_startup_profile_simple', {
          startup_id_param: startupId
        });

      if (error) {
        // Fall back to the full function
        const { data: fullData, error: fullError } = await supabase
          .rpc('get_startup_profile', {
            startup_id_param: startupId
          });
        
        if (fullError) throw fullError;
        data = fullData;
      }
      
      if (!data) return null;

      // Normalize dates to YYYY-MM-DD and map snake_case -> camelCase
      const normalizeDate = (value: unknown): string => {
        if (!value) return '';
        if (value instanceof Date) return value.toISOString().split('T')[0];
        const str = String(value);
        return str.includes('T') ? str.split('T')[0] : str;
      };

      const normalizedSubsidiaries: Subsidiary[] = (data.subsidiaries || []).map((sub: any) => ({
        id: sub.id,
        country: sub.country,
        companyType: sub.companyType ?? sub.company_type,
        registrationDate: normalizeDate(sub.registrationDate ?? sub.registration_date),
      }));

      const normalizedInternationalOps: InternationalOp[] = (data.international_ops || []).map((op: any) => ({
        id: op.id,
        country: op.country,
        startDate: normalizeDate(op.startDate ?? op.start_date),
      }));

      return {
        country: data.startup.country_of_registration,
        companyType: data.startup.company_type,
        registrationDate: normalizeDate(data.startup.registration_date),
        subsidiaries: normalizedSubsidiaries,
        internationalOps: normalizedInternationalOps,
        caServiceCode: data.startup.ca_service_code,
        csServiceCode: data.startup.cs_service_code
      };
    } catch (error) {
      console.error('Error fetching startup profile:', error);
      return null;
    }
  },

  // Update startup profile
  async updateStartupProfile(
    startupId: number,
    profileData: Partial<ProfileData>
  ): Promise<boolean> {
    try {
      console.log('🔍 updateStartupProfile called with:', { startupId, profileData });
      
      // Try the simple function first, then fall back to the full function
      let { data, error } = await supabase
        .rpc('update_startup_profile_simple', {
          startup_id_param: startupId,
          country_param: profileData.country || '',
          company_type_param: profileData.companyType || '',
          registration_date_param: profileData.registrationDate || null,
          ca_service_code_param: profileData.caServiceCode || null,
          cs_service_code_param: profileData.csServiceCode || null
        });

      console.log('🔍 Simple function result:', { data, error });

      if (error) {
        console.log('🔍 Simple function failed, trying full function...');
        // Fall back to the full function
        const { data: fullData, error: fullError } = await supabase
          .rpc('update_startup_profile', {
            startup_id_param: startupId,
            country_param: profileData.country || '',
            company_type_param: profileData.companyType || '',
            registration_date_param: profileData.registrationDate || null,
            ca_service_code_param: profileData.caServiceCode || null,
            cs_service_code_param: profileData.csServiceCode || null
          });
        
        console.log('🔍 Full function result:', { data: fullData, error: fullError });
        
        if (fullError) throw fullError;
        data = fullData;
      }

      console.log('🔍 Final update result:', data);
      return data;
    } catch (error) {
      console.error('❌ Error updating startup profile:', error);
      return false;
    }
  },

  // =====================================================
  // SUBSIDIARY OPERATIONS
  // =====================================================

  // Add subsidiary
  async addSubsidiary(
    startupId: number,
    subsidiary: Omit<Subsidiary, 'id'>
  ): Promise<number | null> {
    try {
      console.log('🔍 addSubsidiary called with:', { startupId, subsidiary });
      
      // Try the simple function first, then fall back to the full function
      let { data, error } = await supabase
        .rpc('add_subsidiary_simple', {
          startup_id_param: startupId,
          country_param: subsidiary.country,
          company_type_param: subsidiary.companyType,
          registration_date_param: subsidiary.registrationDate
        });

      console.log('🔍 Simple add_subsidiary result:', { data, error });

      if (error) {
        console.log('🔍 Simple function failed, trying full function...');
        // Fall back to the full function
        const { data: fullData, error: fullError } = await supabase
          .rpc('add_subsidiary', {
            startup_id_param: startupId,
            country_param: subsidiary.country,
            company_type_param: subsidiary.companyType,
            registration_date_param: subsidiary.registrationDate
          });
        
        console.log('🔍 Full add_subsidiary result:', { data: fullData, error: fullError });
        
        if (fullError) throw fullError;
        data = fullData;
      }

      console.log('🔍 Final addSubsidiary result:', data);
      return data;
    } catch (error) {
      console.error('❌ Error adding subsidiary:', error);
      return null;
    }
  },

  // Update subsidiary
  async updateSubsidiary(
    subsidiaryId: number,
    subsidiary: Omit<Subsidiary, 'id'>
  ): Promise<boolean> {
    try {
      console.log('🔍 updateSubsidiary called with:', { subsidiaryId, subsidiary });
      
      // Ensure registration date is in the correct format
      let registrationDate = subsidiary.registrationDate;
      if (registrationDate && typeof registrationDate === 'string') {
        // Handle different date formats
        const date = new Date(registrationDate);
        if (!isNaN(date.getTime())) {
          // Convert to YYYY-MM-DD format for PostgreSQL
          registrationDate = date.toISOString().split('T')[0];
        } else {
          console.error('❌ Invalid date format:', registrationDate);
          return false;
        }
      } else if (registrationDate instanceof Date) {
        registrationDate = registrationDate.toISOString().split('T')[0];
      }
      
      console.log('🔍 Processed registration date:', registrationDate);
      
      const { data, error } = await supabase
        .rpc('update_subsidiary', {
          subsidiary_id_param: subsidiaryId,
          country_param: subsidiary.country,
          company_type_param: subsidiary.companyType,
          registration_date_param: registrationDate
        });

      console.log('🔍 update_subsidiary result:', { data, error });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('❌ Error updating subsidiary:', error);
      return false;
    }
  },

  // Delete subsidiary
  async deleteSubsidiary(subsidiaryId: number): Promise<boolean> {
    try {
      console.log('🔍 deleteSubsidiary called with ID:', subsidiaryId);
      
      const { data, error } = await supabase
        .rpc('delete_subsidiary', {
          subsidiary_id_param: subsidiaryId
        });

      console.log('🔍 delete_subsidiary result:', { data, error });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('❌ Error deleting subsidiary:', error);
      return false;
    }
  },

  // =====================================================
  // INTERNATIONAL OPERATIONS
  // =====================================================

  // Add international operation
  async addInternationalOp(
    startupId: number,
    operation: Omit<InternationalOp, 'id'>
  ): Promise<number | null> {
    try {
      // Try the simple function first, then fall back to the full function
      let { data, error } = await supabase
        .rpc('add_international_op_simple', {
          startup_id_param: startupId,
          country_param: operation.country,
          start_date_param: operation.startDate
        });

      if (error) {
        // Fall back to the full function
        const { data: fullData, error: fullError } = await supabase
          .rpc('add_international_op', {
            startup_id_param: startupId,
            country_param: operation.country,
            start_date_param: operation.startDate
          });
        
        if (fullError) throw fullError;
        data = fullData;
      }

      return data;
    } catch (error) {
      console.error('Error adding international operation:', error);
      return null;
    }
  },

  // Update international operation
  async updateInternationalOp(
    opId: number,
    operation: Omit<InternationalOp, 'id'>
  ): Promise<boolean> {
    try {
      console.log('🔍 updateInternationalOp called with:', { opId, operation });
      
      // Ensure start date is in the correct format
      let startDate = operation.startDate;
      if (startDate && typeof startDate === 'string') {
        // Handle different date formats
        const date = new Date(startDate);
        if (!isNaN(date.getTime())) {
          // Convert to YYYY-MM-DD format for PostgreSQL
          startDate = date.toISOString().split('T')[0];
        } else {
          console.error('❌ Invalid date format:', startDate);
          return false;
        }
      } else if (startDate instanceof Date) {
        startDate = startDate.toISOString().split('T')[0];
      }
      
      console.log('🔍 Processed start date:', startDate);
      
      const { data, error } = await supabase
        .rpc('update_international_op', {
          op_id_param: opId,
          country_param: operation.country,
          start_date_param: startDate
        });

      console.log('🔍 update_international_op result:', { data, error });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('❌ Error updating international operation:', error);
      return false;
    }
  },

  // Delete international operation
  async deleteInternationalOp(opId: number): Promise<boolean> {
    try {
      const { data, error } = await supabase
        .rpc('delete_international_op', {
          op_id_param: opId
        });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error deleting international operation:', error);
      return false;
    }
  },

  // =====================================================
  // NOTIFICATIONS
  // =====================================================

  // Get profile notifications
  async getProfileNotifications(startupId: number): Promise<ProfileNotification[]> {
    try {
      const { data, error } = await supabase
        .from('profile_notifications')
        .select('*')
        .eq('startup_id', startupId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching profile notifications:', error);
      return [];
    }
  },

  // Mark notification as read
  async markNotificationAsRead(notificationId: string): Promise<boolean> {
    try {
      const { error } = await supabase
        .from('profile_notifications')
        .update({ is_read: true })
        .eq('id', notificationId);

      if (error) throw error;
      return true;
    } catch (error) {
      console.error('Error marking notification as read:', error);
      return false;
    }
  },

  // =====================================================
  // AUDIT LOG
  // =====================================================

  // Get profile audit log
  async getProfileAuditLog(startupId: number): Promise<ProfileAuditLog[]> {
    try {
      const { data, error } = await supabase
        .from('profile_audit_log')
        .select('*')
        .eq('startup_id', startupId)
        .order('changed_at', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching profile audit log:', error);
      return [];
    }
  },

  // =====================================================
  // TEMPLATES
  // =====================================================

  // Get profile templates
  async getProfileTemplates(country?: string, sector?: string): Promise<ProfileTemplate[]> {
    try {
      let query = supabase
        .from('profile_templates')
        .select('*')
        .eq('is_active', true);

      if (country) {
        query = query.eq('country', country);
      }

      if (sector) {
        query = query.eq('sector', sector);
      }

      const { data, error } = await query;

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching profile templates:', error);
      return [];
    }
  },

  // =====================================================
  // REAL-TIME SUBSCRIPTIONS
  // =====================================================

  // Subscribe to profile changes
  subscribeToProfileChanges(startupId: number, callback: (payload: any) => void) {
    return supabase
      .channel(`profile_changes_${startupId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'profile_audit_log',
          filter: `startup_id=eq.${startupId}`
        },
        callback
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'profile_notifications',
          filter: `startup_id=eq.${startupId}`
        },
        callback
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'subsidiaries',
          filter: `startup_id=eq.${startupId}`
        },
        callback
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'international_ops',
          filter: `startup_id=eq.${startupId}`
        },
        callback
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'startups',
          filter: `id=eq.${startupId}`
        },
        callback
      )
      .subscribe();
  },

  // Subscribe to profile notifications
  subscribeToProfileNotifications(startupId: number, callback: (payload: any) => void) {
    return supabase
      .channel(`profile_notifications_${startupId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'profile_notifications',
          filter: `startup_id=eq.${startupId}`
        },
        callback
      )
      .subscribe();
  },

  // =====================================================
  // UTILITY FUNCTIONS
  // =====================================================

  // Get company types by country
  getCompanyTypesByCountry(country: string, sector?: string): string[] {
    const companyTypes: { [key: string]: string[] } = {
      'USA': ['C-Corporation', 'LLC', 'S-Corporation'],
      'UK': ['Limited Company (Ltd)', 'Public Limited Company (PLC)'],
      'India': ['Private Limited Company', 'Public Limited Company', 'LLP'],
      'Singapore': ['Private Limited', 'Exempt Private Company'],
      'Germany': ['GmbH', 'AG', 'UG'],
      'Canada': ['Corporation', 'LLC', 'Partnership'],
      'Australia': ['Proprietary Limited', 'Public Company'],
      'Japan': ['Kabushiki Kaisha', 'Godo Kaisha'],
      'Brazil': ['Ltda', 'S.A.'],
      'Mexico': ['S.A. de C.V.', 'S. de R.L.']
    };

    return companyTypes[country] || ['LLC'];
  },

  // Get all available countries
  getAllCountries(): string[] {
    return [
      'USA', 'UK', 'India', 'Singapore', 'Germany', 
      'Canada', 'Australia', 'Japan', 'Brazil', 'Mexico'
    ];
  },

  // Validate profile data
  validateProfileData(profile: Partial<ProfileData>): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (profile.country && !this.getAllCountries().includes(profile.country)) {
      errors.push('Invalid country selected');
    }

    if (profile.companyType && profile.country) {
      const validTypes = this.getCompanyTypesByCountry(profile.country);
      if (!validTypes.includes(profile.companyType)) {
        errors.push('Invalid company type for selected country');
      }
    }

    if (profile.registrationDate) {
      const date = new Date(profile.registrationDate);
      if (isNaN(date.getTime())) {
        errors.push('Invalid registration date');
      }
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
};
