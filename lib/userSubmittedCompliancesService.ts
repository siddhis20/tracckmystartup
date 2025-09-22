import { supabase } from './supabase';

// Types for user-submitted compliances
export interface UserSubmittedCompliance {
  id: number;
  submitted_by_user_id: string;
  submitted_by_name: string;
  submitted_by_role: string;
  submitted_by_email: string;
  company_name: string;
  company_type: string;
  operation_type: 'parent' | 'subsidiary' | 'international';
  country_code: string;
  country_name: string;
  ca_type?: string;
  cs_type?: string;
  compliance_name: string;
  compliance_description?: string;
  frequency: 'first-year' | 'monthly' | 'quarterly' | 'annual';
  verification_required: 'CA' | 'CS' | 'both';
  justification?: string;
  supporting_documents?: string[];
  regulatory_reference?: string;
  status: 'pending' | 'approved' | 'rejected' | 'under_review';
  reviewed_by_user_id?: string;
  reviewed_at?: string;
  review_notes?: string;
  created_at: string;
  updated_at: string;
}

export interface UserSubmittedComplianceFormData {
  company_name: string;
  company_type: string;
  operation_type: 'parent' | 'subsidiary' | 'international';
  country_code: string;
  country_name: string;
  ca_type?: string;
  cs_type?: string;
  compliance_name: string;
  compliance_description?: string;
  frequency: 'first-year' | 'monthly' | 'quarterly' | 'annual';
  verification_required: 'CA' | 'CS' | 'both';
  justification?: string;
  supporting_documents?: string[];
  regulatory_reference?: string;
}

export interface ComplianceApprovalData {
  status: 'approved' | 'rejected' | 'under_review';
  review_notes?: string;
}

class UserSubmittedCompliancesService {
  // Get all user-submitted compliances (for admin)
  async getAllSubmissions(): Promise<UserSubmittedCompliance[]> {
    const { data, error } = await supabase
      .from('user_submitted_compliances')
      .select(`
        *,
        submitted_by:submitted_by_user_id(name, email, role),
        reviewed_by:reviewed_by_user_id(name, email)
      `)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching user submitted compliances:', error);
      throw new Error('Failed to fetch user submitted compliances');
    }

    return data || [];
  }

  // Get submissions by current user
  async getMySubmissions(): Promise<UserSubmittedCompliance[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    const { data, error } = await supabase
      .from('user_submitted_compliances')
      .select('*')
      .eq('submitted_by_user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching my submissions:', error);
      throw new Error('Failed to fetch my submissions');
    }

    return data || [];
  }

  // Submit a new compliance
  async submitCompliance(formData: UserSubmittedComplianceFormData): Promise<UserSubmittedCompliance> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    // Get user profile for submission details
    const { data: userProfile, error: profileError } = await supabase
      .from('users')
      .select('name, email, role')
      .eq('id', user.id)
      .single();

    if (profileError || !userProfile) {
      throw new Error('Failed to get user profile');
    }

    const submissionData = {
      ...formData,
      submitted_by_user_id: user.id,
      submitted_by_name: userProfile.name,
      submitted_by_role: userProfile.role,
      submitted_by_email: userProfile.email,
      status: 'pending' as const
    };

    const { data, error } = await supabase
      .from('user_submitted_compliances')
      .insert(submissionData)
      .select()
      .single();

    if (error) {
      console.error('Error submitting compliance:', error);
      throw new Error('Failed to submit compliance');
    }

    return data;
  }

  // Update submission status (admin only)
  async updateSubmissionStatus(
    submissionId: number, 
    approvalData: ComplianceApprovalData
  ): Promise<UserSubmittedCompliance> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    const updateData = {
      ...approvalData,
      reviewed_by_user_id: user.id,
      reviewed_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('user_submitted_compliances')
      .update(updateData)
      .eq('id', submissionId)
      .select()
      .single();

    if (error) {
      console.error('Error updating submission status:', error);
      throw new Error('Failed to update submission status');
    }

    return data;
  }

  // Approve and promote to main compliance rules
  async approveAndPromoteToMainRules(submissionId: number): Promise<void> {
    // First, get the submission
    const { data: submission, error: fetchError } = await supabase
      .from('user_submitted_compliances')
      .select('*')
      .eq('id', submissionId)
      .single();

    if (fetchError || !submission) {
      throw new Error('Failed to fetch submission');
    }

    // Create the compliance rule in main table
    const complianceRule = {
      country_code: submission.country_code,
      country_name: submission.country_name,
      ca_type: submission.ca_type,
      cs_type: submission.cs_type,
      company_type: submission.company_type,
      compliance_name: submission.compliance_name,
      compliance_description: submission.compliance_description,
      frequency: submission.frequency,
      verification_required: submission.verification_required
    };

    const { error: insertError } = await supabase
      .from('compliance_rules_comprehensive')
      .insert(complianceRule);

    if (insertError) {
      console.error('Error promoting to main rules:', insertError);
      throw new Error('Failed to promote to main compliance rules');
    }

    // Update submission status to approved
    await this.updateSubmissionStatus(submissionId, {
      status: 'approved',
      review_notes: 'Approved and promoted to main compliance rules'
    });
  }

  // Delete submission (admin only)
  async deleteSubmission(submissionId: number): Promise<void> {
    const { error } = await supabase
      .from('user_submitted_compliances')
      .delete()
      .eq('id', submissionId);

    if (error) {
      console.error('Error deleting submission:', error);
      throw new Error('Failed to delete submission');
    }
  }

  // Get submission statistics
  async getSubmissionStats(): Promise<{
    total: number;
    pending: number;
    approved: number;
    rejected: number;
    under_review: number;
  }> {
    const { data, error } = await supabase
      .from('user_submitted_compliances')
      .select('status');

    if (error) {
      console.error('Error fetching submission stats:', error);
      throw new Error('Failed to fetch submission statistics');
    }

    const stats = {
      total: data.length,
      pending: data.filter(item => item.status === 'pending').length,
      approved: data.filter(item => item.status === 'approved').length,
      rejected: data.filter(item => item.status === 'rejected').length,
      under_review: data.filter(item => item.status === 'under_review').length
    };

    return stats;
  }
}

export const userSubmittedCompliancesService = new UserSubmittedCompliancesService();
