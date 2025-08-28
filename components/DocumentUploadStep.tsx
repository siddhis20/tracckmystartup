import React, { useState } from 'react';
import Card from './ui/Card';
import Button from './ui/Button';
import Input from './ui/Input';
import { UserRole } from '../types';
import { Upload, FileText, Users, CheckCircle } from 'lucide-react';
import LogoTMS from './public/logoTMS.svg';

interface Founder {
  id: string;
  name: string;
  email: string;
}

interface DocumentUploadStepProps {
  userData: {
    name: string;
    email: string;
    password: string;
    role: UserRole;
    startupName?: string;
    country: string;
  };
  onComplete: (userData: any, documents: any, founders: Founder[]) => void;
  onBack: () => void;
}

export const DocumentUploadStep: React.FC<DocumentUploadStepProps> = ({
  userData,
  onComplete,
  onBack
}) => {
  const [uploadedFiles, setUploadedFiles] = useState<{
    govId: File | null;
    roleSpecific: File | null;
  }>({
    govId: null,
    roleSpecific: null
  });

  const [founders, setFounders] = useState<Founder[]>([
    { id: '1', name: '', email: '' }
  ]);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>, documentType: string) => {
    const file = event.target.files?.[0];
    if (file) {
      setUploadedFiles(prev => ({ ...prev, [documentType]: file }));
    }
  };

  const addFounder = () => {
    const newId = (founders.length + 1).toString();
    setFounders(prev => [...prev, { id: newId, name: '', email: '' }]);
  };

  const removeFounder = (id: string) => {
    if (founders.length > 1) {
      setFounders(prev => prev.filter(founder => founder.id !== id));
    }
  };

  const updateFounder = (id: string, field: 'name' | 'email', value: string) => {
    setFounders(prev => prev.map(founder => 
      founder.id === id ? { ...founder, [field]: value } : founder
    ));
  };

  const getRoleSpecificDocumentType = (role: UserRole): string => {
    switch (role) {
      case 'Investor': return 'PAN Card';
      case 'Startup': return 'Proof of Company Registration';
      case 'CA': return 'Copy of CA License';
      case 'CS': return 'Copy of CS License';
      case 'Startup Facilitation Center': return 'Proof of Organization Registration';
      default: return 'Document';
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    // Validation
    if (!uploadedFiles.govId) {
      setError('Government ID is required');
      setIsLoading(false);
      return;
    }

    if (!uploadedFiles.roleSpecific) {
      setError(`${getRoleSpecificDocumentType(userData.role)} is required`);
      setIsLoading(false);
      return;
    }

    if (userData.role === 'Startup') {
      const invalidFounders = founders.filter(f => !f.name.trim() || !f.email.trim());
      if (invalidFounders.length > 0) {
        setError('Please fill in all founder details');
        setIsLoading(false);
        return;
      }
    }

    try {
      // Simulate document upload and profile creation
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Call the completion handler
      onComplete(userData, uploadedFiles, founders);
      
    } catch (err: any) {
      setError(err.message || 'An error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Card className="w-full max-w-2xl">
      <div className="text-center mb-8">
        <img src={LogoTMS} alt="TrackMyStartup" className="mx-auto h-40 w-40" />
        <h2 className="mt-4 text-3xl font-bold tracking-tight text-slate-900">Complete Your Profile</h2>
        <p className="mt-2 text-sm text-slate-600">
          TrackMyStartup - Welcome, {userData.name}! Now let's upload your verification documents.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Verification Documents */}
        <div className="space-y-4">
          <h3 className="text-lg font-semibold text-slate-900 flex items-center">
            <FileText className="h-5 w-5 mr-2" />
            Verification Documents
          </h3>
          
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">
                Government ID (Passport, Driver's License, etc.)
              </label>
              <Input
                type="file"
                accept=".pdf,.jpg,.jpeg,.png"
                onChange={(e) => handleFileChange(e, 'govId')}
                required
              />
              {uploadedFiles.govId && (
                <p className="text-sm text-green-600 mt-1">
                  ✓ {uploadedFiles.govId.name} selected
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">
                {getRoleSpecificDocumentType(userData.role)}
              </label>
              <Input
                type="file"
                accept=".pdf,.jpg,.jpeg,.png"
                onChange={(e) => handleFileChange(e, 'roleSpecific')}
                required
              />
              {uploadedFiles.roleSpecific && (
                <p className="text-sm text-green-600 mt-1">
                  ✓ {uploadedFiles.roleSpecific.name} selected
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Founder Information - Only for Startup role */}
        {userData.role === 'Startup' && (
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-slate-900 flex items-center">
              <Users className="h-5 w-5 mr-2" />
              Founder Information
            </h3>
            <p className="text-sm text-slate-600">
              Please provide the details of all founders.
            </p>
            
            <div className="space-y-4">
              {founders.map((founder, index) => (
                <div key={founder.id} className="p-4 border border-slate-200 rounded-md">
                  <div className="flex items-center justify-between mb-3">
                    <h4 className="font-medium text-slate-900">Founder {index + 1}</h4>
                    {founders.length > 1 && (
                      <button
                        type="button"
                        onClick={() => removeFounder(founder.id)}
                        className="text-red-600 hover:text-red-800 text-sm"
                      >
                        Remove
                      </button>
                    )}
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <Input
                      label="Name"
                      value={founder.name}
                      onChange={(e) => updateFounder(founder.id, 'name', e.target.value)}
                      required
                    />
                    <Input
                      label="Email"
                      type="email"
                      value={founder.email}
                      onChange={(e) => updateFounder(founder.id, 'email', e.target.value)}
                      required
                    />
                  </div>
                </div>
              ))}
              
              <Button
                type="button"
                onClick={addFounder}
                variant="outline"
                className="w-full"
              >
                <Users className="h-4 w-4 mr-2" />
                Add Another Founder
              </Button>
            </div>
          </div>
        )}

        {/* Error Display */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-md p-4">
            <div className="text-sm text-red-800">
              <strong>Error:</strong> {error}
            </div>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex gap-4">
          <Button
            type="button"
            onClick={onBack}
            variant="outline"
            className="flex-1"
          >
            Back
          </Button>
          
          <Button
            type="submit"
            className="flex-1"
            disabled={isLoading}
          >
            {isLoading ? 'Creating Profile...' : 'Complete Registration'}
          </Button>
        </div>
      </form>
    </Card>
  );
};
