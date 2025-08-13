# 🚀 Dynamic Profile Section Implementation Guide

## 📋 Overview

This guide will help you implement a fully dynamic profile section for the startup dashboard with real-time updates. The implementation includes database tables, functions, frontend services, and real-time subscriptions.

## 🗂️ Files Created

1. **`PROFILE_SECTION_DYNAMIC_TABLES.sql`** - Database tables and functions
2. **`lib/profileService.ts`** - Frontend service layer
3. **`DYNAMIC_PROFILE_IMPLEMENTATION_GUIDE.md`** - This guide

## 🛠️ Implementation Steps

### Step 1: Set Up Database Backend

1. **Run the SQL script in Supabase:**
   ```sql
   -- Copy and paste the entire content of PROFILE_SECTION_DYNAMIC_TABLES.sql
   -- into your Supabase SQL Editor and execute it
   ```

2. **Verify the functions were created:**
   ```sql
   -- Test the functions
   SELECT * FROM get_startup_profile(1);
   SELECT * FROM update_startup_profile(1, 'USA', 'C-Corporation', 'CA-123', 'CS-456');
   SELECT * FROM add_subsidiary(1, 'UK', 'Limited Company (Ltd)', '2023-06-01');
   ```

### Step 2: Update ProfileTab Component

Now we need to update the ProfileTab component to use real data instead of mock data:

```typescript
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
  
  // Real profile data from database
  const [profile, setProfile] = useState({
    country: 'USA',
    companyType: 'C-Corporation',
    registrationDate: startup.registrationDate,
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
          setProfile(profileData);
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

  // Real-time subscriptions
  useEffect(() => {
    const subscription = profileService.subscribeToProfileChanges(startup.id, (payload) => {
      console.log('Profile change detected:', payload);
      
      // Refresh profile data
      profileService.getStartupProfile(startup.id).then(profileData => {
        if (profileData) {
          setProfile(profileData);
        }
      });
      
      // Refresh notifications
      profileService.getProfileNotifications(startup.id).then(notifications => {
        setNotifications(notifications);
      });
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [startup.id]);

  // Get dynamic data
  const companyTypesByCountry = profileService.getCompanyTypesByCountry(profile.country, startup.sector);
  const allCountries = profileService.getAllCountries();

  const handleSubsidiaryChange = (index: number, field: keyof Subsidiary, value: any) => {
    const newSubsidiaries = [...profile.subsidiaries];
    (newSubsidiaries[index] as any)[field] = value;
    setProfile(p => ({ ...p, subsidiaries: newSubsidiaries }));
  };

  const addSubsidiary = async () => {
    if (profile.subsidiaries.length < 3) {
      const newSubsidiary: Omit<Subsidiary, 'id'> = { 
        country: 'USA', 
        companyType: 'LLC', 
        registrationDate: new Date().toISOString().split('T')[0] 
      };
      
      const subsidiaryId = await profileService.addSubsidiary(startup.id, newSubsidiary);
      if (subsidiaryId) {
        // The real-time subscription will update the UI
        console.log('Subsidiary added successfully');
      }
    }
  };
  
  const removeSubsidiary = async (id: number) => {
    const success = await profileService.deleteSubsidiary(id);
    if (success) {
      console.log('Subsidiary removed successfully');
    }
  };
  
  const handleIntlOpChange = (index: number, field: keyof InternationalOp, value: string) => {
    const newOps = [...profile.internationalOps];
    (newOps[index] as any)[field] = value;
    setProfile(p => ({...p, internationalOps: newOps}));
  };

  const addIntlOp = async () => {
    const newOp: Omit<InternationalOp, 'id'> = { 
      country: 'Germany', 
      startDate: new Date().toISOString().split('T')[0] 
    };
    
    const opId = await profileService.addInternationalOp(startup.id, newOp);
    if (opId) {
      console.log('International operation added successfully');
    }
  };

  const removeIntlOp = async (index: number) => {
    const op = profile.internationalOps[index];
    if (op.id) {
      const success = await profileService.deleteInternationalOp(op.id);
      if (success) {
        console.log('International operation removed successfully');
      }
    }
  };

  const handleSave = async () => {
    try {
      const validation = profileService.validateProfileData(profile);
      if (!validation.isValid) {
        alert('Validation errors: ' + validation.errors.join(', '));
        return;
      }

      const success = await profileService.updateStartupProfile(startup.id, profile);
      if (success) {
        setIsEditing(false);
        console.log('Profile updated successfully');
      } else {
        alert('Failed to update profile');
      }
    } catch (error) {
      console.error('Error saving profile:', error);
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

      {/* Primary Details */}
      <Card>
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold text-slate-700">Primary Details</h3>
        </div>
        <fieldset disabled={!isEditing}>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Select 
              label="Country of Registration" 
              id="country" 
              value={profile.country} 
              onChange={e => setProfile({...profile, country: e.target.value})}
            >
              {allCountries.map(c => <option key={c} value={c}>{c}</option>)}
            </Select>
            <Select 
              label="Company Type" 
              id="companyType" 
              value={profile.companyType} 
              onChange={e => setProfile({...profile, companyType: e.target.value})}
            >
              {companyTypesByCountry.map(type => <option key={type} value={type}>{type}</option>)}
            </Select>
            <Input 
              label="Date of Registration" 
              id="regDate" 
              type="date" 
              value={profile.registrationDate} 
              onChange={e => setProfile({...profile, registrationDate: e.target.value})} 
            />
          </div>
        </fieldset>
      </Card>

      {/* Subsidiaries */}
      <Card>
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold text-slate-700">Subsidiaries</h3>
          {isEditing && (
            <Button 
              size="sm" 
              variant="outline" 
              onClick={addSubsidiary} 
              disabled={profile.subsidiaries.length >= 3}
            >
              <Plus className="h-4 w-4 mr-2" />Add Subsidiary
            </Button>
          )}
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
                  value={sub.country} 
                  onChange={e => handleSubsidiaryChange(index, 'country', e.target.value)}
                >
                  {allCountries.map(c => <option key={c} value={c}>{c}</option>)}
                </Select>
                <Select 
                  label="Company Type" 
                  id={`sub-type-${index}`} 
                  value={sub.companyType} 
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
                  value={sub.registrationDate} 
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

      {/* International Operations */}
      <Card>
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold text-slate-700">International Operations</h3>
          {isEditing && (
            <Button size="sm" variant="outline" onClick={addIntlOp}>
              <Plus className="h-4 w-4 mr-2" />Add Operation
            </Button>
          )}
        </div>
        <p className="text-sm text-slate-500 mb-4">
          Select countries where you do business without a subsidiary and specify the start date.
        </p>
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
                  value={op.country} 
                  onChange={e => handleIntlOpChange(index, 'country', e.target.value)}
                >
                  {allCountries.map(c => <option key={c} value={c}>{c}</option>)}
                </Select>
                <Input 
                  label="Operations Start Date" 
                  id={`op-date-${index}`} 
                  containerClassName="col-span-3" 
                  type="date" 
                  value={op.startDate} 
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
      
      {/* Service Providers */}
      <Card>
        <h3 className="text-lg font-semibold text-slate-700 mb-4">Service Providers</h3>
        <fieldset disabled={!isEditing}>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input 
              label="CA Service Code" 
              id="ca-code" 
              value={profile.caServiceCode} 
              onChange={e => setProfile({...profile, caServiceCode: e.target.value})} 
            />
            <Input 
              label="CS Service Code" 
              id="cs-code" 
              value={profile.csServiceCode} 
              onChange={e => setProfile({...profile, csServiceCode: e.target.value})} 
            />
          </div>
        </fieldset>
      </Card>

      {/* Action Buttons */}
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
```

### Step 3: Update Types (if needed)

Make sure your `types.ts` file includes the `ProfileData` interface:

```typescript
export interface ProfileData {
  country: string;
  companyType: string;
  registrationDate: string;
  subsidiaries: Subsidiary[];
  internationalOps: InternationalOp[];
  caServiceCode?: string;
  csServiceCode?: string;
}
```

## 🎯 Key Features Implemented

### ✅ Real-time Updates
- Live updates when profile data changes
- Real-time notifications for profile activities
- Automatic UI refreshes

### ✅ Database Operations
- Complete CRUD operations for profile data
- Audit logging for all changes
- Proper validation and error handling

### ✅ Security
- Row-level security policies
- User-specific data access
- Proper authentication checks

### ✅ Notifications
- Real-time notifications for profile changes
- Mark as read functionality
- Notification history

### ✅ Audit Trail
- Complete audit log of all profile changes
- Old and new values tracking
- Timestamp tracking

## 🚀 Real-time Features

### Profile Changes Subscription
The system automatically subscribes to profile changes and updates the UI in real-time:

```typescript
useEffect(() => {
  const subscription = profileService.subscribeToProfileChanges(startup.id, (payload) => {
    console.log('Profile change detected:', payload);
    // Refresh data automatically
  });

  return () => subscription.unsubscribe();
}, [startup.id]);
```

### Notification System
Real-time notifications are created for:
- Profile updates
- Subsidiary additions/updates/deletions
- International operation changes

## 🔧 Database Functions

### Core Functions
- `get_startup_profile(startup_id)` - Get complete profile data
- `update_startup_profile(startup_id, country, company_type, ca_code, cs_code)` - Update profile
- `add_subsidiary(startup_id, country, company_type, registration_date)` - Add subsidiary
- `add_international_op(startup_id, country, start_date)` - Add international operation

### Audit Functions
- Automatic audit logging for all changes
- Old and new values tracking
- User action tracking

## 📊 Tables Created

1. **Enhanced `startups` table** - Added profile-specific columns
2. **`profile_audit_log`** - Audit trail for all changes
3. **`profile_notifications`** - Real-time notifications
4. **`profile_templates`** - Predefined profile templates

## 🔧 Troubleshooting

### Common Issues:

1. **"Function not found" error:**
   - Make sure you ran the SQL script in Supabase
   - Check that the function names match exactly

2. **"Permission denied" error:**
   - Verify RLS policies are enabled
   - Check that user_id is properly set in startups table

3. **Real-time not working:**
   - Ensure real-time is enabled in Supabase
   - Check that the subscription is properly set up

4. **Profile data not loading:**
   - Check if there's data in the database
   - Verify the startup_id is correct
   - Check browser console for errors

## 📞 Support

If you encounter any issues:
1. Check the browser console for error messages
2. Verify the database functions exist in Supabase
3. Ensure all tables have proper RLS policies
4. Check that real-time is enabled in your Supabase project

## 🎉 Next Steps

1. **Test the implementation** with real data
2. **Add more validation rules** as needed
3. **Implement profile templates** for quick setup
4. **Add export functionality** for profile data
5. **Implement advanced filtering** and search
