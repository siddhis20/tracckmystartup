import React, { useState } from 'react';
import { 
  userSubmittedCompliancesService, 
  UserSubmittedComplianceFormData 
} from '../lib/userSubmittedCompliancesService';

interface ComplianceSubmissionFormProps {
  currentUser: any;
  onSuccess?: () => void;
  onCancel?: () => void;
}

const ComplianceSubmissionForm: React.FC<ComplianceSubmissionFormProps> = ({ 
  currentUser, 
  onSuccess, 
  onCancel 
}) => {
  const [formData, setFormData] = useState<UserSubmittedComplianceFormData>({
    company_name: '',
    company_type: '',
    operation_type: 'parent',
    country_code: '',
    country_name: '',
    ca_type: '',
    cs_type: '',
    compliance_name: '',
    compliance_description: '',
    frequency: 'annual',
    verification_required: 'both',
    justification: '',
    supporting_documents: [],
    regulatory_reference: ''
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);
      setError(null);
      
      // Validate required fields
      if (!formData.company_name || !formData.company_type || !formData.compliance_name) {
        throw new Error('Please fill in all required fields');
      }
      
      await userSubmittedCompliancesService.submitCompliance(formData);
      
      setSuccess(true);
      if (onSuccess) onSuccess();
      
    } catch (err) {
      console.error('Error submitting compliance:', err);
      setError(err instanceof Error ? err.message : 'Failed to submit compliance');
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setFormData({
      company_name: '',
      company_type: '',
      operation_type: 'parent',
      country_code: '',
      country_name: '',
      ca_type: '',
      cs_type: '',
      compliance_name: '',
      compliance_description: '',
      frequency: 'annual',
      verification_required: 'both',
      justification: '',
      supporting_documents: [],
      regulatory_reference: ''
    });
    setError(null);
    setSuccess(false);
  };

  if (success) {
    return (
      <div className="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow">
        <div className="text-center">
          <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100 mb-4">
            <svg className="h-6 w-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">Compliance Submitted Successfully!</h3>
          <p className="text-gray-600 mb-4">
            Your compliance submission has been received and is pending admin review. 
            You will be notified once it's been reviewed.
          </p>
          <div className="flex justify-center space-x-3">
            <button
              onClick={handleReset}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              Submit Another
            </button>
            {onCancel && (
              <button
                onClick={onCancel}
                className="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400"
              >
                Close
              </button>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow">
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Submit New Compliance</h2>
        <p className="text-gray-600 mt-2">
          Submit a new compliance requirement for your company's parent operations, subsidiaries, or international operations.
        </p>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Company Information */}
        <div className="bg-gray-50 p-4 rounded-lg">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Company Information</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Company Name *
              </label>
              <input
                type="text"
                name="company_name"
                value={formData.company_name}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter company name"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Company Type *
              </label>
              <input
                type="text"
                name="company_type"
                value={formData.company_type}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="e.g., Private Limited Company"
              />
            </div>
          </div>

          <div className="mt-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Operation Type *
            </label>
            <select
              name="operation_type"
              value={formData.operation_type}
              onChange={handleInputChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="parent">Parent Company</option>
              <option value="subsidiary">Subsidiary</option>
              <option value="international">International Operations</option>
            </select>
          </div>
        </div>

        {/* Location Information */}
        <div className="bg-gray-50 p-4 rounded-lg">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Location Information</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Country Code *
              </label>
              <input
                type="text"
                name="country_code"
                value={formData.country_code}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="e.g., IN, US, UK"
                maxLength={10}
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Country Name *
              </label>
              <input
                type="text"
                name="country_name"
                value={formData.country_name}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="e.g., India, United States"
              />
            </div>
          </div>
        </div>

        {/* Professional Types */}
        <div className="bg-gray-50 p-4 rounded-lg">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Professional Types</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                CA Type
              </label>
              <input
                type="text"
                name="ca_type"
                value={formData.ca_type}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="e.g., Chartered Accountant"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                CS Type
              </label>
              <input
                type="text"
                name="cs_type"
                value={formData.cs_type}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="e.g., Company Secretary"
              />
            </div>
          </div>
        </div>

        {/* Compliance Details */}
        <div className="bg-gray-50 p-4 rounded-lg">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Compliance Details</h3>
          
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Compliance Name *
              </label>
              <input
                type="text"
                name="compliance_name"
                value={formData.compliance_name}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="e.g., Annual Return Filing"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Compliance Description
              </label>
              <textarea
                name="compliance_description"
                value={formData.compliance_description}
                onChange={handleInputChange}
                rows={3}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Describe the compliance requirement..."
              />
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Frequency *
                </label>
                <select
                  name="frequency"
                  value={formData.frequency}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="first-year">First Year</option>
                  <option value="monthly">Monthly</option>
                  <option value="quarterly">Quarterly</option>
                  <option value="annual">Annual</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Verification Required *
                </label>
                <select
                  name="verification_required"
                  value={formData.verification_required}
                  onChange={handleInputChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="CA">CA</option>
                  <option value="CS">CS</option>
                  <option value="both">Both</option>
                </select>
              </div>
            </div>
          </div>
        </div>

        {/* Additional Information */}
        <div className="bg-gray-50 p-4 rounded-lg">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Additional Information</h3>
          
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Justification
              </label>
              <textarea
                name="justification"
                value={formData.justification}
                onChange={handleInputChange}
                rows={3}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Explain why this compliance is needed..."
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Regulatory Reference
              </label>
              <input
                type="text"
                name="regulatory_reference"
                value={formData.regulatory_reference}
                onChange={handleInputChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="e.g., Section 92 of Companies Act, 2013"
              />
            </div>
          </div>
        </div>

        {/* Form Actions */}
        <div className="flex justify-end space-x-3">
          {onCancel && (
            <button
              type="button"
              onClick={onCancel}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
            >
              Cancel
            </button>
          )}
          <button
            type="button"
            onClick={handleReset}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
          >
            Reset
          </button>
          <button
            type="submit"
            disabled={loading}
            className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Submitting...' : 'Submit Compliance'}
          </button>
        </div>
      </form>
    </div>
  );
};

export default ComplianceSubmissionForm;
