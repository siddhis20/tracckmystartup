import React, { useState, useEffect } from 'react';
import { Startup, Subsidiary, InternationalOp } from '../../types';
import { profileService, ProfileNotification } from '../../lib/profileService';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import { Plus, Trash2, Edit3, Save, X, Bell } from 'lucide-react';

interface ProfileTabProps {
  startup: Startup;
  userRole?: string;
}



const ProfileTab: React.FC<ProfileTabProps> = ({ startup, userRole }) => {
    const [isEditing, setIsEditing] = useState(false);
    const [isLoading, setIsLoading] = useState(true);
    const [notifications, setNotifications] = useState<ProfileNotification[]>([]);
    const canEdit = userRole === 'Startup';
    
    // Helper function to sanitize profile data and ensure all values are strings
    const sanitizeProfileData = (data: any) => ({
        country: data.country || 'USA',
        companyType: data.companyType || 'C-Corporation',
        registrationDate: data.registrationDate || '',
        subsidiaries: (data.subsidiaries || []).map((sub: any) => ({
            id: sub.id || 0,
            country: sub.country || 'USA',
            companyType: sub.companyType || 'LLC',
            registrationDate: sub.registrationDate || '' // Don't use mock date, use empty string
        })),
        internationalOps: (data.internationalOps || []).map((op: any) => ({
            id: op.id || 0,
            country: op.country || 'Germany',
            startDate: op.startDate || '' // Don't use mock date, use empty string
        })),
        caServiceCode: data.caServiceCode || '',
        csServiceCode: data.csServiceCode || '',
    });
    
    // Real profile data from database
    const [profile, setProfile] = useState({
        country: 'USA',
        companyType: 'C-Corporation',
        registrationDate: startup.registrationDate || new Date().toISOString().split('T')[0],
        subsidiaries: [] as Subsidiary[],
        internationalOps: [] as InternationalOp[],
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
                    setProfile(sanitizedData);
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
                            setProfile(sanitizeProfileData(profileData));
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
                            setProfile(sanitizeProfileData(profileData));
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
                            setProfile(sanitizeProfileData(profileData));
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
    const companyTypesByCountry = profileService.getCompanyTypesByCountry(profile.country, startup.sector);
    const allCountries = profileService.getAllCountries();

    const handleSubsidiaryChange = async (index: number, field: keyof Subsidiary, value: any) => {
        const newSubsidiaries = [...profile.subsidiaries];
        // Ensure the subsidiary object exists and has all required fields
        if (!newSubsidiaries[index]) {
            newSubsidiaries[index] = {
                id: 0,
                country: 'USA',
                companyType: 'LLC',
                registrationDate: new Date().toISOString().split('T')[0]
            };
        }
        
        const subsidiary = newSubsidiaries[index];
        (subsidiary as any)[field] = value || '';
        
        // Update local state immediately for UI responsiveness
        setProfile(p => ({ ...p, subsidiaries: newSubsidiaries }));
        
        // Save to database if subsidiary has an ID (exists in database)
        if (subsidiary.id && subsidiary.id > 0) {
            console.log('🔍 Updating subsidiary in database:', { 
                id: subsidiary.id, 
                field, 
                value,
                fullSubsidiary: subsidiary 
            });
            try {
                const updateData = {
                    country: subsidiary.country,
                    companyType: subsidiary.companyType,
                    registrationDate: subsidiary.registrationDate
                };
                console.log('🔍 Sending update data to database:', updateData);
                console.log('🔍 Registration date type:', typeof subsidiary.registrationDate);
                console.log('🔍 Registration date value:', subsidiary.registrationDate);
                console.log('🔍 Registration date as Date object:', new Date(subsidiary.registrationDate));
                console.log('🔍 Registration date ISO string:', new Date(subsidiary.registrationDate).toISOString());
                
                const success = await profileService.updateSubsidiary(subsidiary.id, updateData);
                
                if (success) {
                    console.log('✅ Subsidiary updated successfully in database');
                    // Longer delay to ensure database update is committed
                    await new Promise(resolve => setTimeout(resolve, 500));
                    // Force refresh the data to confirm the update
                    console.log('🔍 Forcing refresh of profile data...');
                    const updatedProfile = await profileService.getStartupProfile(startup.id);
                    console.log('🔍 Refreshed profile after update:', updatedProfile);
                    if (updatedProfile) {
                        // Update the state with fresh data from database
                        setProfile(sanitizeProfileData(updatedProfile));
                        console.log('✅ Frontend state updated with fresh database data');
                        console.log('🔍 Subsidiaries in updated profile:', updatedProfile.subsidiaries);
                    } else {
                        console.error('❌ Failed to get updated profile data');
                    }
                } else {
                    console.error('❌ Failed to update subsidiary in database');
                }
            } catch (error) {
                console.error('❌ Error updating subsidiary:', error);
            }
        } else {
            console.log('⚠️ Subsidiary has no ID, skipping database update:', subsidiary);
        }
    };

    const addSubsidiary = async () => {
        if (profile.subsidiaries.length < 3) {
            const newSubsidiary: Omit<Subsidiary, 'id'> = { 
                country: 'USA', 
                companyType: 'LLC', 
                registrationDate: new Date().toISOString().split('T')[0] 
            };
            
            console.log('🔍 Adding subsidiary:', newSubsidiary);
            const subsidiaryId = await profileService.addSubsidiary(startup.id, newSubsidiary);
            console.log('🔍 Subsidiary add result:', subsidiaryId);
            
            if (subsidiaryId) {
                console.log('Subsidiary added successfully');
                // Manually refresh to ensure UI updates
                const updatedProfile = await profileService.getStartupProfile(startup.id);
                console.log('🔍 Updated profile after adding subsidiary:', updatedProfile);
                if (updatedProfile) {
                    setProfile(sanitizeProfileData(updatedProfile));
                }
            } else {
                console.error('❌ Failed to add subsidiary');
            }
        }
    };
    
    const removeSubsidiary = async (id: number) => {
        console.log('🔍 Removing subsidiary with ID:', id);
        const success = await profileService.deleteSubsidiary(id);
        console.log('🔍 Subsidiary delete result:', success);
        
        if (success) {
            console.log('Subsidiary removed successfully');
            // Manually refresh to ensure UI updates
            const updatedProfile = await profileService.getStartupProfile(startup.id);
            console.log('🔍 Updated profile after removing subsidiary:', updatedProfile);
            if (updatedProfile) {
                setProfile(sanitizeProfileData(updatedProfile));
            }
        } else {
            console.error('❌ Failed to remove subsidiary');
        }
    };
    
    const handleIntlOpChange = async (index: number, field: keyof InternationalOp, value: string) => {
        const newOps = [...profile.internationalOps];
        // Ensure the international operation object exists and has all required fields
        if (!newOps[index]) {
            newOps[index] = {
                id: 0,
                country: 'Germany',
                startDate: new Date().toISOString().split('T')[0]
            };
        }
        
        const operation = newOps[index];
        (operation as any)[field] = value || '';
        
        // Update local state immediately for UI responsiveness
        setProfile(p => ({...p, internationalOps: newOps}));
        
        // Save to database if operation has an ID (exists in database)
        if (operation.id && operation.id > 0) {
            console.log('🔍 Updating international operation in database:', { id: operation.id, field, value });
            try {
                const success = await profileService.updateInternationalOp(operation.id, {
                    country: operation.country,
                    startDate: operation.startDate
                });
                
                if (success) {
                    console.log('✅ International operation updated successfully in database');
                    // Small delay to ensure database update is committed
                    await new Promise(resolve => setTimeout(resolve, 100));
                    // Refresh the data to confirm the update
                    const updatedProfile = await profileService.getStartupProfile(startup.id);
                    console.log('🔍 Refreshed profile after international operation update:', updatedProfile);
                    if (updatedProfile) {
                        // Update the state with fresh data from database
                        setProfile(sanitizeProfileData(updatedProfile));
                        console.log('✅ Frontend state updated with fresh database data');
                    }
                } else {
                    console.error('❌ Failed to update international operation in database');
                }
            } catch (error) {
                console.error('❌ Error updating international operation:', error);
            }
        }
    };

    const addIntlOp = async () => {
        const newOp: Omit<InternationalOp, 'id'> = { 
            country: 'Germany', 
            startDate: new Date().toISOString().split('T')[0] 
        };
        
        const opId = await profileService.addInternationalOp(startup.id, newOp);
        if (opId) {
            console.log('International operation added successfully');
            // Manually refresh to ensure UI updates
            const updatedProfile = await profileService.getStartupProfile(startup.id);
            if (updatedProfile) {
                // Ensure all values are properly initialized to prevent controlled/uncontrolled input issues
                setProfile({
                    country: updatedProfile.country || 'USA',
                    companyType: updatedProfile.companyType || 'C-Corporation',
                    registrationDate: updatedProfile.registrationDate || new Date().toISOString().split('T')[0],
                    subsidiaries: updatedProfile.subsidiaries || [],
                    internationalOps: updatedProfile.internationalOps || [],
                    caServiceCode: updatedProfile.caServiceCode || '',
                    csServiceCode: updatedProfile.csServiceCode || '',
                });
            }
        }
    };

    const removeIntlOp = async (index: number) => {
        const op = profile.internationalOps[index];
        if (op.id) {
            const success = await profileService.deleteInternationalOp(op.id);
            if (success) {
                console.log('International operation removed successfully');
                // Manually refresh to ensure UI updates
                const updatedProfile = await profileService.getStartupProfile(startup.id);
                if (updatedProfile) {
                    setProfile(sanitizeProfileData(updatedProfile));
                }
            }
        }
    };


    const handleSave = async () => {
        try {
            console.log('🔍 Starting save process...');
            console.log('🔍 Profile data to save:', profile);
            
            const validation = profileService.validateProfileData(profile);
            if (!validation.isValid) {
                alert('Validation errors: ' + validation.errors.join(', '));
                return;
            }

            console.log('🔍 Calling updateStartupProfile...');
            const success = await profileService.updateStartupProfile(startup.id, profile);
            console.log('🔍 Update result:', success);
            
            if (success) {
        setIsEditing(false);
                console.log('Profile updated successfully');
                
                // Manually refresh the profile data to ensure UI updates
                console.log('🔍 Refreshing profile data...');
                const updatedProfile = await profileService.getStartupProfile(startup.id);
                console.log('🔍 Refreshed profile data:', updatedProfile);
                if (updatedProfile) {
                    setProfile(sanitizeProfileData(updatedProfile));
                }
            } else {
                console.error('❌ Failed to update profile - success was false');
                alert('Failed to update profile');
            }
        } catch (error) {
            console.error('❌ Error saving profile:', error);
            alert('Error saving profile');
        }
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
        <div className="space-y-6">
            {/* Notifications */}
            {notifications.filter(n => !n.is_read).length > 0 && (
                <Card>
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
                </Card>
            )}

            <Card>
                <div className="flex justify-between items-center mb-4">
                    <h3 className="text-lg font-semibold text-slate-700">Primary Details</h3>
                </div>
                <fieldset disabled={!isEditing}>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <Select 
                                label="Country of Registration" 
                                id="country" 
                                value={profile.country || ''} 
                                onChange={e => setProfile({...profile, country: e.target.value})}
                            >
                                {allCountries.map(c => <option key={c} value={c}>{c}</option>)}
                        </Select>
                            <Select 
                                label="Company Type" 
                                id="companyType" 
                                value={profile.companyType || ''} 
                                onChange={e => setProfile({...profile, companyType: e.target.value})}
                            >
                                {companyTypesByCountry.map(type => <option key={type} value={type}>{type}</option>)}
                        </Select>
                            <Input 
                                label="Date of Registration" 
                                id="regDate" 
                                type="date" 
                                value={profile.registrationDate || ''} 
                                onChange={e => setProfile({...profile, registrationDate: e.target.value})} 
                            />
                    </div>
                </fieldset>
            </Card>

            <Card>
                <div className="flex justify-between items-center mb-4">
                    <h3 className="text-lg font-semibold text-slate-700">Subsidiaries</h3>
                    {isEditing && <Button size="sm" variant="outline" onClick={addSubsidiary} disabled={profile.subsidiaries.length >= 3}><Plus className="h-4 w-4 mr-2" />Add Subsidiary</Button>}
                </div>
                <fieldset disabled={!isEditing}>
                    <div className="space-y-4">
                    {profile.subsidiaries.length === 0 && !isEditing && (
                        <p className="text-slate-500 text-sm">No subsidiaries added.</p>
                    )}
                        {profile.subsidiaries.map((sub, index) => (
                            <div key={sub.id} className="grid grid-cols-1 md:grid-cols-4 gap-4 p-4 border rounded-lg">
                            <Select 
                                label={`Subsidiary ${index + 1} Country`} 
                                id={`sub-country-${index}`} 
                                value={sub.country || ''} 
                                onChange={e => handleSubsidiaryChange(index, 'country', e.target.value)}
                            >
                                {allCountries.map(c => <option key={c} value={c}>{c}</option>)}
                                </Select>
                            <Select 
                                label="Company Type" 
                                id={`sub-type-${index}`} 
                                value={sub.companyType || ''} 
                                onChange={e => handleSubsidiaryChange(index, 'companyType', e.target.value)}
                            >
                                {profileService.getCompanyTypesByCountry(sub.country).map(type => (
                                    <option key={type} value={type}>{type}</option>
                                ))}
                                </Select>
                            <Input 
                                label="Registration Date" 
                                id={`sub-date-${index}`} 
                                type="date" 
                                value={sub.registrationDate || ''} 
                                onChange={e => handleSubsidiaryChange(index, 'registrationDate', e.target.value)} 
                            />
                            {isEditing && (
                                <div className="flex items-end">
                                    <Button 
                                        variant="secondary" 
                                        size="sm" 
                                        onClick={() => removeSubsidiary(sub.id)}
                                    >
                                        <Trash2 className="h-4 w-4"/>
                                    </Button>
                                </div>
                            )}
                            </div>
                        ))}
                    </div>
                </fieldset>
            </Card>

            <Card>
                <div className="flex justify-between items-center mb-4">
                    <h3 className="text-lg font-semibold text-slate-700">International Operations</h3>
                    {isEditing && <Button size="sm" variant="outline" onClick={addIntlOp}><Plus className="h-4 w-4 mr-2" />Add Operation</Button>}
                </div>
                <p className="text-sm text-slate-500 mb-4">Select countries where you do business without a subsidiary and specify the start date.</p>
                <fieldset disabled={!isEditing}>
                    <div className="space-y-4">
                    {profile.internationalOps.length === 0 && !isEditing && (
                        <p className="text-slate-500 text-sm">No international operations added.</p>
                    )}
                        {profile.internationalOps.map((op, index) => (
                        <div key={op.id || index} className="grid grid-cols-1 md:grid-cols-7 gap-4 items-end">
                            <Select 
                                label={`Country`} 
                                id={`op-country-${index}`} 
                                containerClassName="col-span-3" 
                                value={op.country || ''} 
                                onChange={e => handleIntlOpChange(index, 'country', e.target.value)}
                            >
                                    {allCountries.map(c => <option key={c} value={c}>{c}</option>)}
                                </Select>
                            <Input 
                                label="Operations Start Date" 
                                id={`op-date-${index}`} 
                                containerClassName="col-span-3" 
                                type="date" 
                                value={op.startDate || ''} 
                                onChange={e => handleIntlOpChange(index, 'startDate', e.target.value)} 
                            />
                            {isEditing && (
                                <Button 
                                    variant="secondary" 
                                    size="sm" 
                                    onClick={() => removeIntlOp(index)}
                                >
                                    <Trash2 className="h-4 w-4"/>
                                </Button>
                            )}
                            </div>
                        ))}
                    </div>
                </fieldset>
            </Card>
            
             <Card>
                <h3 className="text-lg font-semibold text-slate-700 mb-4">Service Providers</h3>
                 <fieldset disabled={!isEditing}>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <Input 
                        label="CA Service Code" 
                        id="ca-code" 
                        value={profile.caServiceCode || ''} 
                        onChange={e => setProfile({...profile, caServiceCode: e.target.value})} 
                    />
                    <Input 
                        label="CS Service Code" 
                        id="cs-code" 
                        value={profile.csServiceCode || ''} 
                        onChange={e => setProfile({...profile, csServiceCode: e.target.value})} 
                    />
                    </div>
                </fieldset>
            </Card>

            <div className="flex justify-end space-x-4">
                {isEditing ? (
                    <>
                        <Button variant="secondary" onClick={() => setIsEditing(false)}>Cancel</Button>
                        <Button onClick={handleSave}>Save Changes</Button>
                    </>
                ) : (
                    <Button onClick={() => setIsEditing(true)} disabled={!canEdit}>Edit Profile</Button>
                )}
            </div>
        </div>
    );
};

export default ProfileTab;