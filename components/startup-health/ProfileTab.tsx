import React, { useState, useEffect } from 'react';
import { Startup, Subsidiary, InternationalOp, ProfileData, ServiceProvider } from '../../types';
import { profileService, ProfileNotification } from '../../lib/profileService';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import { Plus, Trash2, Edit3, Save, X, Bell, UserCheck, ShieldCheck, Download } from 'lucide-react';

interface ProfileTabProps {
  startup: Startup;
  userRole?: string;
  onProfileUpdate?: (startup: Startup) => void;
  isViewOnly?: boolean;
}

type LocalSubsidiary = Subsidiary & { 
  caCode?: string; 
  csCode?: string;
  ca?: ServiceProvider;
  cs?: ServiceProvider;
};

type LocalFormData = Omit<ProfileData, 'subsidiaries'> & {
  subsidiaries: LocalSubsidiary[];
  caCode?: string;
  csCode?: string;
  ca?: ServiceProvider;
  cs?: ServiceProvider;
};

const FormInput: React.FC<React.InputHTMLAttributes<HTMLInputElement> & { label: string }> = ({ label, ...props }) => (
  <div>
    <label className="block text-sm font-medium text-slate-700 mb-1">{label}</label>
    <input {...props} className="w-full bg-white border border-slate-300 rounded-md px-3 py-2 text-slate-900 focus:ring-blue-500 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed" />
  </div>
);

const ServiceCodeInput: React.FC<{
  name: string;
  placeholder: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  disabled?: boolean;
  isValid?: boolean;
  isInvalid?: boolean;
  isLoading?: boolean;
  errorMessage?: string;
}> = ({ name, placeholder, value, onChange, disabled, isValid, isInvalid, isLoading, errorMessage }) => (
  <div className="relative">
    <input
      name={name}
      placeholder={placeholder}
      value={value}
      onChange={onChange}
      disabled={disabled}
      className={`w-full bg-white border rounded-md px-3 py-2 text-slate-900 focus:ring-blue-500 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed pr-10 ${
        isInvalid 
          ? 'border-red-500 focus:ring-red-500 focus:border-red-500' 
          : isValid 
            ? 'border-green-500 focus:ring-green-500 focus:border-green-500'
            : 'border-slate-300'
      }`}
    />
    
    {/* Validation Status Icon */}
    <div className="absolute right-3 top-1/2 transform -translate-y-1/2">
      {isLoading ? (
        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
      ) : isValid ? (
        <div className="w-4 h-4 bg-green-500 rounded-full flex items-center justify-center">
          <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
          </svg>
        </div>
      ) : isInvalid ? (
        <div className="w-4 h-4 bg-red-500 rounded-full flex items-center justify-center">
          <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
          </svg>
        </div>
      ) : null}
    </div>
    
    {/* Error Message */}
    {isInvalid && errorMessage && (
      <p className="mt-1 text-sm text-red-600">{errorMessage}</p>
    )}
  </div>
);

const FormSelect: React.FC<React.SelectHTMLAttributes<HTMLSelectElement> & { label: string; children: React.ReactNode }> = ({ label, children, ...props }) => (
  <div>
    <label className="block text-sm font-medium text-slate-700 mb-1">{label}</label>
    <select {...props} className="w-full bg-white border border-slate-300 rounded-md px-3 py-2 text-slate-900 focus:ring-blue-500 focus:border-blue-500 disabled:opacity-50 disabled:cursor-not-allowed">
      {children}
    </select>
  </div>
);

const ServiceProviderDisplay: React.FC<{ 
  provider: ServiceProvider; 
  onRemove: () => void; 
  isEditing: boolean;
  type: 'ca' | 'cs';
}> = ({ provider, onRemove, isEditing, type }) => (
  <div className="bg-gradient-to-r from-slate-50 to-blue-50 p-4 rounded-xl border border-slate-200 flex justify-between items-center h-full shadow-sm hover:shadow-md transition-shadow">
    <div>
      <p className="font-bold text-slate-900">{provider.name}</p>
      <p className="text-sm text-slate-600 mt-1">Code: {provider.code}</p>
    </div>
    {isEditing && (
      <button 
        onClick={onRemove} 
        className="text-slate-600 hover:text-red-600 font-semibold text-sm bg-white px-3 py-1 rounded-lg border border-slate-200 hover:border-red-200 transition-colors"
      >
        Change
      </button>
    )}
  </div>
);

const ProfileTab: React.FC<ProfileTabProps> = ({ startup, userRole, onProfileUpdate, isViewOnly = false }) => {
      const [isEditing, setIsEditing] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  const [notifications, setNotifications] = useState<ProfileNotification[]>([]);
  const [csRequestLoading, setCsRequestLoading] = useState(false);
  
  // Validation status for CA/CS codes
  const [caCodeValidation, setCaCodeValidation] = useState<{
    isValid: boolean;
    isInvalid: boolean;
    isLoading: boolean;
    errorMessage: string;
  }>({ isValid: false, isInvalid: false, isLoading: false, errorMessage: '' });
  
  const [csCodeValidation, setCsCodeValidation] = useState<{
    isValid: boolean;
    isInvalid: boolean;
    isLoading: boolean;
    errorMessage: string;
  }>({ isValid: false, isInvalid: false, isLoading: false, errorMessage: '' });
  
  const [subsidiaryCodeValidation, setSubsidiaryCodeValidation] = useState<{
    [key: number]: {
      ca: { isValid: boolean; isInvalid: boolean; isLoading: boolean; errorMessage: string; };
      cs: { isValid: boolean; isInvalid: boolean; isLoading: boolean; errorMessage: string; };
    };
  }>({});
    // CA should have view-only access across tabs except compliance. No profile editing.
    const canEdit = (userRole === 'Startup' || userRole === 'Admin') && !isViewOnly;
    
    // Helper function to sanitize profile data and ensure all values are strings
    const sanitizeProfileData = (data: any): LocalFormData => {
        console.log('🔍 Sanitizing profile data:', data);
        
        const sanitized = {
        country: data.country || 'United States',
        companyType: data.companyType || 'C-Corporation',
        registrationDate: data.registrationDate || '',
        subsidiaries: (data.subsidiaries || []).map((sub: any) => ({
            id: sub.id || 0,
            country: sub.country || 'United States',
            companyType: sub.companyType || 'LLC',
                registrationDate: sub.registrationDate || '',
                caCode: sub.caCode || sub.ca_service_code || '',
                csCode: sub.csCode || sub.cs_service_code || '',
                ca: sub.ca || undefined,
                cs: sub.cs || undefined,
        })),
        internationalOps: (data.internationalOps || []).map((op: any) => ({
            id: op.id || 0,
            country: op.country || 'Germany',
                startDate: op.startDate || ''
            })),
            caServiceCode: data.caServiceCode || data.ca_service_code || '',
            csServiceCode: data.csServiceCode || data.cs_service_code || '',
            caCode: data.caServiceCode || data.ca_service_code || '',
            csCode: data.csServiceCode || data.cs_service_code || '',
            ca: data.ca || undefined,
            cs: data.cs || undefined,
        };
        
        console.log('🔍 Sanitized profile data:', sanitized);
        return sanitized;
    };
    
    // Real profile data from database
  const [formData, setFormData] = useState<LocalFormData>({
        country: 'United States',
        companyType: 'C-Corporation',
        registrationDate: startup.registrationDate || new Date().toISOString().split('T')[0],
    subsidiaries: [],
    internationalOps: [],
        caServiceCode: '',
        csServiceCode: '',
    });

    // Load profile data
    useEffect(() => {
        const loadProfileData = async () => {
            try {
                setIsLoading(true);
                const profileData = await profileService.getStartupProfile(startup.id);
                
                if (profileData) {
                    // Sanitize profile data to ensure all values are properly initialized
                    const sanitizedData = sanitizeProfileData(profileData);
          setFormData(sanitizedData);
                }
                
                // Load notifications
                const profileNotifications = await profileService.getProfileNotifications(startup.id);
                setNotifications(profileNotifications);
            } catch (error) {
                console.error('Error loading profile data:', error);
            } finally {
                setIsLoading(false);
            }
        };

        loadProfileData();
    }, [startup.id]);

    // Real-time subscriptions - Simplified approach
    useEffect(() => {
        console.log('Setting up real-time subscriptions for startup:', startup.id);
        
        // Subscribe to startups table changes
        const startupsSubscription = profileService.supabase
            .channel(`startup_profile_${startup.id}`)
            .on(
                'postgres_changes',
                {
                    event: 'UPDATE',
                    schema: 'public',
                    table: 'startups',
                    filter: `id=eq.${startup.id}`
                },
                (payload) => {
                    console.log('Startup profile updated:', payload);
                    // Refresh profile data
                    profileService.getStartupProfile(startup.id).then(profileData => {
                        if (profileData) {
              setFormData(sanitizeProfileData(profileData));
                        }
                    });
                }
            )
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'subsidiaries',
                    filter: `startup_id=eq.${startup.id}`
                },
                (payload) => {
                    console.log('Subsidiary change detected:', payload);
                    // Refresh profile data
                    profileService.getStartupProfile(startup.id).then(profileData => {
                        if (profileData) {
              setFormData(sanitizeProfileData(profileData));
                        }
                    });
                }
            )
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'international_ops',
                    filter: `startup_id=eq.${startup.id}`
                },
                (payload) => {
                    console.log('International operation change detected:', payload);
                    // Refresh profile data
                    profileService.getStartupProfile(startup.id).then(profileData => {
                        if (profileData) {
              setFormData(sanitizeProfileData(profileData));
                        }
                    });
                }
            )
            .subscribe();

        return () => {
            console.log('Cleaning up real-time subscriptions');
            startupsSubscription.unsubscribe();
        };
    }, [startup.id]);

    // Get dynamic data
  const companyTypesByCountry = profileService.getCompanyTypesByCountry(formData.country, startup.sector);
    const allCountries = profileService.getAllCountries();

    // Auto-fix invalid company types when profile loads
    React.useEffect(() => {
    if (formData.country && formData.companyType) {
      const validTypes = profileService.getCompanyTypesByCountry(formData.country);
      if (!validTypes.includes(formData.companyType)) {
        console.log(`🔧 Auto-fixing invalid company type: ${formData.companyType} -> ${validTypes[0]} for country: ${formData.country}`);
        setFormData(prev => ({
                    ...prev,
                    companyType: validTypes[0]
                }));
            }
        }
  }, [formData.country, formData.companyType]);

  const handleEdit = () => setIsEditing(true);

  const handleCancel = () => {
    setIsEditing(false);
    // Reload original data
    profileService.getStartupProfile(startup.id).then(profileData => {
      if (profileData) {
        setFormData(sanitizeProfileData(profileData));
      }
    });
  };

    const handleSave = async () => {
        try {
            console.log('🔍 Starting save process...');
            console.log('🔍 Profile data to save:', formData);
            
            // First validate basic profile data
            const validation = profileService.validateProfileData(formData);
            if (!validation.isValid) {
                const errorMessage = validation.errors.map(error => {
                    if (error === 'Invalid company type for selected country') {
                        const validTypes = profileService.getCompanyTypesByCountry(formData.country);
                        return `Invalid company type for ${formData.country}. Valid types are: ${validTypes.join(', ')}`;
                    }
                    return error;
                }).join('\n');
                setValidationErrors(errorMessage.split('\n'));
                // Scroll to top where the banner is
                window.scrollTo({ top: 0, behavior: 'smooth' });
                return;
            }

            // Then validate CA/CS service codes against backend
            console.log('🔍 Validating CA/CS service codes...');
            const serviceCodeValidation = await profileService.validateServiceCodes(formData);
            if (!serviceCodeValidation.isValid) {
                const errorMessage = serviceCodeValidation.errors.join('\n');
                setValidationErrors(errorMessage.split('\n'));
                // Scroll to top where the banner is
                window.scrollTo({ top: 0, behavior: 'smooth' });
                return;
            }
            
            setValidationErrors([]);

            console.log('🔍 Calling updateStartupProfile...');
            console.log('🔍 CA Service Code being saved:', formData.caServiceCode);
            console.log('🔍 CS Service Code being saved:', formData.csServiceCode);
            const success = await profileService.updateStartupProfile(startup.id, formData);
            console.log('🔍 Update result:', success);
            
            // Handle subsidiaries - add, update, or delete as needed
            console.log('🔍 Processing subsidiaries...');
            const currentSubsidiaries = await profileService.getStartupProfile(startup.id);
            const existingSubIds = currentSubsidiaries?.subsidiaries?.map(sub => sub.id) || [];
            const newSubIds = formData.subsidiaries.map(sub => sub.id);
            
            // Delete subsidiaries that are no longer in the list
            for (const existingId of existingSubIds) {
                if (!newSubIds.includes(existingId)) {
                    console.log(`🔍 Deleting subsidiary ${existingId}`);
                    await profileService.deleteSubsidiary(existingId);
                }
            }
            
            // Add or update subsidiaries
            for (let i = 0; i < formData.subsidiaries.length; i++) {
                const sub = formData.subsidiaries[i];
                if (sub.id && sub.id > 0) {
                    // Update existing subsidiary
                    console.log(`🔍 Updating subsidiary ${sub.id}`);
                    await profileService.updateSubsidiary(sub.id, {
                        country: sub.country,
                        companyType: sub.companyType,
                        registrationDate: sub.registrationDate
                    });
                    
                    // Update service providers
                    if (sub.caCode) {
                        await profileService.updateSubsidiaryServiceProvider(sub.id, 'ca', sub.caCode);
                    }
                    if (sub.csCode) {
                        await profileService.updateSubsidiaryServiceProvider(sub.id, 'cs', sub.csCode);
                    }
                } else {
                    // Add new subsidiary
                    console.log(`🔍 Adding new subsidiary ${i + 1}`);
                    const newSubId = await profileService.addSubsidiary(startup.id, {
                        country: sub.country,
                        companyType: sub.companyType,
                        registrationDate: sub.registrationDate
                    });
                    
                    if (newSubId) {
                        // Update service providers for new subsidiary
                        if (sub.caCode) {
                            await profileService.updateSubsidiaryServiceProvider(newSubId, 'ca', sub.caCode);
                        }
                        if (sub.csCode) {
                            await profileService.updateSubsidiaryServiceProvider(newSubId, 'cs', sub.csCode);
                        }
                    }
                }
            }
            
            // Handle international operations - add, update, or delete as needed
            console.log('🔍 Processing international operations...');
            const existingOpIds = currentSubsidiaries?.internationalOps?.map(op => op.id) || [];
            const newOpIds = formData.internationalOps.map(op => op.id);
            
            // Delete operations that are no longer in the list
            for (const existingId of existingOpIds) {
                if (!newOpIds.includes(existingId)) {
                    console.log(`🔍 Deleting international operation ${existingId}`);
                    await profileService.deleteInternationalOp(existingId);
                }
            }
            
            // Add or update international operations
            for (let i = 0; i < formData.internationalOps.length; i++) {
                const op = formData.internationalOps[i];
                if (op.id && op.id > 0) {
                    // Update existing operation
                    console.log(`🔍 Updating international operation ${op.id}`);
                    await profileService.updateInternationalOp(op.id, {
                        country: op.country,
                        startDate: op.startDate
                    });
                } else {
                    // Add new operation
                    console.log(`🔍 Adding new international operation ${i + 1}`);
                    await profileService.addInternationalOp(startup.id, {
                        country: op.country,
                        startDate: op.startDate
                    });
                }
            }
            
            if (success) {
        setIsEditing(false);
                console.log('Profile updated successfully');
                
                // Manually refresh the profile data to ensure UI updates
                console.log('🔍 Refreshing profile data...');
                const updatedProfile = await profileService.getStartupProfile(startup.id);
                console.log('🔍 Refreshed profile data:', updatedProfile);
                if (updatedProfile) {
                    setFormData(sanitizeProfileData(updatedProfile));
                    // Notify parent so other tabs receive updated profile
                    if (onProfileUpdate) {
                        onProfileUpdate({
                            ...startup,
                            profile: {
                                country: updatedProfile.country,
                                companyType: updatedProfile.companyType,
                                registrationDate: updatedProfile.registrationDate,
                                subsidiaries: updatedProfile.subsidiaries || [],
                                internationalOps: updatedProfile.internationalOps || [],
                                caServiceCode: updatedProfile.caServiceCode,
                                csServiceCode: updatedProfile.csServiceCode,
                                ca: updatedProfile.ca,
                                cs: updatedProfile.cs,
                            },
                        });
                    }
                }
                
                // Trigger compliance task sync after profile update
                console.log('🔍 Triggering compliance task sync...');
                try {
                    await profileService.syncComplianceTasks(startup.id);
                    console.log('🔍 Compliance tasks synced successfully');
                } catch (error) {
                    console.error('❌ Error syncing compliance tasks:', error);
                }
            } else {
                console.error('❌ Failed to update profile - success was false');
                setValidationErrors(['Failed to update profile']);
            }
        } catch (error) {
            console.error('❌ Error saving profile:', error);
            setValidationErrors(['Error saving profile']);
        }
    };

  const handlePrimaryChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    if (name === 'countryOfRegistration') {
      const newCountryTypes = profileService.getCompanyTypesByCountry(value);
      setFormData(prev => ({
        ...prev,
        country: value,
        companyType: newCountryTypes[0]
      }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
  };
  
  const handleServiceCodeChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    const isCA = name === 'caCode';
    
    // Clear any previous validation errors for this field
    setValidationErrors(prev => prev.filter(error => 
      !error.includes(isCA ? 'CA code' : 'CS code')
    ));
    
    // Reset validation state for this field
    if (isCA) {
      setCaCodeValidation({ isValid: false, isInvalid: false, isLoading: false, errorMessage: '' });
    } else {
      setCsCodeValidation({ isValid: false, isInvalid: false, isLoading: false, errorMessage: '' });
    }
    
    // Keep typed code and canonical serviceCode in sync so it persists via updateStartupProfile
    setFormData(prev => ({ 
      ...prev, 
      [name]: value,
      [isCA ? 'caServiceCode' : 'csServiceCode']: value
    }));
    
    // Clear the service provider object when code changes
    setFormData(prev => ({
      ...prev,
      [isCA ? 'ca' : 'cs']: undefined
    }));
    
    // If we have a valid service code, try to fetch the service provider details
    if (value && value.length >= 3) {
      // Set loading state
      if (isCA) {
        setCaCodeValidation(prev => ({ ...prev, isLoading: true }));
      } else {
        setCsCodeValidation(prev => ({ ...prev, isLoading: true }));
      }
      
      try {
        const providerType = isCA ? 'ca' : 'cs';
        console.log('🔍 Fetching service provider:', { value, providerType });
        const provider = await profileService.getServiceProvider(value, providerType);
        console.log('🔍 Service provider result:', provider);
        
        if (provider) {
          setFormData(prev => ({
            ...prev,
            [providerType]: provider
          }));
          
          // Set valid state
          if (isCA) {
            setCaCodeValidation({ isValid: true, isInvalid: false, isLoading: false, errorMessage: '' });
          } else {
            setCsCodeValidation({ isValid: true, isInvalid: false, isLoading: false, errorMessage: '' });
          }
        } else {
          // Set invalid state
          const errorMessage = `Invalid ${isCA ? 'CA' : 'CS'} code: ${value}. Please enter a valid service provider code.`;
          if (isCA) {
            setCaCodeValidation({ isValid: false, isInvalid: true, isLoading: false, errorMessage });
          } else {
            setCsCodeValidation({ isValid: false, isInvalid: true, isLoading: false, errorMessage });
          }
          setValidationErrors(prev => [...prev, errorMessage]);
        }
        
        // If this is a CS code, automatically create an assignment request and save profile
        // (regardless of whether provider was found)
        if (!isCA && value) {
            setCsRequestLoading(true);
            try {
              // First, save the profile to ensure CS code is stored in database
              console.log('🔍 Auto-saving profile with CS code:', value);
              const saveSuccess = await profileService.updateStartupProfile(startup.id, {
                ...formData,
                csServiceCode: value
              });
              
              if (!saveSuccess) {
                throw new Error('Failed to save profile');
              }
              
              // Then create the assignment request
              const { startupService } = await import('../../lib/startupService');
              const result = await startupService.requestCSAssignment(
                value, 
                `Assignment request from ${value}`,
                startup.id,
                startup.name
              );
              
              if (result.success) {
                console.log('CS assignment request created successfully');
                // Show success notification
                setNotifications(prev => [...prev, {
                  id: Date.now(),
                  type: 'success',
                  message: `CS assignment request sent to ${value} and profile saved`,
                  timestamp: new Date()
                }]);
              } else {
                console.error('Failed to create CS assignment request:', result.error);
                // Show error notification
                setNotifications(prev => [...prev, {
                  id: Date.now(),
                  type: 'error',
                  message: `Failed to request CS assignment: ${result.error}`,
                  timestamp: new Date()
                }]);
              }
            } catch (error) {
              console.error('Error creating CS assignment request:', error);
              setNotifications(prev => [...prev, {
                id: Date.now(),
                type: 'error',
                  message: 'Failed to request CS assignment',
                  timestamp: new Date()
              }]);
            } finally {
              setCsRequestLoading(false);
            }
          }
      } catch (error) {
        console.error('Error fetching service provider:', error);
        // Show error for network/database issues
        const errorMessage = `Error validating ${isCA ? 'CA' : 'CS'} code. Please try again.`;
        if (isCA) {
          setCaCodeValidation({ isValid: false, isInvalid: true, isLoading: false, errorMessage });
        } else {
          setCsCodeValidation({ isValid: false, isInvalid: true, isLoading: false, errorMessage });
        }
        setValidationErrors(prev => [...prev, errorMessage]);
      }
    } else {
      // Clear validation state if code is too short
      if (isCA) {
        setCaCodeValidation({ isValid: false, isInvalid: false, isLoading: false, errorMessage: '' });
      } else {
        setCsCodeValidation({ isValid: false, isInvalid: false, isLoading: false, errorMessage: '' });
      }
    }
  }
  
  const handleSubsidiaryServiceCodeChange = async (index: number, e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    const isCA = name === 'caCode';
    
    // Clear any previous validation errors for this subsidiary field
    setValidationErrors(prev => prev.filter(error => 
      !error.includes(`Subsidiary ${index + 1}`) || 
      !error.includes(isCA ? 'CA code' : 'CS code')
    ));
    
    // Reset validation state for this subsidiary field
    setSubsidiaryCodeValidation(prev => ({
      ...prev,
      [index]: {
        ...prev[index],
        [isCA ? 'ca' : 'cs']: { isValid: false, isInvalid: false, isLoading: false, errorMessage: '' }
      }
    }));
    
    const newSubs = [...formData.subsidiaries];
    newSubs[index] = {...newSubs[index], [name]: value };
    setFormData(prev => ({ ...prev, subsidiaries: newSubs }));
    
    // Clear the service provider object when code changes
    newSubs[index] = {
      ...newSubs[index],
      [isCA ? 'ca' : 'cs']: undefined
    };
    setFormData(prev => ({ ...prev, subsidiaries: newSubs }));
    
    // If we have a valid service code, try to fetch the service provider details
    if (value && value.length >= 3) {
      // Set loading state
      setSubsidiaryCodeValidation(prev => ({
        ...prev,
        [index]: {
          ...prev[index],
          [isCA ? 'ca' : 'cs']: { isValid: false, isInvalid: false, isLoading: true, errorMessage: '' }
        }
      }));
      
      try {
        const providerType = isCA ? 'ca' : 'cs';
        const provider = await profileService.getServiceProvider(value, providerType);
        
        if (provider) {
          const updatedSubs = [...formData.subsidiaries];
          updatedSubs[index] = {
            ...updatedSubs[index],
            [providerType]: provider
          };
          setFormData(prev => ({ ...prev, subsidiaries: updatedSubs }));
          
          // Set valid state
          setSubsidiaryCodeValidation(prev => ({
            ...prev,
            [index]: {
              ...prev[index],
              [isCA ? 'ca' : 'cs']: { isValid: true, isInvalid: false, isLoading: false, errorMessage: '' }
            }
          }));
        } else {
          // Set invalid state
          const errorMessage = `Subsidiary ${index + 1}: Invalid ${isCA ? 'CA' : 'CS'} code "${value}". Please enter a valid service provider code.`;
          setSubsidiaryCodeValidation(prev => ({
            ...prev,
            [index]: {
              ...prev[index],
              [isCA ? 'ca' : 'cs']: { isValid: false, isInvalid: true, isLoading: false, errorMessage }
            }
          }));
          setValidationErrors(prev => [...prev, errorMessage]);
        }
          
        // If this is a CS code, automatically create an assignment request and save profile
        if (name === 'csCode' && value) {
          setCsRequestLoading(true);
          try {
            // First, save the profile to ensure CS code is stored in database
            console.log('🔍 Auto-saving profile with subsidiary CS code:', value);
            const saveSuccess = await profileService.updateStartupProfile(startup.id, formData);
            
            if (!saveSuccess) {
              throw new Error('Failed to save profile');
            }
            
            // Then create the assignment request
            const { startupService } = await import('../../lib/startupService');
            const result = await startupService.requestCSAssignment(
              value, 
              `Assignment request from ${startup.name} subsidiary`,
              startup.id,
              startup.name
            );
            
            if (result.success) {
              console.log('CS assignment request created successfully for subsidiary');
              // Show success notification
              setNotifications(prev => [...prev, {
                id: Date.now(),
                type: 'success',
                message: `CS assignment request sent to ${value} for subsidiary and profile saved`,
                timestamp: new Date()
              }]);
            } else {
              console.error('Failed to create CS assignment request for subsidiary:', result.error);
              // Show error notification
              setNotifications(prev => [...prev, {
                id: Date.now(),
                type: 'error',
                message: `Failed to request CS assignment for subsidiary: ${result.error}`,
                timestamp: new Date()
              }]);
            }
          } catch (error) {
            console.error('Error creating CS assignment request for subsidiary:', error);
            setNotifications(prev => [...prev, {
              id: Date.now(),
              type: 'error',
              message: 'Failed to request CS assignment for subsidiary',
              timestamp: new Date()
            }]);
          } finally {
            setCsRequestLoading(false);
          }
        }
      } catch (error) {
        console.error('Error fetching service provider:', error);
        // Show error for network/database issues
        const errorMessage = `Error validating ${isCA ? 'CA' : 'CS'} code. Please try again.`;
        setSubsidiaryCodeValidation(prev => ({
          ...prev,
          [index]: {
            ...prev[index],
            [isCA ? 'ca' : 'cs']: { isValid: false, isInvalid: true, isLoading: false, errorMessage }
          }
        }));
        setValidationErrors(prev => [...prev, errorMessage]);
      }
    } else {
      // Clear validation state if code is too short
      setSubsidiaryCodeValidation(prev => ({
        ...prev,
        [index]: {
          ...prev[index],
          [isCA ? 'ca' : 'cs']: { isValid: false, isInvalid: false, isLoading: false, errorMessage: '' }
        }
      }));
    }
  };
  
  const handleRemoveSubsidiaryProvider = (index: number, providerType: 'ca' | 'cs') => {
    const newSubs = [...formData.subsidiaries];
    newSubs[index] = { ...newSubs[index], [providerType]: undefined };
    setFormData(prev => ({ ...prev, subsidiaries: newSubs }));
  };

  const handleSubsidiaryCountChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const count = parseInt(e.target.value, 10);
    const currentSubs = formData.subsidiaries;
    const newSubs: LocalSubsidiary[] = [];
    
    console.log(`🔍 Changing subsidiary count from ${currentSubs.length} to ${count}`);
    
    if (count === 0) {
      // User wants 0 subsidiaries - clear the array
      console.log('🔍 Setting subsidiaries to empty array');
      setFormData(prev => ({ ...prev, subsidiaries: [] }));
      // Clear subsidiary validation states
      setSubsidiaryCodeValidation({});
    } else {
      // User wants some subsidiaries - preserve existing data where possible
      for (let i = 0; i < count; i++) {
        if (currentSubs[i]) {
          // Keep existing subsidiary data
          newSubs.push(currentSubs[i]);
        } else {
          // Create new subsidiary with default values
          newSubs.push({ 
            id: 0, 
            country: 'United States', 
            companyType: 'C-Corporation', 
            registrationDate: '',
            caCode: '',
            csCode: '',
            ca: undefined,
            cs: undefined
          });
        }
      }
      setFormData(prev => ({ ...prev, subsidiaries: newSubs }));
      
      // Initialize validation states for new subsidiaries
      const newValidationStates: typeof subsidiaryCodeValidation = {};
      for (let i = 0; i < count; i++) {
        newValidationStates[i] = {
          ca: { isValid: false, isInvalid: false, isLoading: false, errorMessage: '' },
          cs: { isValid: false, isInvalid: false, isLoading: false, errorMessage: '' }
        };
      }
      setSubsidiaryCodeValidation(newValidationStates);
    }
  };

  const handleSubsidiaryChange = (index: number, e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    const newSubs = [...formData.subsidiaries];

    if (name === 'country') {
      const newCountryTypes = profileService.getCompanyTypesByCountry(value);
      newSubs[index] = { ...newSubs[index], country: value, companyType: newCountryTypes[0] };
    } else {
      newSubs[index] = { ...newSubs[index], [name]: value };
    }

    setFormData(prev => ({ ...prev, subsidiaries: newSubs }));
  };

  const handleIntlOpsCountChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const count = parseInt(e.target.value, 10);
    const currentOps = formData.internationalOps;
    const newOps: InternationalOp[] = [];
    
    console.log(`🔍 Changing international operations count from ${currentOps.length} to ${count}`);
    
    if (count === 0) {
      // User wants 0 international operations - clear the array
      console.log('🔍 Setting international operations to empty array');
      setFormData(prev => ({ ...prev, internationalOps: [] }));
    } else {
      // User wants some international operations - preserve existing data where possible
      for (let i = 0; i < count; i++) {
        if (currentOps[i]) {
          // Keep existing operation data
          newOps.push(currentOps[i]);
        } else {
          // Create new operation with default values
          newOps.push({ 
            id: 0, 
            country: 'United States', 
            startDate: '' 
          });
        }
      }
      setFormData(prev => ({ ...prev, internationalOps: newOps }));
    }
  };

  const handleIntlOpChange = (index: number, e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    const newOps = [...formData.internationalOps];
    newOps[index] = { ...newOps[index], [name]: value };
    setFormData(prev => ({ ...prev, internationalOps: newOps }));
    };

    const markNotificationAsRead = async (notificationId: string) => {
        await profileService.markNotificationAsRead(notificationId);
        // Update local state
        setNotifications(prev => 
            prev.map(n => n.id === notificationId ? { ...n, is_read: true } : n)
        );
    };

    if (isLoading) {
        return (
            <div className="space-y-6">
                <Card>
                    <div className="animate-pulse">
                        <div className="h-4 bg-slate-200 rounded w-1/3 mb-4"></div>
                        <div className="h-32 bg-slate-200 rounded"></div>
                    </div>
                </Card>
            </div>
        );
    }

    return (
    <div className="bg-slate-50 p-8 space-y-8">
            {/* Validation Errors Banner */}
            {validationErrors.length > 0 && (
                <div className="bg-red-50 border border-red-200 text-red-800 rounded-xl p-4">
                    <div className="font-semibold mb-2">Please fix the following issues:</div>
                    <ul className="list-disc pl-5 space-y-1 text-sm">
                        {validationErrors.map((e, i) => (
                            <li key={i}>{e}</li>
                        ))}
                    </ul>
                </div>
            )}
            {/* Notifications */}
            {notifications.filter(n => !n.is_read).length > 0 && (
        <div className="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                    <div className="flex items-center gap-2 mb-4">
                        <Bell className="w-5 h-5 text-blue-600" />
                        <h3 className="text-lg font-semibold text-slate-700">Recent Updates</h3>
                    </div>
                    <div className="space-y-2">
                        {notifications.filter(n => !n.is_read).slice(0, 3).map(notification => (
                            <div key={notification.id} className="flex justify-between items-center p-3 bg-blue-50 rounded-lg">
                                <div>
                                    <p className="font-medium text-sm">{notification.title}</p>
                                    <p className="text-xs text-slate-600">{notification.message}</p>
                                </div>
                                <Button 
                                    size="sm" 
                                    variant="outline" 
                                    onClick={() => markNotificationAsRead(notification.id)}
                                >
                                    Mark Read
                                </Button>
                            </div>
                        ))}
                    </div>
        </div>
      )}

      <div className="flex justify-between items-center">
        <h2 className="text-3xl font-bold text-slate-900">Company Profile</h2>
        {canEdit && !isEditing && (
          <button 
            onClick={handleEdit} 
            className="bg-blue-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-700 transition-colors flex items-center gap-2 shadow-md hover:shadow-lg"
          >
            <Edit3 size={18} /> Edit Profile
          </button>
        )}
      </div>

      <fieldset disabled={!isEditing || !canEdit} className="space-y-8">
        {/* Primary Details & Service Providers Card */}
        <div className="bg-white rounded-xl shadow-xl border border-slate-200 p-8 hover:shadow-2xl transition-shadow duration-300">
          <div className="space-y-8">
            {/* Primary Details Section */}
            <div className="space-y-6">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                  <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-slate-900">Primary Details</h3>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <FormSelect 
                                label="Country of Registration" 
                  name="countryOfRegistration" 
                  value={formData.country} 
                  onChange={handlePrimaryChange} 
                  disabled={!isEditing}
                            >
                                {allCountries.map(c => <option key={c} value={c}>{c}</option>)}
                </FormSelect>
                <FormSelect 
                                label="Company Type" 
                  name="companyType" 
                  value={formData.companyType} 
                  onChange={handlePrimaryChange} 
                  disabled={!isEditing}
                            >
                                {companyTypesByCountry.map(type => <option key={type} value={type}>{type}</option>)}
                </FormSelect>
                <FormInput 
                                label="Date of Registration" 
                  name="registrationDate" 
                                type="date" 
                  value={formData.registrationDate} 
                  onChange={handlePrimaryChange} 
                  disabled={!isEditing}
                            />
                    </div>
            </div>

            {/* Divider */}
            <div className="border-t border-slate-200"></div>

            {/* Service Providers Section */}
            <div className="space-y-6">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                  <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-slate-900">Service Providers</h3>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                    <UserCheck size={16}/> Chartered Accountant
                  </label>
                  {formData.ca ? (
                    <ServiceProviderDisplay 
                      provider={formData.ca} 
                      onRemove={() => setFormData(prev => ({...prev, ca: undefined}))} 
                      isEditing={isEditing}
                      type="ca"
                    />
                  ) : (
                    <ServiceCodeInput 
                      name="caCode" 
                      placeholder="Enter CA-Code" 
                      value={formData.caServiceCode || formData.caCode || ''}
                      onChange={handleServiceCodeChange} 
                      disabled={!isEditing}
                      isValid={caCodeValidation.isValid}
                      isInvalid={caCodeValidation.isInvalid}
                      isLoading={caCodeValidation.isLoading}
                      errorMessage={caCodeValidation.errorMessage}
                    />
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                    <ShieldCheck size={16}/> Company Secretary
                  </label>
                  {formData.cs ? (
                    <ServiceProviderDisplay 
                      provider={formData.cs} 
                      onRemove={() => setFormData(prev => ({...prev, cs: undefined}))} 
                      isEditing={isEditing}
                      type="cs"
                    />
                  ) : (
                    <ServiceCodeInput 
                      name="csCode" 
                      placeholder="Enter CS-Code" 
                      value={formData.csServiceCode || formData.csCode || ''}
                      onChange={handleServiceCodeChange} 
                      disabled={!isEditing || csRequestLoading}
                      isValid={csCodeValidation.isValid}
                      isInvalid={csCodeValidation.isInvalid}
                      isLoading={csCodeValidation.isLoading || csRequestLoading}
                      errorMessage={csCodeValidation.errorMessage}
                    />
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Subsidiaries Card */}
        <div className="bg-white rounded-xl shadow-xl border border-slate-200 p-8 hover:shadow-2xl transition-shadow duration-300">
          <div className="space-y-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-slate-900">Subsidiaries</h3>
            </div>
            <div className="max-w-xs">
              <FormSelect 
                label="Number of Subsidiaries" 
                value={formData.subsidiaries.length} 
                onChange={handleSubsidiaryCountChange} 
                disabled={!isEditing}
              >
                <option value={0}>0</option>
                <option value={1}>1</option>
                <option value={2}>2</option>
                <option value={3}>3</option>
              </FormSelect>
            </div>
            {formData.subsidiaries.length === 0 ? (
              <div className="bg-blue-50 p-6 border border-blue-200 rounded-xl text-center">
                <p className="text-blue-700 font-medium">No subsidiaries added</p>
                <p className="text-blue-600 text-sm mt-1">Add subsidiaries to manage their compliance requirements</p>
              </div>
            ) : (
              formData.subsidiaries.map((sub, index) => (
                <div key={sub.id} className="bg-gradient-to-r from-blue-50 to-indigo-50 p-6 border border-blue-200 rounded-xl space-y-6 shadow-md">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <h4 className="md:col-span-3 text-lg font-bold text-blue-900 flex items-center gap-2">
                      <div className="w-6 h-6 bg-blue-200 rounded-full flex items-center justify-center text-sm font-bold text-blue-700">
                        {index + 1}
                      </div>
                      Subsidiary {index + 1}
                    </h4>
                    <FormSelect 
                      label="Country" 
                      name="country" 
                      value={sub.country} 
                      onChange={(e) => handleSubsidiaryChange(index, e)} 
                      disabled={!isEditing}
                            >
                                {allCountries.map(c => <option key={c} value={c}>{c}</option>)}
                    </FormSelect>
                    <FormSelect 
                                label="Company Type" 
                      name="companyType" 
                      value={sub.companyType} 
                      onChange={(e) => handleSubsidiaryChange(index, e)} 
                      disabled={!isEditing}
                    >
                      {profileService.getCompanyTypesByCountry(sub.country).map(type => <option key={type} value={type}>{type}</option>)}
                    </FormSelect>
                    <FormInput 
                                label="Registration Date" 
                      name="registrationDate" 
                                type="date" 
                      value={sub.registrationDate} 
                      onChange={(e) => handleSubsidiaryChange(index, e)} 
                      disabled={!isEditing} 
                    />
                                </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6 border-t border-blue-200">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                        <UserCheck size={16}/> Chartered Accountant
                      </label>
                      {sub.ca ? (
                        <ServiceProviderDisplay 
                          provider={sub.ca} 
                          onRemove={() => handleRemoveSubsidiaryProvider(index, 'ca')} 
                          isEditing={isEditing}
                          type="ca"
                        />
                      ) : (
                        <ServiceCodeInput 
                          name="caCode" 
                          placeholder="Enter CA-Code" 
                          value={sub.caCode || ''}
                          onChange={(e) => handleSubsidiaryServiceCodeChange(index, e)} 
                          disabled={!isEditing}
                          isValid={subsidiaryCodeValidation[index]?.ca?.isValid || false}
                          isInvalid={subsidiaryCodeValidation[index]?.ca?.isInvalid || false}
                          isLoading={subsidiaryCodeValidation[index]?.ca?.isLoading || false}
                          errorMessage={subsidiaryCodeValidation[index]?.ca?.errorMessage || ''}
                        />
                      )}
                            </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                        <ShieldCheck size={16}/> Company Secretary
                      </label>
                      {sub.cs ? (
                        <ServiceProviderDisplay 
                          provider={sub.cs} 
                          onRemove={() => handleRemoveSubsidiaryProvider(index, 'cs')} 
                          isEditing={isEditing}
                          type="cs"
                        />
                      ) : (
                        <ServiceCodeInput 
                          name="csCode" 
                          placeholder="Enter CS-Code" 
                          value={sub.csCode || ''}
                          onChange={(e) => handleSubsidiaryServiceCodeChange(index, e)} 
                          disabled={!isEditing}
                          isValid={subsidiaryCodeValidation[index]?.cs?.isValid || false}
                          isInvalid={subsidiaryCodeValidation[index]?.cs?.isInvalid || false}
                          isLoading={subsidiaryCodeValidation[index]?.cs?.isLoading || false}
                          errorMessage={subsidiaryCodeValidation[index]?.cs?.errorMessage || ''}
                        />
                      )}
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* International Operations Card */}
        <div className="bg-white rounded-xl shadow-xl border border-slate-200 p-8 hover:shadow-2xl transition-shadow duration-300">
          <div className="space-y-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-slate-900">International Operations</h3>
            </div>
            <p className="text-sm text-slate-600 bg-blue-50 p-3 rounded-lg border border-blue-200">
              Define countries where you do business without a subsidiary.
            </p>
            <div className="max-w-xs">
              <FormSelect 
                label="Number of International Operations" 
                value={formData.internationalOps.length} 
                onChange={handleIntlOpsCountChange} 
                disabled={!isEditing}
              >
                {[0, 1, 2, 3, 4, 5].map(i => <option key={i} value={i}>{i}</option>)}
              </FormSelect>
            </div>
            {formData.internationalOps.length === 0 ? (
              <div className="bg-blue-50 p-6 border border-blue-200 rounded-xl text-center">
                <p className="text-blue-700 font-medium">No international operations added</p>
                <p className="text-blue-600 text-sm mt-1">Add countries where you do business without subsidiaries</p>
              </div>
            ) : (
              formData.internationalOps.map((op, index) => (
                <div key={op.id} className="bg-gradient-to-r from-blue-50 to-indigo-50 p-6 border border-blue-200 rounded-xl shadow-md">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <h4 className="md:col-span-3 text-lg font-bold text-blue-900 flex items-center gap-2">
                      <div className="w-6 h-6 bg-blue-200 rounded-full flex items-center justify-center text-sm font-bold text-blue-700">
                        {index + 1}
                      </div>
                      Operation {index + 1}
                    </h4>
                    <div className="md:col-span-1">
                      <FormSelect 
                        label="Country" 
                        name="country" 
                        value={op.country} 
                        onChange={(e) => handleIntlOpChange(index, e)} 
                        disabled={!isEditing}
                            >
                                    {allCountries.map(c => <option key={c} value={c}>{c}</option>)}
                      </FormSelect>
                    </div>
                    <div className="md:col-span-1">
                      <FormInput 
                        label="Start Date" 
                        name="startDate" 
                        type="date" 
                        value={op.startDate} 
                        onChange={(e) => handleIntlOpChange(index, e)} 
                        disabled={!isEditing} 
                    />
                    </div>
                  </div>
                </div>
              ))
                )}
            </div>
        </div>
      </fieldset>

      {isEditing && (
        <div className="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
          <div className="flex flex-wrap justify-end items-center gap-4">
            <button 
              onClick={handleCancel} 
              className="bg-slate-100 text-slate-700 px-6 py-3 rounded-lg font-semibold hover:bg-slate-200 transition-colors flex items-center gap-2"
            >
              <X size={18} /> Cancel
            </button>
            <button 
              onClick={handleSave} 
              className="bg-blue-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-700 transition-colors flex items-center gap-2 shadow-md hover:shadow-lg"
            >
              <Save size={18} /> Save Changes
            </button>
          </div>
        </div>
      )}
        </div>
    );
};

export default ProfileTab;