import { supabase } from './supabase';
import { Startup, ComplianceStatus } from '../types';

// Cache CS code to avoid excessive lookups
let cachedCSCode: string | null = null;
let csCodeCacheExpiry: number = 0;
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

export interface CSStartup {
  id: number;
  name: string;
  sector: string;
  complianceStatus: ComplianceStatus;
  totalFunding: number;
  totalRevenue: number;
  registrationDate: string;
  assignmentDate: string;
  assignmentStatus: string;
  notes?: string;
}

export interface CSStats {
  totalStartups: number;
  pendingReview: number;
  compliant: number;
  nonCompliant: number;
  activeAssignments: number;
  pendingRequests: number;
}

export interface CSAssignmentRequest {
  id: number;
  startupId: number;
  startupName: string;
  requestDate: string;
  status: 'pending' | 'approved' | 'rejected';
  notes?: string;
}

export const csService = {
  // Get CS code for current user
  async getCSCode(): Promise<string | null> {
    try {
      const now = Date.now();
      if (cachedCSCode && now < csCodeCacheExpiry) {
        return cachedCSCode;
      }
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        console.log('No authenticated user found');
        return null;
      }

      console.log('Getting CS code for user ID:', user.id);

      const { data, error } = await supabase
        .from('users')
        .select('cs_code, role, name')
        .eq('id', user.id)
        .single();

      if (error) {
        console.error('Database error fetching CS code:', error);
        throw error;
      }

      console.log('User data from database:', data);
      const csCode = (data as any)?.cs_code;
      console.log('CS code found:', csCode);
      
      cachedCSCode = csCode || null;
      csCodeCacheExpiry = Date.now() + CACHE_DURATION;
      return cachedCSCode;
    } catch (err) {
      console.error('Error fetching CS code:', err);
      return null;
    }
  },

  // Get startups assigned to the current CS
  async getAssignedStartups(): Promise<CSStartup[]> {
    try {
      const csCode = await this.getCSCode();
      if (!csCode) {
        console.log('No CS code found for current user');
        return [];
      }

      console.log('Fetching assigned startups for CS code:', csCode);

      // Expect an RPC similar to CA: get_cs_startups(cs_code_param)
      const { data, error } = await supabase
        .rpc('get_cs_startups', { cs_code_param: csCode });

      if (error) {
        console.error('RPC error:', error);
        throw error;
      }

      console.log('RPC response data:', data);

      const startupIds = (data || []).map((item: any) => item.startup_id);
      if (startupIds.length === 0) {
        console.log('No assigned startups found');
        return [];
      }

      const { data: startupDetails, error: startupError } = await supabase
        .from('startups')
        .select('*')
        .in('id', startupIds);

      if (startupError) throw startupError;

      const result: CSStartup[] = (data || []).map((assignment: any) => {
        const startup = (startupDetails || []).find((s: any) => s.id === assignment.startup_id);
        return {
          id: assignment.startup_id,
          name: assignment.startup_name,
          sector: startup?.sector || 'Unknown',
          complianceStatus: startup?.compliance_status || ComplianceStatus.Pending,
          totalFunding: startup?.total_funding || 0,
          totalRevenue: startup?.total_revenue || 0,
          registrationDate: startup?.registration_date || '',
          assignmentDate: assignment.assignment_date,
          assignmentStatus: assignment.status,
        };
      });

      // Only show active assignments
      const activeOnly = result.filter(s => s.assignmentStatus === 'active');

      console.log('Processed assigned startups:', activeOnly);
      return activeOnly;
    } catch (err) {
      console.error('Error fetching assigned CS startups:', err);
      return [];
    }
  },

  // Request assignment to a startup
  async requestAssignment(startupId: number, startupName: string, notes?: string): Promise<{ success: boolean; error?: string }> {
    try {
      const csCode = await this.getCSCode();
      if (!csCode) {
        return { success: false, error: 'CS code not found' };
      }

      const { error } = await supabase
        .from('cs_assignments')
        .insert({
          cs_code: csCode,
          startup_id: startupId,
          status: 'pending',
          notes: notes || `Assignment request from CS ${csCode}`
        });

      if (error) throw error;
      return { success: true };
    } catch (err) {
      console.error('Error requesting assignment:', err);
      return { success: false, error: 'Failed to request assignment' };
    }
  },

  // Get startups that have requested this specific CS
  async getAvailableStartups(): Promise<Startup[]> {
    try {
      const csCode = await this.getCSCode();
      if (!csCode) {
        console.log('No CS code found for current user');
        return [];
      }

      console.log('Fetching startups that requested CS code:', csCode);

      // Use the RPC function instead of direct table access to avoid RLS issues
      const { data: requests, error: requestsError } = await supabase
        .rpc('get_cs_assignment_requests', { cs_code_param: csCode });

      if (requestsError) throw requestsError;

      console.log('CS assignment requests found:', requests);

      if (!requests || requests.length === 0) {
        console.log('No pending requests found for this CS');
        return [];
      }

      // Get startup details for the requested startups
      const startupIds = requests.map(req => req.startup_id);
      const { data: startupDetails, error: startupError } = await supabase
        .from('startups')
        .select('*')
        .in('id', startupIds);

      if (startupError) throw startupError;

      console.log('Startup details found:', startupDetails);

      return startupDetails || [];
    } catch (err) {
      console.error('Error fetching available startups:', err);
      return [];
    }
  },

  // Update startup compliance status (CS verification)
  async updateComplianceStatus(startupId: number, status: ComplianceStatus, notes?: string): Promise<{ success: boolean; error?: string }> {
    try {
      const csCode = await this.getCSCode();
      if (!csCode) {
        return { success: false, error: 'CS code not found' };
      }

      // Verify CS has assignment to this startup
      const { data: assignment, error: assignmentError } = await supabase
        .from('cs_assignments')
        .select('*')
        .eq('cs_code', csCode)
        .eq('startup_id', startupId)
        .eq('status', 'active')
        .single();

      if (assignmentError || !assignment) {
        return { success: false, error: 'Not assigned to this startup' };
      }

      // Update startup compliance status
      const { error: updateError } = await supabase
        .from('startups')
        .update({ 
          compliance_status: status,
          cs_verification_date: new Date().toISOString(),
          cs_verification_notes: notes
        })
        .eq('id', startupId);

      if (updateError) throw updateError;

      return { success: true };
    } catch (err) {
      console.error('Error updating compliance status:', err);
      return { success: false, error: 'Failed to update compliance status' };
    }
  },

  // Get CS dashboard statistics
  async getCSStats(): Promise<CSStats> {
    try {
      const [assignedStartups, assignmentRequests] = await Promise.all([
        this.getAssignedStartups(),
        this.getAssignmentRequests()
      ]);
      
      return {
        totalStartups: assignedStartups.length,
        pendingReview: assignedStartups.filter(s => s.complianceStatus === ComplianceStatus.Pending).length,
        compliant: assignedStartups.filter(s => s.complianceStatus === ComplianceStatus.Compliant).length,
        nonCompliant: assignedStartups.filter(s => s.complianceStatus === ComplianceStatus.NonCompliant).length,
        activeAssignments: assignedStartups.filter(s => s.assignmentStatus === 'active').length,
        pendingRequests: assignmentRequests.filter(r => r.status === 'pending').length,
      };
    } catch (err) {
      console.error('Error fetching CS stats:', err);
      return {
        totalStartups: 0,
        pendingReview: 0,
        compliant: 0,
        nonCompliant: 0,
        activeAssignments: 0,
        pendingRequests: 0,
      };
    }
  },

  // Assign CS to a startup
  async assignToStartup(startupId: number, notes?: string): Promise<boolean> {
    try {
      const csCode = await this.getCSCode();
      if (!csCode) return false;

      const { data, error } = await supabase
        .rpc('assign_cs_to_startup', {
          cs_code_param: csCode,
          startup_id_param: startupId,
          notes_param: notes
        });

      if (error) throw error;
      return data;
    } catch (err) {
      console.error('Error assigning CS to startup:', err);
      return false;
    }
  },

  // Get assignment requests for the current CS
  async getAssignmentRequests(): Promise<CSAssignmentRequest[]> {
    try {
      const csCode = await this.getCSCode();
      if (!csCode) return [];

      const { data, error } = await supabase
        .rpc('get_cs_assignment_requests', { cs_code_param: csCode });

      if (error) throw error;

      return (data || []).map((req: any) => ({
        id: req.id,
        startupId: req.startup_id,
        startupName: req.startup_name,
        requestDate: req.request_date,
        status: req.status,
        notes: req.notes,
      }));
    } catch (err) {
      console.error('Error fetching assignment requests:', err);
      return [];
    }
  },

  // Approve assignment request
  async approveAssignmentRequest(requestId: number): Promise<boolean> {
    try {
      const csCode = await this.getCSCode();
      console.log('🔍 Approving request:', { requestId, csCode });
      
      if (!csCode) {
        console.error('❌ No CS code found for current user');
        return false;
      }

      const { data, error } = await supabase
        .rpc('approve_cs_assignment_request', {
          request_id_param: requestId,
          cs_code_param: csCode,
          response_notes_param: 'Approved via CS dashboard'
        });

      console.log('🔍 RPC response:', { data, error });

      if (error) {
        console.error('❌ RPC error:', error);
        throw error;
      }
      
      console.log('✅ Approval successful:', data);
      return data;
    } catch (err) {
      console.error('❌ Error approving assignment request:', err);
      return false;
    }
  },

  // Reject assignment request
  async rejectAssignmentRequest(requestId: number, notes?: string): Promise<boolean> {
    try {
      const csCode = await this.getCSCode();
      if (!csCode) return false;

      const { data, error } = await supabase
        .rpc('reject_cs_assignment_request', {
          request_id_param: requestId,
          cs_code_param: csCode,
          response_notes_param: notes || 'Rejected via CS dashboard'
        });

      if (error) throw error;
      return data;
    } catch (err) {
      console.error('Error rejecting assignment request:', err);
      return false;
    }
  },

  // Remove assignment (for CS to unassign themselves)
  async removeAssignment(startupId: number): Promise<boolean> {
    try {
      const csCode = await this.getCSCode();
      if (!csCode) return false;

      const { data, error } = await supabase
        .rpc('remove_cs_assignment', {
          cs_code_param: csCode,
          startup_id_param: startupId
        });

      if (error) {
        console.error('RPC error:', error);
        throw error;
      }
      return data;
    } catch (err) {
      console.error('Error removing assignment:', err);
      return false;
    }
  },

  // Get all startups (for CS to browse and request assignments)
  async getAllStartups(): Promise<Startup[]> {
    try {
      const { data, error } = await supabase
        .from('startups')
        .select('*')
        .order('name');

      if (error) throw error;
      return data || [];
    } catch (err) {
      console.error('Error fetching all startups:', err);
      return [];
    }
  },

  // Check if CS is assigned to a specific startup
  async isAssignedToStartup(startupId: number): Promise<boolean> {
    try {
      const csCode = await this.getCSCode();
      if (!csCode) return false;

      const { data, error } = await supabase
        .from('cs_assignments')
        .select('id')
        .eq('cs_code', csCode)
        .eq('startup_id', startupId)
        .eq('status', 'active')
        .single();

      if (error && error.code !== 'PGRST116') throw error; // PGRST116 = no rows returned
      return !!data;
    } catch (err) {
      console.error('Error checking CS assignment:', err);
      return false;
    }
  },

  // Get assignment details for a specific startup
  async getAssignmentDetails(startupId: number): Promise<any> {
    try {
      const csCode = await this.getCSCode();
      if (!csCode) return null;

      const { data, error } = await supabase
        .from('cs_assignments')
        .select('*')
        .eq('cs_code', csCode)
        .eq('startup_id', startupId)
        .single();

      if (error && error.code !== 'PGRST116') throw error;
      return data;
    } catch (err) {
      console.error('Error fetching assignment details:', err);
      return null;
    }
  }
};



