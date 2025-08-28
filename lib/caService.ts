import { supabase } from './supabase';
import { Startup, ComplianceStatus } from '../types';

export interface CAStartup {
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

export interface CAStats {
  totalStartups: number;
  pendingReview: number;
  compliant: number;
  nonCompliant: number;
  activeAssignments: number;
  pendingRequests: number;
}

export interface CAAssignmentRequest {
  id: number;
  startupId: number;
  startupName: string;
  requestDate: string;
  status: 'pending' | 'approved' | 'rejected';
  notes?: string;
}

export const caService = {
  // Get CA code for current user
  async getCACode(): Promise<string | null> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;

      const { data, error } = await supabase
        .from('users')
        .select('ca_code')
        .eq('id', user.id)
        .single();

      if (error) throw error;
      return data?.ca_code || null;
    } catch (err) {
      console.error('Error fetching CA code:', err);
      return null;
    }
  },

  // Get startups assigned to the current CA
  async getAssignedStartups(): Promise<CAStartup[]> {
    try {
      const caCode = await this.getCACode();
      if (!caCode) return [];

      const { data, error } = await supabase
        .rpc('get_ca_startups', { ca_code_param: caCode });

      if (error) throw error;

      // Fetch additional startup details
      const startupIds = data.map((item: any) => item.startup_id);
      
      if (startupIds.length === 0) return [];

      const { data: startupDetails, error: startupError } = await supabase
        .from('startups')
        .select('*')
        .in('id', startupIds);

      if (startupError) throw startupError;

      // Merge assignment data with startup details
      const result = data.map((assignment: any) => {
        const startup = startupDetails.find((s: any) => s.id === assignment.startup_id);
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
      
      return result;
    } catch (err) {
      console.error('Error fetching assigned startups:', err);
      return [];
    }
  },

  // Get CA dashboard statistics
  async getCAStats(): Promise<CAStats> {
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
      console.error('Error fetching CA stats:', err);
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

  // Update compliance status for a startup
  async updateComplianceStatus(startupId: number, status: ComplianceStatus): Promise<boolean> {
    try {
      const { error } = await supabase
        .from('startups')
        .update({ compliance_status: status })
        .eq('id', startupId);

      if (error) throw error;
      return true;
    } catch (err) {
      console.error('Error updating compliance status:', err);
      return false;
    }
  },

  // Assign CA to a startup
  async assignToStartup(startupId: number, notes?: string): Promise<boolean> {
    try {
      const caCode = await this.getCACode();
      if (!caCode) return false;

      const { data, error } = await supabase
        .rpc('assign_ca_to_startup', {
          ca_code_param: caCode,
          startup_id_param: startupId,
          notes_param: notes
        });

      if (error) throw error;
      return data;
    } catch (err) {
      console.error('Error assigning CA to startup:', err);
      return false;
    }
  },

  // Remove CA assignment from startup
  async removeAssignment(startupId: number): Promise<boolean> {
    try {
      const caCode = await this.getCACode();
      if (!caCode) return false;

      const { data, error } = await supabase
        .rpc('remove_ca_assignment', {
          ca_code_param: caCode,
          startup_id_param: startupId
        });

      if (error) throw error;
      return data;
    } catch (err) {
      console.error('Error removing CA assignment:', err);
      return false;
    }
  },

  // Get all startups (for CA to browse and request assignments)
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

  // Check if CA is assigned to a specific startup
  async isAssignedToStartup(startupId: number): Promise<boolean> {
    try {
      const caCode = await this.getCACode();
      if (!caCode) return false;

      const { data, error } = await supabase
        .from('ca_assignments')
        .select('id')
        .eq('ca_code', caCode)
        .eq('startup_id', startupId)
        .eq('status', 'active')
        .single();

      if (error && error.code !== 'PGRST116') throw error; // PGRST116 = no rows returned
      return !!data;
    } catch (err) {
      console.error('Error checking CA assignment:', err);
      return false;
    }
  },

  // Get assignment details for a specific startup
  async getAssignmentDetails(startupId: number): Promise<any> {
    try {
      const caCode = await this.getCACode();
      if (!caCode) return null;

      const { data, error } = await supabase
        .from('ca_assignments')
        .select('*')
        .eq('ca_code', caCode)
        .eq('startup_id', startupId)
        .single();

      if (error && error.code !== 'PGRST116') throw error;
      return data;
    } catch (err) {
      console.error('Error fetching assignment details:', err);
      return null;
    }
  },

  // Get CA assignment requests
  async getAssignmentRequests(): Promise<CAAssignmentRequest[]> {
    try {
      const caCode = await this.getCACode();
      if (!caCode) return [];

      const { data, error } = await supabase
        .rpc('get_ca_assignment_requests', { ca_code_param: caCode });

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
      console.error('Error fetching CA assignment requests:', err);
      return [];
    }
  },

  // Approve CA assignment request
  async approveAssignmentRequest(requestId: number): Promise<boolean> {
    try {
      const caCode = await this.getCACode();
      if (!caCode) return false;

      const { data, error } = await supabase
        .rpc('approve_ca_assignment_request', {
          request_id_param: requestId,
          ca_code_param: caCode
        });

      if (error) throw error;
      return data;
    } catch (err) {
      console.error('Error approving CA assignment request:', err);
      return false;
    }
  },

  // Reject CA assignment request
  async rejectAssignmentRequest(requestId: number, notes?: string): Promise<boolean> {
    try {
      const caCode = await this.getCACode();
      if (!caCode) return false;

      const { data, error } = await supabase
        .rpc('reject_ca_assignment_request', {
          request_id_param: requestId,
          ca_code_param: caCode,
          rejection_notes: notes
        });

      if (error) throw error;
      return data;
    } catch (err) {
      console.error('Error rejecting CA assignment request:', err);
      return false;
    }
  }
};
