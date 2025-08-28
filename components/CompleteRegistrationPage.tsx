import React, { useState, useEffect } from 'react';
import Card from './ui/Card';
import Button from './ui/Button';
import Input from './ui/Input';
import { UserRole } from '../types';
import { FileText, Users, CheckCircle } from 'lucide-react';
import LogoTMS from './public/logoTMS.svg';
import { authService } from '../lib/auth';
import { storageService } from '../lib/storage';

interface Founder {
  id: string;
  name: string;
  email: string;
}

interface CompleteRegistrationPageProps {
  onNavigateToRegister: () => void;
  onNavigateToDashboard: () => void;
}

export const CompleteRegistrationPage: React.FC<CompleteRegistrationPageProps> = ({
  onNavigateToRegister,
  onNavigateToDashboard
}) => {
  const [userData, setUserData] = useState<any>(null);
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
  const [isCheckingUser, setIsCheckingUser] = useState(true);

  useEffect(() => {
    checkUserAndRedirect();
  }, []);

  const checkUserAndRedirect = async () => {
    try {
      const { data: { user }, error } = await authService.supabase.auth.getUser();
      
      if (error || !user) {
        // No user found, redirect to login
        onNavigateToRegister();
        return;
      }

      // Check if user already has a complete profile using the new method
      const isComplete = await authService.isProfileComplete(user.id);
      
      if (isComplete) {
        // User already has complete profile, redirect to dashboard
        onNavigateToDashboard();
        return;
      }

      // Get user profile for display
      const { data: profile } = await authService.supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .single();

      // User needs to complete Step 2
      setUserData({
        id: user.id,
        email: user.email,
        name: profile?.name || user.user_metadata?.name || 'User',
        role: profile?.role || user.user_metadata?.role || 'Investor',
        startupName: profile?.startup_name || user.user_metadata?.startupName
      });
      
    } catch (err) {
      console.error('Error checking user:', err);
      onNavigateToRegister();
    } finally {
      setIsCheckingUser(false);
    }
  };

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
      // Upload documents to storage
      let governmentIdUrl = '';
      let roleSpecificUrl = '';

      console.log('📁 Starting file uploads...', { govId: uploadedFiles.govId, roleSpecific: uploadedFiles.roleSpecific });

      if (uploadedFiles.govId) {
        console.log('📤 Uploading government ID...');
        const result = await storageService.uploadVerificationDocument(
          uploadedFiles.govId, 
          userData.email, 
          'government-id'
        );
        if (result.success && result.url) {
          governmentIdUrl = result.url;
          console.log('✅ Government ID uploaded successfully:', governmentIdUrl);
        } else {
          console.error('❌ Government ID upload failed:', result);
        }
      }

      if (uploadedFiles.roleSpecific) {
        const roleDocType = getRoleSpecificDocumentType(userData.role);
        console.log('📤 Uploading role-specific document:', roleDocType);
        const result = await storageService.uploadVerificationDocument(
          uploadedFiles.roleSpecific, 
          userData.email, 
          roleDocType
        );
        if (result.success && result.url) {
          roleSpecificUrl = result.url;
          console.log('✅ Role-specific document uploaded successfully:', roleSpecificUrl);
        } else {
          console.error('❌ Role-specific document upload failed:', result);
        }
      }

      console.log('📊 Upload results:', { governmentIdUrl, roleSpecificUrl });

      // Update user profile with documents
      console.log('💾 Updating user profile in database...', {
        userId: userData.id,
        governmentId: governmentIdUrl,
        caLicense: roleSpecificUrl,
        verificationDocuments: [governmentIdUrl, roleSpecificUrl]
      });

      const { error: updateError } = await authService.supabase
        .from('users')
        .update({
          government_id: governmentIdUrl,
          ca_license: roleSpecificUrl,
          verification_documents: [governmentIdUrl, roleSpecificUrl],
          updated_at: new Date().toISOString()
        })
        .eq('id', userData.id);

      if (updateError) {
        console.error('❌ Database update failed:', updateError);
        throw new Error('Failed to update user profile');
      }

      console.log('✅ User profile updated successfully in database');

      // If user is a startup, create startup and founders
      if (userData.role === 'Startup') {
        try {
          const { data: startup } = await authService.supabase
            .from('startups')
            .insert({
              name: userData.startupName || `${userData.name}'s Startup`,
              investment_type: 'Seed',
              investment_value: 0,
              equity_allocation: 0,
              current_valuation: 0,
              compliance_status: 'Pending',
              sector: 'Technology',
              total_funding: 0,
              total_revenue: 0,
              registration_date: new Date().toISOString().split('T')[0],
              user_id: userData.id
            })
            .select()
            .single();

          if (startup && founders.length > 0) {
            const foundersData = founders.map(founder => ({
              startup_id: startup.id,
              name: founder.name,
              email: founder.email
            }));

            await authService.supabase
              .from('founders')
              .insert(foundersData);
          }
        } catch (error) {
          console.error('Error creating startup:', error);
        }
      }

      // Registration complete! Redirect to dashboard
      console.log('🎉 Registration complete! Redirecting to dashboard...');
      onNavigateToDashboard();
      
    } catch (error: any) {
      setError(error.message || 'An error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  if (isCheckingUser) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <Card className="w-full max-w-md">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-brand-primary mx-auto"></div>
            <p className="mt-4 text-slate-600">Checking your account...</p>
          </div>
        </Card>
      </div>
    );
  }

  if (!userData) {
    return null;
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 py-12">
      <Card className="w-full max-w-2xl">
        <div className="text-center mb-8">
          <img src={LogoTMS} alt="TrackMyStartup" className="mx-auto h-40 w-40" />
          <h2 className="mt-4 text-3xl font-bold tracking-tight text-slate-900">Complete Your Registration</h2>
          <p className="mt-2 text-sm text-slate-600">
            TrackMyStartup - Welcome, {userData.name}! Please upload your verification documents to complete your profile.
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

          {/* Submit Button */}
          <Button
            type="submit"
            className="w-full"
            disabled={isLoading}
          >
            {isLoading ? 'Completing Registration...' : 'Complete Registration'}
          </Button>
        </form>
      </Card>
    </div>
  );
};
