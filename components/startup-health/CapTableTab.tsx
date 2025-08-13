import React, { useState, useEffect } from 'react';
import { Startup, InvestmentRecord, InvestorType, InvestmentRoundType, Founder, FundraisingDetails, UserRole } from '../../types';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import Modal from '../ui/Modal';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { Plus, Trash2, Edit3, Save, X, TrendingUp, Users, DollarSign, PieChart as PieChartIcon, UserPlus, Download, Upload } from 'lucide-react';
import { capTableService } from '../../lib/capTableService';
import { AuthUser } from '../../lib/auth';

interface CapTableTabProps {
  startup: Startup;
  userRole?: UserRole;
  user?: AuthUser;
  onActivateFundraising: (details: FundraisingDetails, startup: Startup) => void;
  onInvestorAdded: (investment: InvestmentRecord, startup: Startup) => void;
  onUpdateFounders: (startupId: number, founders: Founder[]) => void;
}

interface FounderStateItem extends Founder {
  id: number;
}

interface InvestmentSummary {
  totalEquityFunding: number;
  totalDebtFunding: number;
  totalGrantFunding: number;
  totalInvestments: number;
  avgEquityAllocated: number;
}

interface ValuationHistoryData {
  roundName: string;
  valuation: number;
  investmentAmount: number;
  date: string;
}

interface EquityDistributionData {
  holderType: string;
  equityPercentage: number;
  totalAmount: number;
}

const formatCurrency = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
const formatCurrencyCompact = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact' }).format(value);

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6', '#60a5fa'];

const CapTableTab: React.FC<CapTableTabProps> = ({ startup, userRole, user, onActivateFundraising, onInvestorAdded, onUpdateFounders }) => {
    const [isEditing, setIsEditing] = useState(false);
    const [isFundraisingModalOpen, setIsFundraisingModalOpen] = useState(false);
    const [isAddInvestorModalOpen, setIsAddInvestorModalOpen] = useState(false);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    
    // Real data states
    const [investmentRecords, setInvestmentRecords] = useState<InvestmentRecord[]>([]);
    const [founders, setFounders] = useState<Founder[]>([]);
    const [fundraisingDetails, setFundraisingDetails] = useState<FundraisingDetails[]>([]);
    const [valuationHistory, setValuationHistory] = useState<ValuationHistoryData[]>([]);
    const [equityDistribution, setEquityDistribution] = useState<EquityDistributionData[]>([]);
    const [investmentSummary, setInvestmentSummary] = useState<InvestmentSummary>({
        totalEquityFunding: 0,
        totalDebtFunding: 0,
        totalGrantFunding: 0,
        totalInvestments: 0,
        avgEquityAllocated: 0
    });

    const canEdit = userRole === 'Startup';
    console.log('CapTableTab - userRole:', userRole, 'canEdit:', canEdit);
    
    // Form states
    const [isEditingFundraising, setIsEditingFundraising] = useState(false);
    const [fundraising, setFundraising] = useState<FundraisingDetails>({
        active: false,
        type: 'SeriesA',
        value: 5000000,
        equity: 15,
        validationRequested: false,
        pitchDeckUrl: '',
        pitchVideoUrl: '',
    });
    
    const [isFounderModalOpen, setIsFounderModalOpen] = useState(false);
    const [editingFounders, setEditingFounders] = useState<FounderStateItem[]>([]);

    // Load data on component mount
    useEffect(() => {
        loadCapTableData();
        setupRealTimeSubscriptions();
    }, [startup.id]);

    const loadCapTableData = async () => {
        if (!startup?.id) return;
        
        setIsLoading(true);
        setError(null);
        
        try {
            const [
                records,
                foundersData,
                fundraisingData,
                valuationData,
                equityData,
                summaryData
            ] = await Promise.allSettled([
                capTableService.getInvestmentRecords(startup.id),
                capTableService.getFounders(startup.id),
                capTableService.getFundraisingDetails(startup.id),
                capTableService.getValuationHistoryData(startup.id),
                capTableService.getEquityDistributionData(startup.id),
                capTableService.getInvestmentSummary(startup.id)
            ]);

            // Handle each result individually
            setInvestmentRecords(records.status === 'fulfilled' ? records.value : []);
            setFounders(foundersData.status === 'fulfilled' ? foundersData.value : []);
            setFundraisingDetails(fundraisingData.status === 'fulfilled' ? fundraisingData.value : []);
            setValuationHistory(valuationData.status === 'fulfilled' ? valuationData.value : []);
            setEquityDistribution(equityData.status === 'fulfilled' ? equityData.value : []);
            setInvestmentSummary(summaryData.status === 'fulfilled' ? summaryData.value : {
                totalEquityFunding: 0,
                totalDebtFunding: 0,
                totalGrantFunding: 0,
                totalInvestments: 0,
                avgEquityAllocated: 0
            });

            // Set current fundraising details if available
            if (fundraisingData.status === 'fulfilled' && fundraisingData.value.length > 0) {
                setFundraising(fundraisingData.value[0]);
            }

            // Log any errors for debugging
            [records, foundersData, fundraisingData, valuationData, equityData, summaryData].forEach((result, index) => {
                if (result.status === 'rejected') {
                    console.warn(`Failed to load data ${index}:`, result.reason);
                }
            });

            // Debug loaded data
            console.log('📊 Cap Table Data Loaded:', {
                investmentRecords: records.status === 'fulfilled' ? records.value.length : 'failed',
                founders: foundersData.status === 'fulfilled' ? foundersData.value.length : 'failed',
                fundraisingDetails: fundraisingData.status === 'fulfilled' ? fundraisingData.value.length : 'failed',
                valuationHistory: valuationData.status === 'fulfilled' ? valuationData.value.length : 'failed',
                equityDistribution: equityData.status === 'fulfilled' ? equityData.value.length : 'failed',
                investmentSummary: summaryData.status === 'fulfilled' ? summaryData.value : 'failed'
            });
        } catch (err) {
            console.error('Error loading cap table data:', err);
            setError('Failed to load cap table data');
        } finally {
            setIsLoading(false);
        }
    };

    const setupRealTimeSubscriptions = () => {
        if (!startup?.id) return;

        // Subscribe to real-time changes
        const investmentSubscription = capTableService.subscribeToInvestmentRecords(startup.id, (records) => {
            setInvestmentRecords(records);
        });

        const foundersSubscription = capTableService.subscribeToFounders(startup.id, (founders) => {
            setFounders(founders);
        });

        const fundraisingSubscription = capTableService.subscribeToFundraisingDetails(startup.id, (details) => {
            setFundraisingDetails(details);
            if (details.length > 0) {
                setFundraising(details[0]);
            }
        });

        // Cleanup subscriptions on unmount
        return () => {
            investmentSubscription?.unsubscribe();
            foundersSubscription?.unsubscribe();
            fundraisingSubscription?.unsubscribe();
        };
    };

    const handleEditFoundersClick = () => {
        console.log('🔧 Opening founder edit modal with founders:', founders);
        setEditingFounders(founders.map(f => ({ ...f, id: Math.random() * 10000 })));
        setIsFounderModalOpen(true);
    };

    const handleFounderChange = (id: number, field: keyof Omit<FounderStateItem, 'id'>, value: string) => {
        console.log('✏️ Editing founder:', { id, field, value });
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

    const handleFounderSave = async () => {
        if (!startup?.id) return;
        
        try {
            const finalFounders = editingFounders.map(({ id, ...rest }) => rest);
            console.log('💾 Saving founders:', finalFounders);
            
            // Clear existing founders and add new ones
            await capTableService.deleteAllFounders(startup.id);
            console.log('🗑️ Deleted existing founders');
            
            for (const founder of finalFounders) {
                await capTableService.addFounder(startup.id, founder);
                console.log('➕ Added founder:', founder.name);
            }
            
            onUpdateFounders(startup.id, finalFounders);
            setIsFounderModalOpen(false);
            console.log('✅ Founders saved successfully');
        } catch (err) {
            console.error('Error saving founders:', err);
            setError('Failed to save founder information');
        }
    };

    const handleFundraisingSave = async () => {
        if (!startup?.id) return;
        
        try {
            // Optional: handle pitch deck upload if user selected a file
            const deckInput = document.getElementById('fr-deck') as HTMLInputElement | null;
            const deckFile = deckInput?.files?.[0];
            let deckUrl = fundraising.pitchDeckUrl;
            if (deckFile) {
                deckUrl = await capTableService.uploadPitchDeck(deckFile, startup.id);
            }

            const toSave = { ...fundraising, pitchDeckUrl: deckUrl };

            // Upsert via update-or-insert
            await capTableService.updateFundraisingDetails(startup.id, toSave);
            onActivateFundraising(fundraising, startup);
            setIsEditingFundraising(false);
        } catch (err) {
            console.error('Error saving fundraising details:', err);
            setError('Failed to save fundraising details');
        }
    };

    const handleAddInvestment = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        if (!startup?.id) return;
        
        try {
            const formData = new FormData(e.currentTarget);
            const proofFile = (e.currentTarget.querySelector('input[name="inv-proof"]') as HTMLInputElement)?.files?.[0];
            
            // Debug form data
            console.log('Form data entries:');
            for (const [key, value] of formData.entries()) {
                console.log(`${key}: ${value}`);
            }
            
            const date = formData.get('inv-date') as string;
            const investorType = formData.get('inv-investor-type') as InvestorType;
            const investmentType = formData.get('inv-type') as InvestmentRoundType;
            const investorName = formData.get('inv-name') as string;
            const investorCode = formData.get('inv-code') as string;
            const amount = Number(formData.get('inv-amount'));
            const equityAllocated = Number(formData.get('inv-equity'));
            const preMoneyValuation = Number(formData.get('inv-premoney'));
            
            // Validate required fields
            if (!date) {
                setError('Date is required');
                return;
            }
            if (!investorType) {
                setError('Investor type is required');
                return;
            }
            if (!investmentType) {
                setError('Investment type is required');
                return;
            }
            if (!investorName) {
                setError('Investor name is required');
                return;
            }
            if (!amount || amount <= 0) {
                setError('Valid investment amount is required');
                return;
            }
            if (!equityAllocated || equityAllocated < 0) {
                setError('Valid equity allocation is required');
                return;
            }
            if (!preMoneyValuation || preMoneyValuation <= 0) {
                setError('Valid pre-money valuation is required');
                return;
            }
            
            let proofUrl = '';
            if (proofFile) {
                proofUrl = await capTableService.uploadProofDocument(startup.id, proofFile);
            }
            
            const newInvestment = {
                startupId: startup.id,
                date,
                investorType,
                investmentType,
                investorName,
                investorCode,
                amount,
                equityAllocated,
                preMoneyValuation,
                proofUrl
            };
            
            console.log('Adding investment:', newInvestment);
            console.log('Startup ID:', startup.id);
            console.log('Investment data type:', typeof newInvestment);
            console.log('Investment data keys:', Object.keys(newInvestment));
            
            // Remove startupId from the data passed to service since it's passed separately
            const { startupId, ...investmentDataForService } = newInvestment;
            console.log('Investment data for service:', investmentDataForService);
            
            await capTableService.addInvestmentRecord(startup.id, investmentDataForService);
            onInvestorAdded(newInvestment as InvestmentRecord, startup);
            e.currentTarget.reset();
            setError(null); // Clear any previous errors
        } catch (err) {
            console.error('Error adding investment:', err);
            setError('Failed to add investment');
        }
    };

    const handleDeleteInvestment = async (investmentId: string) => {
        if (!startup?.id) return;
        
        try {
            await capTableService.deleteInvestmentRecord(investmentId);
        } catch (err) {
            console.error('Error deleting investment:', err);
            setError('Failed to delete investment');
        }
    };

    const handleDownloadProof = async (proofUrl: string, investorName: string) => {
        try {
            const downloadUrl = await capTableService.getAttachmentDownloadUrl(proofUrl);
            const link = document.createElement('a');
            link.href = downloadUrl;
            link.download = `investment-proof-${investorName}.pdf`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        } catch (err) {
            console.error('Error downloading proof:', err);
            setError('Failed to download proof document');
        }
    };

    // Prepare chart data
    const valuationData = valuationHistory.map(item => ({
        name: item.roundName,
        valuation: item.valuation,
        investment: item.investmentAmount
    }));

    const equityData = equityDistribution.map(item => ({
        name: item.holderType,
        value: item.equityPercentage
    }));

    // Debug chart data
    console.log('📈 Chart Data:', {
        valuationData: valuationData.length > 0 ? valuationData : 'No valuation data',
        equityData: equityData.length > 0 ? equityData : 'No equity data'
    });

    if (isLoading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
                    <p className="text-slate-600">Loading cap table data...</p>
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="text-center py-8">
                <p className="text-red-600 mb-4">{error}</p>
                <Button onClick={loadCapTableData}>Retry</Button>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <Card>
                    <p className="text-sm font-medium text-slate-500">Current Valuation</p>
                    <p className="text-2xl font-bold">
                        {investmentSummary.totalEquityFunding > 0 
                            ? formatCurrency(investmentSummary.totalEquityFunding * 6.67) // Rough valuation estimate
                            : formatCurrency(startup.currentValuation)
                        }
                    </p>
                </Card>
                <Card>
                    <p className="text-sm font-medium text-slate-500">Total Funding</p>
                    <p className="text-2xl font-bold">
                        {formatCurrency(
                            investmentSummary.totalEquityFunding + 
                            investmentSummary.totalDebtFunding + 
                            investmentSummary.totalGrantFunding
                        )}
                    </p>
                </Card>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <Card>
                    <p className="text-sm font-medium text-slate-500">Total Investments</p>
                    <p className="text-xl font-bold">{investmentSummary.totalInvestments}</p>
                </Card>
                <Card>
                    <p className="text-sm font-medium text-slate-500">Total Equity Funding</p>
                    <p className="text-xl font-bold">{formatCurrencyCompact(investmentSummary.totalEquityFunding)}</p>
                </Card>
                <Card>
                    <p className="text-sm font-medium text-slate-500">Total Debt Funding</p>
                    <p className="text-xl font-bold">{formatCurrencyCompact(investmentSummary.totalDebtFunding)}</p>
                </Card>
                <Card>
                    <p className="text-sm font-medium text-slate-500">Total Grant Funding</p>
                    <p className="text-xl font-bold">{formatCurrencyCompact(investmentSummary.totalGrantFunding)}</p>
                </Card>
            </div>

            {/* Charts & Founder Info */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-2 space-y-6">
                    <Card>
                        <h3 className="text-lg font-semibold mb-4 text-slate-700">Valuation History</h3>
                        {valuationData.length > 0 ? (
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
                        ) : (
                            <div className="flex items-center justify-center h-64 text-center">
                                <div>
                                    <TrendingUp className="h-12 w-12 text-slate-300 mx-auto mb-4" />
                                    <p className="text-slate-500 mb-2">No valuation history available</p>
                                    <p className="text-sm text-slate-400">Add investment records to see valuation trends</p>
                                </div>
                            </div>
                        )}
                    </Card>
                    <Card>
                        <h3 className="text-lg font-semibold mb-4 text-slate-700">Equity Holdings</h3>
                        {equityData.length > 0 ? (
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
                        ) : (
                            <div className="flex items-center justify-center h-64 text-center">
                                <div>
                                    <PieChartIcon className="h-12 w-12 text-slate-300 mx-auto mb-4" />
                                    <p className="text-slate-500 mb-2">No equity distribution available</p>
                                    <p className="text-sm text-slate-400">Add founders and investments to see equity breakdown</p>
                                </div>
                            </div>
                        )}
                    </Card>
                </div>
                <div className="space-y-6">
                    <Card>
                        <div className="flex justify-between items-center mb-4">
                            <h3 className="text-lg font-semibold text-slate-700">Founder Information</h3>
                            <Button variant="outline" size="sm" onClick={handleEditFoundersClick} disabled={!canEdit}>
                                <Edit3 className="h-4 w-4 mr-2" />Edit
                            </Button>
                        </div>
                        <div className="space-y-4">
                            {founders && founders.length > 0 ? (
                                founders.map((founder, index) => (
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
                                <Button variant="outline" size="sm" onClick={() => setIsEditingFundraising(true)} disabled={!canEdit}>
                                    <Edit3 className="h-4 w-4 mr-2" />Edit
                                </Button>
                            ) : (
                                <div className="flex gap-2">
                                    <Button variant="secondary" size="sm" onClick={() => setIsEditingFundraising(false)}>
                                        <X className="h-4 w-4"/>
                                    </Button>
                                    <Button size="sm" onClick={handleFundraisingSave}>
                                        <Save className="h-4 w-4 mr-2"/>Save
                                    </Button>
                                </div>
                            )}
                        </div>
                        <fieldset disabled={!isEditingFundraising}>
                            <div className="space-y-4">
                                <div className="flex items-center">
                                    <input 
                                        type="checkbox" 
                                        id="fundraising-active" 
                                        className="h-4 w-4 rounded border-gray-300 text-brand-primary focus:ring-brand-primary" 
                                        checked={fundraising.active} 
                                        onChange={(e) => setFundraising({...fundraising, active: e.target.checked})} 
                                    />
                                    <label htmlFor="fundraising-active" className="ml-2 block text-sm text-gray-900">Activate Fundraising Round</label>
                                </div>
                                <Select label="Type" id="fr-type" value={fundraising.type} onChange={e => setFundraising({...fundraising, type: e.target.value as InvestmentRoundType})}>
                                    {Object.values(InvestmentRoundType).map(t => <option key={t} value={t}>{t}</option>)}
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
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Proof</th>
                                <th className="px-4 py-2 text-right font-medium text-slate-500">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-slate-200">
                            {investmentRecords.map(inv => (
                                <tr key={inv.id}>
                                    <td className="px-4 py-2 font-medium text-slate-900">{inv.investorName}</td>
                                    <td className="px-4 py-2 text-slate-500">{formatCurrency(inv.amount)}</td>
                                    <td className="px-4 py-2 text-slate-500">{inv.equityAllocated}%</td>
                                    <td className="px-4 py-2 text-slate-500">{formatCurrency(inv.preMoneyValuation)}</td>
                                    <td className="px-4 py-2 text-slate-500">
                                        {inv.proofUrl && (
                                            <Button 
                                                size="sm" 
                                                variant="outline" 
                                                onClick={() => handleDownloadProof(inv.proofUrl!, inv.investorName)}
                                            >
                                                <Download className="h-4 w-4" />
                                            </Button>
                                        )}
                                    </td>
                                    <td className="px-4 py-2 text-right">
                                        <div className="flex gap-2 justify-end">
                                            <Button size="sm" variant="outline" disabled={!canEdit}>
                                                <Edit3 className="h-4 w-4" />
                                            </Button>
                                            <Button 
                                                size="sm" 
                                                variant="outline" 
                                                disabled={!canEdit}
                                                onClick={() => handleDeleteInvestment(inv.id)}
                                            >
                                                <Trash2 className="h-4 w-4" />
                                            </Button>
                                        </div>
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