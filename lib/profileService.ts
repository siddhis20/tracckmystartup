import { supabase } from './supabase';
import { COUNTRIES } from '../constants';
import { Subsidiary, InternationalOp, ProfileData, ServiceProvider } from '../types';

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
        caCode: sub.caCode ?? sub.ca_service_code ?? undefined,
        csCode: sub.csCode ?? sub.cs_service_code ?? undefined,
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
      // Ensure we write CA/CS service codes
      let { data, error } = await supabase
        .rpc('update_startup_profile_simple', {
          startup_id_param: startupId,
          country_param: profileData.country || '',
          company_type_param: profileData.companyType || '',
          registration_date_param: profileData.registrationDate || null,
          ca_service_code_param: (profileData.caServiceCode || (profileData as any).caCode) || null,
          cs_service_code_param: (profileData.csServiceCode || (profileData as any).csCode) || null
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
            ca_service_code_param: (profileData.caServiceCode || (profileData as any).caCode) || null,
            cs_service_code_param: (profileData.csServiceCode || (profileData as any).csCode) || null
          });
        
        console.log('🔍 Full function result:', { data: fullData, error: fullError });
        
        if (fullError) throw fullError;
        data = fullData;
      } else {
        // Treat success (even if data is false/no-op) as success
        return true;
      }

      // As a final safety, if RPC path failed to update (data is falsy), attempt direct update
      if (!data) {
        const { error: directError } = await supabase
          .from('startups')
          .update({
            country_of_registration: profileData.country || null,
            company_type: profileData.companyType || null,
            registration_date: profileData.registrationDate || null,
            ca_service_code: (profileData.caServiceCode || (profileData as any).caCode) || null,
            cs_service_code: (profileData.csServiceCode || (profileData as any).csCode) || null,
            updated_at: new Date().toISOString(),
          })
          .eq('id', startupId);
        if (directError) {
          console.error('❌ Direct update on startups failed due to RLS/policy:', directError);
          return false;
        }
        console.log('🔍 Direct update on startups succeeded');
        return true;
      }

      console.log('🔍 Final update result:', data);
      return true;
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
      let registrationDate: string | null = (subsidiary.registrationDate as unknown as string) || null;
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
      } else if (registrationDate && typeof registrationDate === 'object' && 'toISOString' in (registrationDate as any)) {
        registrationDate = ((registrationDate as unknown) as Date).toISOString().split('T')[0];
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
      let startDate: string | null = (operation.startDate as unknown as string) || null;
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
      } else if (startDate && typeof startDate === 'object' && 'toISOString' in (startDate as any)) {
        startDate = ((startDate as unknown) as Date).toISOString().split('T')[0];
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
    // Normalize common aliases to align with compliance rules
    const aliasToCanonical: Record<string, string> = {
      'USA': 'United States',
      'US': 'United States',
      'UK': 'United Kingdom'
    };
    const normalized = aliasToCanonical[country] || country;

    const companyTypes: { [key: string]: string[] } = {
      'United States': ['C-Corporation', 'LLC', 'S-Corporation'],
      'United Kingdom': ['Limited Company (Ltd)', 'Public Limited Company (PLC)'],
      'India': ['Private Limited Company', 'Public Limited Company', 'LLP'],
      'Singapore': ['Private Limited', 'Exempt Private Company'],
      'Germany': ['GmbH', 'AG', 'UG'],
      'Canada': ['Corporation', 'LLC', 'Partnership'],
      'Australia': ['Proprietary Limited', 'Public Company'],
      'Japan': ['Kabushiki Kaisha', 'Godo Kaisha'],
      'Brazil': ['Ltda', 'S.A.'],
      'France': ['SARL', 'SA', 'SAS']
    };

    return companyTypes[normalized] || ['LLC'];
  },

  // Get all available countries
  getAllCountries(): string[] {
    return COUNTRIES;
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

    // Cross-entity date consistency checks
    const parentDate = profile.registrationDate ? new Date(profile.registrationDate) : null;
    const isValidDate = (d: any) => d instanceof Date && !isNaN(d.getTime());

    // Validate subsidiaries
    if (Array.isArray(profile.subsidiaries)) {
      for (const sub of profile.subsidiaries) {
        if (sub.country && !this.getAllCountries().includes(sub.country)) {
          errors.push(`Invalid subsidiary country: ${sub.country}`);
        }
        if (sub.companyType && sub.country) {
          const valid = this.getCompanyTypesByCountry(sub.country);
          if (!valid.includes(sub.companyType)) {
            errors.push(`Invalid company type for subsidiary country ${sub.country}`);
          }
        }
        if (sub.registrationDate) {
          const subDate = new Date(sub.registrationDate);
          if (isNaN(subDate.getTime())) {
            errors.push('Invalid subsidiary registration date');
          }
          if (parentDate && isValidDate(parentDate) && isValidDate(subDate) && subDate < (parentDate as Date)) {
            errors.push('Subsidiary registration date cannot be earlier than parent registration date');
          }
        }
      }
    }

    // Validate international operations
    if (Array.isArray(profile.internationalOps)) {
      for (const op of profile.internationalOps) {
        if (op.country && !this.getAllCountries().includes(op.country)) {
          errors.push(`Invalid international operation country: ${op.country}`);
        }
        if (op.startDate) {
          const opDate = new Date(op.startDate);
          if (isNaN(opDate.getTime())) {
            errors.push('Invalid international operation start date');
          }
          if (parentDate && isValidDate(parentDate) && isValidDate(opDate) && opDate < (parentDate as Date)) {
            errors.push('International operation start date cannot be earlier than parent registration date');
          }
        }
      }
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  },

  // Validate CA/CS codes against backend
  async validateServiceCodes(profile: Partial<ProfileData>): Promise<{ isValid: boolean; errors: string[] }> {
    const errors: string[] = [];

    // Validate main startup CA/CS codes
    if (profile.caServiceCode && profile.caServiceCode.trim()) {
      const caProvider = await this.getServiceProvider(profile.caServiceCode.trim(), 'ca');
      if (!caProvider) {
        errors.push(`Invalid CA code: ${profile.caServiceCode}. Please enter a valid CA service provider code.`);
      }
    }

    if (profile.csServiceCode && profile.csServiceCode.trim()) {
      const csProvider = await this.getServiceProvider(profile.csServiceCode.trim(), 'cs');
      if (!csProvider) {
        errors.push(`Invalid CS code: ${profile.csServiceCode}. Please enter a valid CS service provider code.`);
      }
    }

    // Validate subsidiary CA/CS codes
    if (Array.isArray(profile.subsidiaries)) {
      for (let i = 0; i < profile.subsidiaries.length; i++) {
        const sub = profile.subsidiaries[i];
        const subIndex = i + 1;

        if (sub.caCode && sub.caCode.trim()) {
          const caProvider = await this.getServiceProvider(sub.caCode.trim(), 'ca');
          if (!caProvider) {
            errors.push(`Subsidiary ${subIndex}: Invalid CA code "${sub.caCode}". Please enter a valid CA service provider code.`);
          }
        }

        if (sub.csCode && sub.csCode.trim()) {
          const csProvider = await this.getServiceProvider(sub.csCode.trim(), 'cs');
          if (!csProvider) {
            errors.push(`Subsidiary ${subIndex}: Invalid CS code "${sub.csCode}". Please enter a valid CS service provider code.`);
          }
        }
      }
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  },

  // =====================================================
  // SERVICE PROVIDER OPERATIONS
  // =====================================================

  // Get service provider by code
  async getServiceProvider(code: string, type: 'ca' | 'cs'): Promise<ServiceProvider | null> {
    try {
      const { data, error } = await supabase
        .from('service_providers')
        .select('*')
        .eq('code', code)
        .eq('type', type)
        .maybeSingle();

      if (error) {
        console.error('Error fetching service provider:', error);
        return null;
      }

      return data ? {
        name: data.name,
        code: data.code,
        licenseUrl: data.license_url
      } : null;
    } catch (error) {
      console.error('Error fetching service provider:', error);
      return null;
    }
  },

  // Update subsidiary service provider
  async updateSubsidiaryServiceProvider(
    subsidiaryId: number,
    type: 'ca' | 'cs',
    serviceCode: string
  ): Promise<boolean> {
    try {
      const updateData = type === 'ca' 
        ? { ca_service_code: serviceCode }
        : { cs_service_code: serviceCode };

      const { data, error } = await supabase
        .from('subsidiaries')
        .update(updateData)
        .eq('id', subsidiaryId)
        .select('id, ca_service_code, cs_service_code')
        .single();

      if (error) throw error;
      return true;
    } catch (error) {
      console.error('Error updating subsidiary service provider:', error);
      return false;
    }
  },

  // Remove subsidiary service provider
  async removeSubsidiaryServiceProvider(
    subsidiaryId: number,
    type: 'ca' | 'cs'
  ): Promise<boolean> {
    try {
      const updateData = type === 'ca' 
        ? { ca_service_code: null }
        : { cs_service_code: null };

      const { data, error } = await supabase
        .from('subsidiaries')
        .update(updateData)
        .eq('id', subsidiaryId);

      if (error) throw error;
      return true;
    } catch (error) {
      console.error('Error removing subsidiary service provider:', error);
      return false;
    }
  },

  // =====================================================
  // COMPLIANCE TASK GENERATION
  // =====================================================

  // Generate compliance tasks for a startup
  async generateComplianceTasks(startupId: number): Promise<any[]> {
    try {
      console.log('🔍 Generating compliance tasks for startup:', startupId);
      
      const { data, error } = await supabase
        .rpc('generate_compliance_tasks_for_startup', {
          startup_id_param: startupId
        });
      
      if (error) {
        console.error('Error generating compliance tasks:', error);
        throw error;
      }
      
      console.log('🔍 Generated compliance tasks:', data);
      return data || [];
    } catch (error) {
      console.error('Error generating compliance tasks:', error);
      return [];
    }
  },

  // Sync compliance tasks with database
  async syncComplianceTasks(startupId: number): Promise<boolean> {
    try {
      console.log('🔍 Syncing compliance tasks for startup:', startupId);
      
      const tasks = await this.generateComplianceTasks(startupId);
      
      // Clear existing tasks for this startup
      const { error: deleteError } = await supabase
        .from('compliance_checks')
        .delete()
        .eq('startup_id', startupId);
      
      if (deleteError) {
        console.error('Error clearing existing compliance tasks:', deleteError);
        throw deleteError;
      }
      
      // Insert new tasks
      if (tasks.length > 0) {
        const taskRecords = tasks.map(task => ({
          startup_id: startupId,
          task_id: task.task_id,
          entity_identifier: task.entity_identifier,
          entity_display_name: task.entity_display_name,
          year: task.year,
          task_name: task.task_name,
          ca_required: task.ca_required,
          cs_required: task.cs_required,
          task_type: task.task_type,
          ca_status: 'Pending',
          cs_status: 'Pending'
        }));
        
        console.log('🔍 Inserting compliance task records:', taskRecords);
        
        const { error: insertError } = await supabase
          .from('compliance_checks')
          .insert(taskRecords);
        
        if (insertError) {
          console.error('Error inserting compliance tasks:', insertError);
          throw insertError;
        }
      }
      
      console.log('🔍 Compliance tasks synced successfully');
      return true;
    } catch (error) {
      console.error('Error syncing compliance tasks:', error);
      return false;
    }
  },

  // Get compliance tasks for a startup
  async getComplianceTasks(startupId: number): Promise<any[]> {
    try {
      const { data, error } = await supabase
        .from('compliance_checks')
        .select('*')
        .eq('startup_id', startupId)
        .order('year', { ascending: false })
        .order('task_name', { ascending: true });
      
      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching compliance tasks:', error);
      return [];
    }
  },

  // Update compliance task status
  async updateComplianceTaskStatus(
    startupId: number,
    taskId: string,
    type: 'ca' | 'cs',
    status: string
  ): Promise<boolean> {
    try {
      const updateData = type === 'ca' 
        ? { ca_status: status }
        : { cs_status: status };

      const { error } = await supabase
        .from('compliance_checks')
        .update(updateData)
        .eq('startup_id', startupId)
        .eq('task_id', taskId);

      if (error) throw error;
      return true;
    } catch (error) {
      console.error('Error updating compliance task status:', error);
      return false;
    }
  }
};
