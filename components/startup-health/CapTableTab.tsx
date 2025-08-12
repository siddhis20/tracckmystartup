import React, { useState } from 'react';
import { Startup, InvestmentRecord, InvestorType, InvestmentRoundType, Founder, FundraisingDetails, UserRole } from '../../types';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import Modal from '../ui/Modal';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { Plus, Trash2, Edit3, Save, X, TrendingUp, Users, DollarSign, PieChart as PieChartIcon } from 'lucide-react';

interface CapTableTabProps {
  startup: Startup;
  userRole?: UserRole;
  onActivateFundraising: (details: FundraisingDetails, startup: Startup) => void;
  onInvestorAdded: (investment: InvestmentRecord, startup: Startup) => void;
  onUpdateFounders: (startupId: number, founders: Founder[]) => void;
}

interface FounderStateItem extends Founder {
  id: number;
}


const formatCurrency = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
const formatCurrencyCompact = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact' }).format(value);


// Dynamic data generation based on startup
const generateValuationData = (startup: Startup) => {
  const currentValuation = startup.currentValuation || 5000000;
  const totalFunding = startup.totalFunding || 1000000;
  
  return [
    { name: 'Seed', valuation: Math.floor(currentValuation * 0.2), investment: Math.floor(totalFunding * 0.5) },
    { name: 'Series A', valuation: Math.floor(currentValuation * 0.6), investment: Math.floor(totalFunding * 0.5) },
    { name: 'Current', valuation: currentValuation, investment: 0 },
  ];
};

// Dynamic mock investors based on startup
const generateMockInvestors = (startup: Startup): InvestmentRecord[] => {
  const totalFunding = startup.totalFunding || 1000000;
  const currentValuation = startup.currentValuation || 5000000;
  
  if (totalFunding < 500000) {
    // Seed stage
    return [
      {
        id: 'inv1',
        date: '2022-01-20',
        investorType: InvestorType.VC,
        investmentType: InvestmentRoundType.Equity,
        investorName: 'SeedFund Ventures',
        amount: Math.floor(totalFunding * 0.5),
        equityAllocated: 10,
        preMoneyValuation: Math.floor(currentValuation * 0.9)
      }
    ];
  } else {
    // Series A stage
    return [
      {
        id: 'inv1',
        date: '2022-01-20',
        investorType: InvestorType.VC,
        investmentType: InvestmentRoundType.Equity,
        investorName: 'SeedFund Ventures',
        amount: Math.floor(totalFunding * 0.25),
        equityAllocated: 5,
        preMoneyValuation: Math.floor(currentValuation * 0.4)
      },
      {
        id: 'inv2',
        date: '2023-06-15',
        investorType: InvestorType.VC,
        investmentType: InvestmentRoundType.Equity,
        investorName: 'Growth Capital',
        amount: Math.floor(totalFunding * 0.75),
        equityAllocated: 15,
        preMoneyValuation: Math.floor(currentValuation * 0.6)
      }
    ];
  }
};

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6', '#60a5fa'];

const CapTableTab: React.FC<CapTableTabProps> = ({ startup, userRole, onActivateFundraising, onInvestorAdded, onUpdateFounders }) => {
    const [isEditing, setIsEditing] = useState(false);
    const [isFundraisingModalOpen, setIsFundraisingModalOpen] = useState(false);
    const [isAddInvestorModalOpen, setIsAddInvestorModalOpen] = useState(false);
    const canEdit = userRole === 'Startup';
    
    // Generate dynamic data based on startup
    const valuationData = generateValuationData(startup);
    const mockInvestors = generateMockInvestors(startup);

    const ESOP_RESERVED_PERCENTAGE = 5; 
    
    const equityData = [
      { name: 'Founders', value: 70 },
      { name: 'Investors', value: 100 - 70 - ESOP_RESERVED_PERCENTAGE },
      { name: 'ESOP', value: ESOP_RESERVED_PERCENTAGE },
    ];
    const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6'];

    const [isEditingFundraising, setIsEditingFundraising] = useState(false);
    const [fundraising, setFundraising] = useState<FundraisingDetails>({
        active: false,
        type: 'SeriesA', // This will need to be dynamic based on startup
        value: 5000000,
        equity: 15,
        validationRequested: false,
        pitchDeckUrl: '',
        pitchVideoUrl: '',
    });
    
    const [isFounderModalOpen, setIsFounderModalOpen] = useState(false);
    const [editingFounders, setEditingFounders] = useState<FounderStateItem[]>([]);

    const handleEditFoundersClick = () => {
        setEditingFounders(startup.founders.map(f => ({ ...f, id: Math.random() * 10000 })));
        setIsFounderModalOpen(true);
    };

    const handleFounderChange = (id: number, field: keyof Omit<FounderStateItem, 'id'>, value: string) => {
        setEditingFounders(editingFounders.map(f => f.id === id ? { ...f, [field]: value } : f));
    };

    const handleAddFounder = () => {
        setEditingFounders([...editingFounders, { id: Date.now(), name: '', email: '' }]);
    };
    
    const handleRemoveFounder = (id: number) => {
        if (editingFounders.length > 1) {
            setEditingFounders(editingFounders.filter(f => f.id !== id));
        }
    };

    const handleFounderSave = () => {
        const finalFounders = editingFounders.map(({ id, ...rest }) => rest);
        onUpdateFounders(startup.id, finalFounders);
        setIsFounderModalOpen(false);
    };


    const handleFundraisingSave = () => {
        onActivateFundraising(fundraising, startup);
        setIsEditingFundraising(false);
    };

    const handleAddInvestment = (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        const formData = new FormData(e.currentTarget);
        const newInvestment: InvestmentRecord = {
            id: `inv-${Date.now()}`,
            date: formData.get('inv-date') as string,
            investorType: formData.get('inv-investor-type') as InvestorType,
            investmentType: formData.get('inv-type') as InvestmentRoundType,
            investorName: formData.get('inv-name') as string,
            investorCode: formData.get('inv-code') as string,
            amount: Number(formData.get('inv-amount')),
            equityAllocated: Number(formData.get('inv-equity')),
            preMoneyValuation: Number(formData.get('inv-premoney')),
        };
        // In a real app, this would be saved to a DB. Here we just add to mock data.
        mockInvestors.push(newInvestment);
        onInvestorAdded(newInvestment, startup);
        e.currentTarget.reset();
    };

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
       <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card><p className="text-sm font-medium text-slate-500">Current Valuation</p><p className="text-2xl font-bold">{formatCurrency(startup.currentValuation)}</p></Card>
        <Card><p className="text-sm font-medium text-slate-500">Total Funding</p><p className="text-2xl font-bold">{formatCurrency(startup.totalFunding)}</p></Card>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card><p className="text-sm font-medium text-slate-500">Founder Investment</p><p className="text-xl font-bold">{formatCurrencyCompact(50000)}</p></Card>
        <Card><p className="text-sm font-medium text-slate-500">Total Equity Funding</p><p className="text-xl font-bold">{formatCurrencyCompact(mockInvestors.reduce((acc, inv) => inv.investmentType === 'Equity' ? acc + inv.amount : acc, 0))}</p></Card>
        <Card><p className="text-sm font-medium text-slate-500">Total Debt Funding</p><p className="text-xl font-bold">{formatCurrencyCompact(0)}</p></Card>
        <Card><p className="text-sm font-medium text-slate-500">Total Grant Funding</p><p className="text-xl font-bold">{formatCurrencyCompact(0)}</p></Card>
      </div>

      {/* Charts & Founder Info */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Valuation History</h3>
                <div style={{ width: '100%', height: 300 }}>
                    <ResponsiveContainer>
                        <BarChart data={valuationData}>
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis dataKey="name" fontSize={12} />
                            <YAxis yAxisId="left" orientation="left" stroke="#16a34a" fontSize={12} tickFormatter={(val) => formatCurrencyCompact(val)}/>
                            <YAxis yAxisId="right" orientation="right" stroke="#3b82f6" fontSize={12} tickFormatter={(val) => formatCurrencyCompact(val)}/>
                            <Tooltip formatter={(value: number) => formatCurrency(value)} />
                            <Legend />
                            <Bar yAxisId="left" dataKey="valuation" fill="#16a34a" name="Valuation" />
                            <Bar yAxisId="right" dataKey="investment" fill="#3b82f6" name="Investment" />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </Card>
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Equity Holdings</h3>
                <div style={{ width: '100%', height: 300 }}>
                    <ResponsiveContainer>
                        <PieChart>
                            <Pie data={equityData} cx="50%" cy="50%" labelLine={false} outerRadius={110} fill="#8884d8" dataKey="value" nameKey="name" label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}>
                                {equityData.map((entry, index) => <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />)}
                            </Pie>
                            <Tooltip formatter={(value: number) => `${value}%`} />
                            <Legend />
                        </PieChart>
                    </ResponsiveContainer>
                </div>
            </Card>
        </div>
        <div className="space-y-6">
            <Card>
                 <div className="flex justify-between items-center mb-4">
                    <h3 className="text-lg font-semibold text-slate-700">Founder Information</h3>
                    <Button variant="outline" size="sm" onClick={handleEditFoundersClick} disabled={!canEdit}><Edit3 className="h-4 w-4 mr-2" />Edit</Button>
                </div>
                <div className="space-y-4">
                    {startup.founders && startup.founders.length > 0 ? (
                        startup.founders.map((founder, index) => (
                            <div key={index}>
                                <p className="font-semibold">{founder.name}</p>
                                <p className="text-sm text-slate-500">{founder.email}</p>
                            </div>
                        ))
                    ) : (
                        <p className="text-sm text-slate-500">No founder information available.</p>
                    )}
                </div>
            </Card>
             <Card>
                <div className="flex justify-between items-center mb-4">
                    <h3 className="text-lg font-semibold text-slate-700">Fundraising</h3>
                    {!isEditingFundraising ? (
                        <Button variant="outline" size="sm" onClick={() => setIsEditingFundraising(true)} disabled={!canEdit}><Edit3 className="h-4 w-4 mr-2" />Edit</Button>
                    ) : (
                         <div className="flex gap-2">
                            <Button variant="secondary" size="sm" onClick={() => setIsEditingFundraising(false)}><X className="h-4 w-4"/></Button>
                            <Button size="sm" onClick={handleFundraisingSave}><Save className="h-4 w-4 mr-2"/>Save</Button>
                        </div>
                    )}
                </div>
                 <fieldset disabled={!isEditingFundraising}>
                    <div className="space-y-4">
                        <Switch label="Activate Fundraising Round" id="fundraising-active" checked={fundraising.active} onChange={(c) => setFundraising({...fundraising, active: c})} />
                        <Select label="Type" id="fr-type" value={fundraising.type} onChange={e => setFundraising({...fundraising, type: e.target.value as NewInvestmentType})}>
                           {Object.values(NewInvestmentType).map(t => <option key={t} value={t}>{t}</option>)}
                        </Select>
                        <Input label="Value" id="fr-value" type="number" value={fundraising.value} onChange={e => setFundraising({...fundraising, value: Number(e.target.value)})} />
                        <Input label="Equity" id="fr-equity" type="number" value={fundraising.equity} onChange={e => setFundraising({...fundraising, equity: Number(e.target.value)})} />
                        <Input label="Pitch Deck" id="fr-deck" type="file" />
                        <Input 
                            label="Pitch Video (YouTube Link)" 
                            id="fr-video" 
                            type="url" 
                            placeholder="https://www.youtube.com/watch?v=..."
                            value={fundraising.pitchVideoUrl || ''}
                            onChange={e => setFundraising({...fundraising, pitchVideoUrl: e.target.value})}
                        />
                        <div className="flex items-center">
                            <input type="checkbox" id="fr-validation" className="h-4 w-4 rounded border-gray-300 text-brand-primary focus:ring-brand-primary" checked={fundraising.validationRequested} onChange={e => setFundraising({...fundraising, validationRequested: e.target.checked})} />
                            <label htmlFor="fr-validation" className="ml-2 block text-sm text-gray-900">Startup Nation Validation Requested</label>
                        </div>
                         {fundraising.validationRequested && (
                            <div className="p-3 bg-blue-50 border-l-4 border-brand-accent text-sm text-slate-600">
                                Startup Nation will charge 3% of fund raised or 4% to total equity raised as fees for validation, documentation and connection.
                            </div>
                        )}
                    </div>
                </fieldset>
            </Card>
        </div>
      </div>
      
      <Modal isOpen={isFounderModalOpen} onClose={() => setIsFounderModalOpen(false)} title="Edit Founder Information">
        <div className="space-y-4 max-h-[60vh] overflow-y-auto pr-2">
            {editingFounders.map((founder, index) => (
                <div key={founder.id} className="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-2 relative border p-4 rounded-lg bg-slate-50/50">
                    <Input 
                        label={`Founder ${index + 1} Name`}
                        id={`founder-name-${founder.id}`}
                        type="text"
                        value={founder.name}
                        onChange={e => handleFounderChange(founder.id, 'name', e.target.value)}
                        required
                    />
                    <Input 
                        label={`Founder ${index + 1} Email`}
                        id={`founder-email-${founder.id}`}
                        type="email"
                        value={founder.email}
                        onChange={e => handleFounderChange(founder.id, 'email', e.target.value)}
                        required
                    />
                    {editingFounders.length > 1 && (
                        <Button 
                            type="button" 
                            onClick={() => handleRemoveFounder(founder.id)}
                            className="absolute top-2 right-2 p-1.5 h-auto bg-transparent hover:bg-red-100 text-slate-400 hover:text-red-500 shadow-none border-none"
                            variant="secondary"
                            size="sm"
                            aria-label="Remove founder"
                        >
                            <Trash2 className="h-4 w-4" />
                        </Button>
                    )}
                </div>
            ))}
             <Button type="button" variant="outline" size="sm" onClick={handleAddFounder}>
                <UserPlus className="h-4 w-4 mr-2" />
                Add Another Founder
            </Button>
        </div>
        <div className="flex justify-end gap-3 pt-6 border-t mt-4">
            <Button type="button" variant="secondary" onClick={() => setIsFounderModalOpen(false)}>Cancel</Button>
            <Button type="button" onClick={handleFounderSave}>Save Changes</Button>
        </div>
      </Modal>


      {/* Add Investment Form */}
      <Card>
        <h3 className="text-lg font-semibold mb-4 text-slate-700">Add New Investment</h3>
        <fieldset disabled={!canEdit}>
            <form onSubmit={handleAddInvestment} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <Input label="Date" name="inv-date" id="inv-date" type="date" required />
                <Select label="Investor Type" name="inv-investor-type" id="inv-investor-type" required>
                    {Object.values(InvestorType).map(t => <option key={t} value={t}>{t}</option>)}
                </Select>
                <Select label="Investment Type" name="inv-type" id="inv-type" required>
                    {Object.values(InvestmentRoundType).map(t => <option key={t} value={t}>{t}</option>)}
                </Select>
                <Input label="Investor Name" name="inv-name" id="inv-name" required />
                <Input label="Investor Code" name="inv-code" id="inv-code" placeholder="e.g., INV-A7B3C9"/>
                <Input label="Investment Amount" name="inv-amount" id="inv-amount" type="number" required/>
                <Input label="Equity Allocated (%)" name="inv-equity" id="inv-equity" type="number" required/>
                <Input label="Pre-Money Valuation" name="inv-premoney" id="inv-premoney" type="number" required/>
                <Input label="Proof of Investment" name="inv-proof" id="inv-proof" type="file" />
                <div className="flex items-end col-span-full">
                    <Button type="submit">Add Investment</Button>
                </div>
            </form>
        </fieldset>
      </Card>

      {/* Investor List */}
      <Card>
        <h3 className="text-lg font-semibold mb-4 text-slate-700">Investor List</h3>
        <div className="overflow-x-auto">
             <table className="min-w-full divide-y divide-slate-200 text-sm">
                <thead className="bg-slate-50">
                    <tr>
                        <th className="px-4 py-2 text-left font-medium text-slate-500">Investor Name</th>
                        <th className="px-4 py-2 text-left font-medium text-slate-500">Amount</th>
                        <th className="px-4 py-2 text-left font-medium text-slate-500">Equity</th>
                        <th className="px-4 py-2 text-left font-medium text-slate-500">Pre-Money</th>
                        <th className="px-4 py-2 text-right font-medium text-slate-500">Actions</th>
                    </tr>
                </thead>
                <tbody className="bg-white divide-y divide-slate-200">
                    {mockInvestors.map(inv => (
                        <tr key={inv.id}>
                            <td className="px-4 py-2 font-medium text-slate-900">{inv.investorName}</td>
                            <td className="px-4 py-2 text-slate-500">{formatCurrency(inv.amount)}</td>
                            <td className="px-4 py-2 text-slate-500">{inv.equityAllocated}%</td>
                            <td className="px-4 py-2 text-slate-500">{formatCurrency(inv.preMoneyValuation)}</td>
                            <td className="px-4 py-2 text-right">
                                <Button size="sm" variant="outline" disabled={!canEdit}><Edit3 className="h-4 w-4" /></Button>
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
      </Card>
    </div>
  );
};

export default CapTableTab;