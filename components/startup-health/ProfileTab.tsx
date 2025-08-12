import React, { useState } from 'react';
import { Startup, Subsidiary, InternationalOp } from '../../types';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import { Plus, Trash2, Edit3, Save, X } from 'lucide-react';

interface ProfileTabProps {
  startup: Startup;
  userRole?: string;
}

// Dynamic data generation based on startup
const generateCompanyTypesByCountry = (startup: Startup) => {
  const sector = startup.sector || 'Technology';
  
  // Adjust company types based on startup sector
  if (sector === 'FinTech' || sector === 'HealthTech') {
    return {
      'USA': ['C-Corporation', 'LLC', 'S-Corporation'],
      'UK': ['Limited Company (Ltd)', 'Public Limited Company (PLC)'],
      'India': ['Private Limited Company', 'Public Limited Company', 'LLP'],
      'Singapore': ['Private Limited', 'Exempt Private Company'],
    };
  } else {
    return {
      'USA': ['LLC', 'C-Corporation', 'S-Corporation'],
      'UK': ['Limited Company (Ltd)', 'Public Limited Company (PLC)'],
      'India': ['Private Limited Company', 'Public Limited Company', 'LLP'],
      'Singapore': ['Private Limited', 'Exempt Private Company'],
    };
  }
};

const generateAllCountries = (startup: Startup) => {
  const sector = startup.sector || 'Technology';
  
  // Add more countries for international startups
  if (startup.totalFunding > 5000000) {
    return ['USA', 'UK', 'India', 'Singapore', 'Germany', 'Canada', 'Australia', 'Japan', 'Brazil', 'Mexico'];
  } else {
    return ['USA', 'UK', 'India', 'Singapore', 'Germany', 'Canada', 'Australia'];
  }
};

// Dynamic mock data based on startup
const generateMockSubsidiaries = (startup: Startup): Subsidiary[] => {
  const totalFunding = startup.totalFunding || 1000000;
  
  if (totalFunding < 2000000) {
    return []; // No subsidiaries for small startups
  } else if (totalFunding < 10000000) {
    return [
      { id: 1, country: 'UK', companyType: 'Limited Company (Ltd)', registrationDate: '2023-06-01' }
    ];
  } else {
    return [
      { id: 1, country: 'UK', companyType: 'Limited Company (Ltd)', registrationDate: '2023-06-01' },
      { id: 2, country: 'Singapore', companyType: 'Private Limited', registrationDate: '2023-09-15' }
    ];
  }
};

const generateMockInternationalOps = (startup: Startup): InternationalOp[] => {
  const totalFunding = startup.totalFunding || 1000000;
  
  if (totalFunding < 1000000) {
    return []; // No international ops for very small startups
  } else if (totalFunding < 5000000) {
    return [
      { country: 'Canada', startDate: '2023-01-15' }
    ];
  } else {
    return [
      { country: 'Canada', startDate: '2023-01-15' },
      { country: 'UK', startDate: '2023-06-01' }
    ];
  }
};

const ProfileTab: React.FC<ProfileTabProps> = ({ startup, userRole }) => {
    const [isEditing, setIsEditing] = useState(false);
    const canEdit = userRole === 'Startup';
    
    // Generate dynamic data based on startup
    const companyTypesByCountry = generateCompanyTypesByCountry(startup);
    const allCountries = generateAllCountries(startup);
    const mockSubsidiaries = generateMockSubsidiaries(startup);
    const mockInternationalOps = generateMockInternationalOps(startup);
    
    // Mock initial state, in a real app this would come from the backend
    const [profile, setProfile] = useState({
        country: 'USA',
        companyType: 'C-Corporation',
        registrationDate: startup.registrationDate,
        subsidiaries: mockSubsidiaries,
        internationalOps: mockInternationalOps,
        caServiceCode: 'CA-84321',
        csServiceCode: 'CS-98876',
    });

    const handleSubsidiaryChange = (index: number, field: keyof Subsidiary, value: any) => {
        const newSubsidiaries = [...profile.subsidiaries];
        (newSubsidiaries[index] as any)[field] = value;
        setProfile(p => ({ ...p, subsidiaries: newSubsidiaries }));
    };

    const addSubsidiary = () => {
        if (profile.subsidiaries.length < 3) {
            const newSubsidiary: Subsidiary = { id: Date.now(), country: 'USA', companyType: 'LLC', registrationDate: '' };
            setProfile(p => ({ ...p, subsidiaries: [...p.subsidiaries, newSubsidiary] }));
        }
    };
    
    const removeSubsidiary = (id: number) => {
        setProfile(p => ({ ...p, subsidiaries: p.subsidiaries.filter(s => s.id !== id) }));
    };
    
    const handleIntlOpChange = (index: number, field: keyof InternationalOp, value: string) => {
        const newOps = [...profile.internationalOps];
        (newOps[index] as any)[field] = value;
        setProfile(p => ({...p, internationalOps: newOps}));
    };

    const addIntlOp = () => {
        setProfile(p => ({ ...p, internationalOps: [...p.internationalOps, { country: 'Germany', startDate: new Date().toISOString().split('T')[0] }] }));
    };

    const removeIntlOp = (index: number) => {
        setProfile(p => ({ ...p, internationalOps: p.internationalOps.filter((_, i) => i !== index) }));
    };


    const handleSave = () => {
        console.log('Saving profile:', profile);
        setIsEditing(false);
    };

    return (
        <div className="space-y-6">
            <Card>
                <div className="flex justify-between items-center mb-4">
                    <h3 className="text-lg font-semibold text-slate-700">Primary Details</h3>
                </div>
                <fieldset disabled={!isEditing}>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <Select label="Country of Registration" id="country" value={profile.country} onChange={e => setProfile({...profile, country: e.target.value})}>
                            {Object.keys(companyTypesByCountry).map(c => <option key={c} value={c}>{c}</option>)}
                        </Select>
                        <Select label="Company Type" id="companyType" value={profile.companyType} onChange={e => setProfile({...profile, companyType: e.target.value})}>
                            {(companyTypesByCountry[profile.country] || []).map(type => <option key={type} value={type}>{type}</option>)}
                        </Select>
                        <Input label="Date of Registration" id="regDate" type="date" value={profile.registrationDate} onChange={e => setProfile({...profile, registrationDate: e.target.value})} />
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
                        {profile.subsidiaries.length === 0 && !isEditing && <p className="text-slate-500 text-sm">No subsidiaries added.</p>}
                        {profile.subsidiaries.map((sub, index) => (
                            <div key={sub.id} className="grid grid-cols-1 md:grid-cols-4 gap-4 p-4 border rounded-lg">
                                <Select label={`Subsidiary ${index + 1} Country`} id={`sub-country-${index}`} value={sub.country} onChange={e => handleSubsidiaryChange(index, 'country', e.target.value)}>
                                    {Object.keys(companyTypesByCountry).map(c => <option key={c} value={c}>{c}</option>)}
                                </Select>
                                <Select label="Company Type" id={`sub-type-${index}`} value={sub.companyType} onChange={e => handleSubsidiaryChange(index, 'companyType', e.target.value)}>
                                     {(companyTypesByCountry[sub.country] || []).map(type => <option key={type} value={type}>{type}</option>)}
                                </Select>
                                 <Input label="Registration Date" id={`sub-date-${index}`} type="date" value={sub.registrationDate} onChange={e => handleSubsidiaryChange(index, 'registrationDate', e.target.value)} />
                                 {isEditing && <div className="flex items-end"><Button variant="secondary" size="sm" onClick={() => removeSubsidiary(sub.id)}><Trash2 className="h-4 w-4"/></Button></div>}
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
                         {profile.internationalOps.length === 0 && !isEditing && <p className="text-slate-500 text-sm">No international operations added.</p>}
                        {profile.internationalOps.map((op, index) => (
                            <div key={index} className="grid grid-cols-1 md:grid-cols-7 gap-4 items-end">
                                <Select label={`Country`} id={`op-country-${index}`} containerClassName="col-span-3" value={op.country} onChange={e => handleIntlOpChange(index, 'country', e.target.value)}>
                                    {allCountries.map(c => <option key={c} value={c}>{c}</option>)}
                                </Select>
                                <Input label="Operations Start Date" id={`op-date-${index}`} containerClassName="col-span-3" type="date" value={op.startDate} onChange={e => handleIntlOpChange(index, 'startDate', e.target.value)} />
                                {isEditing && <Button variant="secondary" size="sm" onClick={() => removeIntlOp(index)}><Trash2 className="h-4 w-4"/></Button>}
                            </div>
                        ))}
                    </div>
                </fieldset>
            </Card>
            
             <Card>
                <h3 className="text-lg font-semibold text-slate-700 mb-4">Service Providers</h3>
                 <fieldset disabled={!isEditing}>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <Input label="CA Service Code" id="ca-code" value={profile.caServiceCode} onChange={e => setProfile({...profile, caServiceCode: e.target.value})} />
                        <Input label="CS Service Code" id="cs-code" value={profile.csServiceCode} onChange={e => setProfile({...profile, csServiceCode: e.target.value})} />
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