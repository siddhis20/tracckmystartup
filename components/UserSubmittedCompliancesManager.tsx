import React, { useState, useEffect } from 'react';
import { 
  userSubmittedCompliancesService, 
  UserSubmittedCompliance, 
  UserSubmittedComplianceFormData,
  ComplianceApprovalData 
} from '../lib/userSubmittedCompliancesService';
import { complianceRulesComprehensiveService } from '../lib/complianceRulesComprehensiveService';

interface UserSubmittedCompliancesManagerProps {
  currentUser: any;
}

const UserSubmittedCompliancesManager: React.FC<UserSubmittedCompliancesManagerProps> = ({ currentUser }) => {
  const [submissions, setSubmissions] = useState<UserSubmittedCompliance[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedSubmission, setSelectedSubmission] = useState<UserSubmittedCompliance | null>(null);
  const [showApprovalModal, setShowApprovalModal] = useState(false);
  const [approvalData, setApprovalData] = useState<ComplianceApprovalData>({
    status: 'under_review',
    review_notes: ''
  });
  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    approved: 0,
    rejected: 0,
    under_review: 0
  });

  const loadData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const [submissionsData, statsData] = await Promise.all([
        userSubmittedCompliancesService.getAllSubmissions(),
        userSubmittedCompliancesService.getSubmissionStats()
      ]);
      
      setSubmissions(submissionsData);
      setStats(statsData);
    } catch (err) {
      console.error('Error loading submissions:', err);
      setError('Failed to load submissions');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleApproveSubmission = async (submissionId: number) => {
    try {
      setError(null);
      
      // First approve and promote to main rules
      await userSubmittedCompliancesService.approveAndPromoteToMainRules(submissionId);
      
      // Reload data
      await loadData();
      
      setShowApprovalModal(false);
      setSelectedSubmission(null);
      
      alert('Compliance approved and added to main rules successfully!');
    } catch (err) {
      console.error('Error approving submission:', err);
      setError('Failed to approve submission');
    }
  };

  const handleRejectSubmission = async () => {
    if (!selectedSubmission) return;
    
    try {
      setError(null);
      
      await userSubmittedCompliancesService.updateSubmissionStatus(
        selectedSubmission.id, 
        approvalData
      );
      
      // Reload data
      await loadData();
      
      setShowApprovalModal(false);
      setSelectedSubmission(null);
      setApprovalData({ status: 'under_review', review_notes: '' });
      
      alert('Submission rejected successfully!');
    } catch (err) {
      console.error('Error rejecting submission:', err);
      setError('Failed to reject submission');
    }
  };

  const handleDeleteSubmission = async (submissionId: number) => {
    if (!confirm('Are you sure you want to delete this submission? This action cannot be undone.')) {
      return;
    }
    
    try {
      setError(null);
      
      await userSubmittedCompliancesService.deleteSubmission(submissionId);
      
      // Reload data
      await loadData();
      
      alert('Submission deleted successfully!');
    } catch (err) {
      console.error('Error deleting submission:', err);
      setError('Failed to delete submission');
    }
  };

  const getStatusBadge = (status: string) => {
    const statusColors = {
      pending: 'bg-yellow-100 text-yellow-800',
      approved: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800',
      under_review: 'bg-blue-100 text-blue-800'
    };
    
    return (
      <span className={`px-2 py-1 text-xs font-medium rounded-full ${statusColors[status as keyof typeof statusColors]}`}>
        {status.replace('_', ' ').toUpperCase()}
      </span>
    );
  };

  const getOperationTypeBadge = (operationType: string) => {
    const typeColors = {
      parent: 'bg-purple-100 text-purple-800',
      subsidiary: 'bg-indigo-100 text-indigo-800',
      international: 'bg-orange-100 text-orange-800'
    };
    
    return (
      <span className={`px-2 py-1 text-xs font-medium rounded-full ${typeColors[operationType as keyof typeof typeColors]}`}>
        {operationType.toUpperCase()}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">New Compliances Added by Users</h2>
          <p className="text-gray-600">Review and approve compliance submissions from users</p>
        </div>
        <button
          onClick={loadData}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          Refresh
        </button>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-2xl font-bold text-gray-900">{stats.total}</div>
          <div className="text-sm text-gray-600">Total Submissions</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-2xl font-bold text-yellow-600">{stats.pending}</div>
          <div className="text-sm text-gray-600">Pending Review</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-2xl font-bold text-blue-600">{stats.under_review}</div>
          <div className="text-sm text-gray-600">Under Review</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-2xl font-bold text-green-600">{stats.approved}</div>
          <div className="text-sm text-gray-600">Approved</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-2xl font-bold text-red-600">{stats.rejected}</div>
          <div className="text-sm text-gray-600">Rejected</div>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Submissions Table */}
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Submitted By
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Company & Operation
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Compliance
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Country
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Submitted
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {submissions.map((submission) => (
                <tr key={submission.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">
                        {submission.submitted_by_name}
                      </div>
                      <div className="text-sm text-gray-500">
                        {submission.submitted_by_role} • {submission.submitted_by_email}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">
                        {submission.company_name}
                      </div>
                      <div className="text-sm text-gray-500">
                        {submission.company_type}
                      </div>
                      <div className="mt-1">
                        {getOperationTypeBadge(submission.operation_type)}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div>
                      <div className="text-sm font-medium text-gray-900">
                        {submission.compliance_name}
                      </div>
                      <div className="text-sm text-gray-500">
                        {submission.frequency} • {submission.verification_required}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">
                      {submission.country_name} ({submission.country_code})
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {getStatusBadge(submission.status)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {new Date(submission.created_at).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                    {submission.status === 'pending' && (
                      <>
                        <button
                          onClick={() => {
                            setSelectedSubmission(submission);
                            setApprovalData({ status: 'approved', review_notes: '' });
                            setShowApprovalModal(true);
                          }}
                          className="text-green-600 hover:text-green-900"
                        >
                          Approve
                        </button>
                        <button
                          onClick={() => {
                            setSelectedSubmission(submission);
                            setApprovalData({ status: 'rejected', review_notes: '' });
                            setShowApprovalModal(true);
                          }}
                          className="text-red-600 hover:text-red-900"
                        >
                          Reject
                        </button>
                      </>
                    )}
                    <button
                      onClick={() => handleDeleteSubmission(submission.id)}
                      className="text-gray-600 hover:text-gray-900"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {submissions.length === 0 && (
          <div className="text-center py-12">
            <div className="text-gray-500">No user submissions found</div>
          </div>
        )}
      </div>

      {/* Approval Modal */}
      {showApprovalModal && selectedSubmission && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="mt-3">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                {approvalData.status === 'approved' ? 'Approve' : 'Reject'} Submission
              </h3>
              
              <div className="mb-4">
                <div className="text-sm text-gray-600 mb-2">
                  <strong>Compliance:</strong> {selectedSubmission.compliance_name}
                </div>
                <div className="text-sm text-gray-600 mb-2">
                  <strong>Company:</strong> {selectedSubmission.company_name}
                </div>
                <div className="text-sm text-gray-600 mb-2">
                  <strong>Operation Type:</strong> {selectedSubmission.operation_type}
                </div>
              </div>

              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Review Notes
                </label>
                <textarea
                  value={approvalData.review_notes}
                  onChange={(e) => setApprovalData(prev => ({ ...prev, review_notes: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={3}
                  placeholder="Add review notes..."
                />
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  onClick={() => {
                    setShowApprovalModal(false);
                    setSelectedSubmission(null);
                    setApprovalData({ status: 'under_review', review_notes: '' });
                  }}
                  className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
                >
                  Cancel
                </button>
                {approvalData.status === 'approved' ? (
                  <button
                    onClick={() => handleApproveSubmission(selectedSubmission.id)}
                    className="px-4 py-2 text-sm font-medium text-white bg-green-600 rounded-md hover:bg-green-700"
                  >
                    Approve & Add to Main Rules
                  </button>
                ) : (
                  <button
                    onClick={handleRejectSubmission}
                    className="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700"
                  >
                    Reject
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserSubmittedCompliancesManager;
