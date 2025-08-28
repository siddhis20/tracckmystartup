import React, { useState } from 'react';
import { BasicRegistrationStep } from './BasicRegistrationStep';
import { DocumentUploadStep } from './DocumentUploadStep';
import { UserRole } from '../types';
import { authService, AuthUser } from '../lib/auth';
import { storageService } from '../lib/storage';

interface TwoStepRegistrationProps {
  onRegister: (user: any, founders: any[], startupName?: string) => void;
  onNavigateToLogin: () => void;
  onNavigateToLanding?: () => void;
}

export const TwoStepRegistration: React.FC<TwoStepRegistrationProps> = ({
  onRegister,
  onNavigateToLogin,
  onNavigateToLanding
}) => {
  const [currentStep, setCurrentStep] = useState<'basic' | 'documents'>('basic');
  const [userData, setUserData] = useState<{
    name: string;
    email: string;
    password: string;
    role: UserRole;
    startupName?: string;
    country: string;
  } | null>(() => {
    // Try to restore data from localStorage
    const saved = localStorage.getItem('registrationData');
    if (saved) {
      const data = JSON.parse(saved);
      // If we have saved data, start at documents step
      setCurrentStep('documents');
      return data;
    }
    return null;
  });

  const handleEmailVerified = (data: {
    name: string;
    email: string;
    password: string;
    role: UserRole;
    startupName?: string;
    country: string;
  }) => {
    // Save data to localStorage
    localStorage.setItem('registrationData', JSON.stringify(data));
    setUserData(data);
    setCurrentStep('documents');
  };

  const handleBackToBasic = () => {
    setCurrentStep('basic');
    setUserData(null);
    // Clear saved data when going back
    localStorage.removeItem('registrationData');
  };

  const handleComplete = async (
    userData: any, 
    documents: any, 
    founders: any[]
  ) => {
    try {
      // Clear saved data after successful completion
      localStorage.removeItem('registrationData');
      
      // Upload documents to storage
      let governmentIdUrl = '';
      let roleSpecificUrl = '';

      if (documents.govId) {
        const result = await storageService.uploadVerificationDocument(
          documents.govId, 
          userData.email, 
          'government-id'
        );
        if (result.success && result.url) {
          governmentIdUrl = result.url;
        }
      }

      if (documents.roleSpecific) {
        const roleDocType = getRoleSpecificDocumentType(userData.role);
        const result = await storageService.uploadVerificationDocument(
          documents.roleSpecific, 
          userData.email, 
          roleDocType
        );
        if (result.success && result.url) {
          roleSpecificUrl = result.url;
        }
      }

      // Get current user to update their profile
      const { data: { user }, error: userError } = await authService.supabase.auth.getUser();
      
      if (userError || !user) {
        throw new Error('User not authenticated');
      }

      // Update user profile with documents
      const { data: updatedProfile, error: updateError } = await authService.supabase
        .from('users')
        .update({
          government_id: governmentIdUrl,
          ca_license: roleSpecificUrl,
          verification_documents: [governmentIdUrl, roleSpecificUrl].filter(Boolean),
          updated_at: new Date().toISOString()
        })
        .eq('id', user.id)
        .select()
        .single();

      if (updateError) {
        throw new Error('Failed to update user profile');
      }

      // If user is a startup, ensure startup and founders are created
      if (userData.role === 'Startup') {
        try {
          // Check if startup already exists
          const { data: existingStartup } = await authService.supabase
            .from('startups')
            .select('id')
            .eq('name', userData.startupName || `${userData.name}'s Startup`)
            .single();

          let startupId = existingStartup?.id;

          if (!existingStartup) {
            // Create startup if it doesn't exist
            const { data: newStartup } = await authService.supabase
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
                user_id: user.id
              })
              .select()
              .single();
            startupId = newStartup?.id;
          }

          // Add founders if startup exists and founders provided
          if (startupId && founders.length > 0) {
            const foundersData = founders.map(founder => ({
              startup_id: startupId,
              name: founder.name,
              email: founder.email
            }));

            await authService.supabase
              .from('founders')
              .insert(foundersData);
          }
        } catch (error) {
          console.error('Error handling startup/founders:', error);
        }
      }

      // Create AuthUser object for the callback
      const authUser: AuthUser = {
        id: updatedProfile.id,
        email: updatedProfile.email,
        name: updatedProfile.name,
        role: updatedProfile.role,
        startup_name: updatedProfile.startup_name,
        investor_code: updatedProfile.investor_code,
        ca_code: updatedProfile.ca_code,
        cs_code: updatedProfile.cs_code,
        registration_date: updatedProfile.registration_date,
        phone: updatedProfile.phone,
        address: updatedProfile.address,
        city: updatedProfile.city,
        state: updatedProfile.state,
        country: updatedProfile.country,
        company: updatedProfile.company,
        government_id: updatedProfile.government_id,
        ca_license: updatedProfile.ca_license,
        verification_documents: updatedProfile.verification_documents,
        profile_photo_url: updatedProfile.profile_photo_url,
        is_profile_complete: true
      };

      // Registration successful
      onRegister(
        authUser, 
        userData.role === 'Startup' ? founders : [], 
        userData.role === 'Startup' ? userData.startupName : undefined
      );

    } catch (error: any) {
      console.error('Registration error:', error);
      // Handle error appropriately
      throw error;
    }
  };

  const getRoleSpecificDocumentType = (role: UserRole): string => {
    switch (role) {
      case 'Investor': return 'pan-card';
      case 'Startup': return 'company-registration';
      case 'CA': return 'ca-license';
      case 'CS': return 'cs-license';
      case 'Startup Facilitation Center': return 'org-registration';
      default: return 'document';
    }
  };

  if (currentStep === 'documents' && userData) {
    return (
      <DocumentUploadStep
        userData={userData}
        onComplete={handleComplete}
        onBack={handleBackToBasic}
      />
    );
  }

  return (
    <BasicRegistrationStep
      onEmailVerified={handleEmailVerified}
      onNavigateToLogin={onNavigateToLogin}
      onNavigateToLanding={onNavigateToLanding}
    />
  );
};
