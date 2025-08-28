import { supabase } from './supabase';
import { Startup, ComplianceStatus } from '../types';

export interface StartupCSRequest {
  id: number;
  startup_id: number;
  startup_name: string;
  cs_code: string;
  status: 'pending' | 'approved' | 'rejected';
  notes?: string;
  request_date: string;
  response_date?: string;
  response_notes?: string;
}

export interface AvailableCS {
  cs_code: string;
  name: string;
  email: string;
}

export const startupService = {
  // Get current user's startup
  async getCurrentStartup(): Promise<Startup | null> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;

      const { data, error } = await supabase
        .from('startups')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (error) throw error;
      return data;
    } catch (err) {
      console.error('Error fetching current startup:', err);
      return null;
    }
  },

  // Request CS assignment using CS code
  async requestCSAssignment(csCode: string, notes?: string, startupId?: number, startupName?: string): Promise<{ success: boolean; error?: string }> {
    try {
      console.log('🔍 requestCSAssignment called with:', { csCode, notes, startupId, startupName });
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        console.log('❌ User not authenticated');
        return { success: false, error: 'User not authenticated' };
      }

      let startup = { id: startupId, name: startupName };

      // If startup details not provided, try to get them from database
      if (!startupId || !startupName) {
        console.log('🔍 Startup details not provided, querying database...');
        const { data: startupData, error: startupError } = await supabase
          .from('startups')
          .select('id, name')
          .eq('user_id', user.id)
          .single();

        if (startupError || !startupData) {
          console.log('❌ Startup not found:', { startupError, startup: startupData });
          return { success: false, error: 'Startup not found for current user' };
        }
        startup = startupData;
      }

      console.log('✅ Using startup:', startup);
      // Skip direct CS user verification here to avoid RLS/read issues.
      // The RPC and database constraints will validate cs_code integrity.

      // Create assignment request
      console.log('🔍 Calling create_cs_assignment_request with:', {
        startup_id_param: startup.id,
        startup_name_param: startup.name,
        cs_code_param: csCode,
        notes_param: notes
      });

      const { data, error } = await supabase
        .rpc('create_cs_assignment_request', {
          startup_id_param: startup.id,
          startup_name_param: startup.name,
          cs_code_param: csCode,
          request_message_param: notes
        });

      console.log('🔍 RPC response:', { data, error });

      if (error) {
        console.log('❌ RPC error:', error);
        throw error;
      }
      
      console.log('✅ Request creation result:', data);
      return { success: data };
    } catch (err) {
      console.error('❌ Error requesting CS assignment:', err);
      return { success: false, error: 'Failed to request CS assignment' };
    }
  },

  // Get CS assignment requests for current startup
  async getCSAssignmentRequests(): Promise<StartupCSRequest[]> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return [];

      // Get startup ID for current user
      const { data: startup, error: startupError } = await supabase
        .from('startups')
        .select('id')
        .eq('user_id', user.id)
        .single();

      if (startupError || !startup) return [];

      // Get assignment requests
      const { data, error } = await supabase
        .rpc('get_startup_cs_requests', { startup_id_param: startup.id });

      if (error) throw error;
      return data || [];
    } catch (err) {
      console.error('Error fetching CS assignment requests:', err);
      return [];
    }
  },

  // Get available CS users (for startup to browse)
  async getAvailableCS(): Promise<AvailableCS[]> {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('cs_code, name, email')
        .eq('role', 'CS')
        .not('cs_code', 'is', null)
        .order('name');

      if (error) throw error;
      return data || [];
    } catch (err) {
      console.error('Error fetching available CS:', err);
      return [];
    }
  },

  // Update startup profile
  async updateProfile(updates: Partial<Startup>): Promise<{ success: boolean; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return { success: false, error: 'User not authenticated' };
      }

      const { error } = await supabase
        .from('startups')
        .update(updates)
        .eq('user_id', user.id);

      if (error) throw error;
      return { success: true };
    } catch (err) {
      console.error('Error updating startup profile:', err);
      return { success: false, error: 'Failed to update profile' };
    }
  },

  // Get startup compliance status
  async getComplianceStatus(): Promise<ComplianceStatus | null> {
    try {
      const startup = await this.getCurrentStartup();
      return startup?.compliance_status || null;
    } catch (err) {
      console.error('Error getting compliance status:', err);
      return null;
    }
  }
};



