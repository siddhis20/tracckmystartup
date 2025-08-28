import React, { useState, useMemo, useEffect } from 'react';
import { User, Startup, VerificationRequest, InvestmentOffer, ComplianceStatus, UserRole } from '../types';
import { ValidationRequest } from '../lib/validationService';
import Card from './ui/Card';
import Button from './ui/Button';
import Badge from './ui/Badge';
import { Users, Building2, HelpCircle, FileCheck2, LayoutGrid, Eye, Check, X, UserCheck, NotebookPen, BookUser, FileStack, Database, Shield, Settings } from 'lucide-react';
import UserGrowthChart from './admin/UserGrowthChart';
import UserRoleDistributionChart from './admin/UserRoleDistributionChart';
import DataManager from './DataManager';
import { complianceRulesService } from '../lib/complianceRulesService';


interface AdminViewProps {
  users: User[];
  startups: Startup[];
  verificationRequests: VerificationRequest[];
  investmentOffers: InvestmentOffer[];
  validationRequests: ValidationRequest[];
  onProcessVerification: (requestId: number, status: 'approved' | 'rejected') => void;
  onProcessOffer: (offerId: number, status: 'approved' | 'rejected') => void;
  onProcessValidationRequest: (requestId: number, status: 'approved' | 'rejected', notes?: string) => void;
  onViewStartup: (id: number) => void;
}

type AdminTab = 'dashboard' | 'users' | 'verifications' | 'offers' | 'validations' | 'data' | 'complianceRules';
type TimeFilter = '30d' | '90d' | 'all';

const SummaryCard: React.FC<{ title: string; value: string | number; icon: React.ReactNode }> = ({ title, value, icon }) => (
    <Card className="flex-1">
        <div className="flex items-center justify-between">
            <div>
                <p className="text-sm font-medium text-slate-500">{title}</p>
                <p className="text-2xl font-bold text-slate-800">{value}</p>
            </div>
            <div className="p-3 bg-brand-light rounded-full">
                {icon}
            </div>
        </div>
    </Card>
);

const formatCurrency = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact' }).format(value);

const AdminView: React.FC<AdminViewProps> = ({ users, startups, verificationRequests, investmentOffers, validationRequests, onProcessVerification, onProcessOffer, onProcessValidationRequest, onViewStartup }) => {
    const [activeTab, setActiveTab] = useState<AdminTab>('dashboard');
    const [timeFilter, setTimeFilter] = useState<TimeFilter>('all');

    const investorCount = useMemo(() => users.filter(u => u.role === 'Investor').length, [users]);
    const caCount = useMemo(() => users.filter(u => u.role === 'CA').length, [users]);
    const csCount = useMemo(() => users.filter(u => u.role === 'CS').length, [users]);
    const totalOffers = investmentOffers.length;
    const pendingValidations = validationRequests.filter(v => v.status === 'pending').length;
    
    const filteredUsers = useMemo(() => {
        if (timeFilter === 'all') {
            return users;
        }
        const now = new Date();
        const daysToSubtract = timeFilter === '30d' ? 30 : 90;
        const cutoffDate = new Date(new Date().setDate(now.getDate() - daysToSubtract));
        return users.filter(u => new Date(u.registrationDate) >= cutoffDate);
    }, [users, timeFilter]);

    const renderTabContent = () => {
        switch (activeTab) {
            case 'dashboard': return <DashboardTab startups={startups} users={filteredUsers} onViewStartup={onViewStartup} timeFilter={timeFilter} setTimeFilter={setTimeFilter} />;
            case 'users': return <UsersTab users={users} />;
            case 'verifications': return <VerificationsTab requests={verificationRequests} onProcessVerification={onProcessVerification} />;
            case 'offers': return <OffersTab offers={investmentOffers} onProcessOffer={onProcessOffer} />;
            case 'validations': return <ValidationsTab requests={validationRequests} onProcessValidationRequest={onProcessValidationRequest} />;
            case 'data': return <DataManager />;
            case 'complianceRules': return <ComplianceRulesManager />;
            default: return null;
        }
    }
    
    return (
        <div className="space-y-6">
             <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-6">
                <SummaryCard title="Total Users" value={users.length} icon={<Users className="h-6 w-6 text-brand-primary" />} />
                <SummaryCard title="Total Startups" value={startups.length} icon={<Building2 className="h-6 w-6 text-brand-primary" />} />
                <SummaryCard title="Total Investors" value={investorCount} icon={<UserCheck className="h-6 w-6 text-brand-primary" />} />
                <SummaryCard title="Total CAs" value={caCount} icon={<NotebookPen className="h-6 w-6 text-brand-primary" />} />
                <SummaryCard title="Total CSs" value={csCount} icon={<BookUser className="h-6 w-6 text-brand-primary" />} />
                <SummaryCard title="Pending Verifications" value={verificationRequests.length} icon={<HelpCircle className="h-6 w-6 text-brand-primary" />} />
                <SummaryCard title="Pending Offers" value={investmentOffers.filter(o => o.status === 'pending').length} icon={<FileCheck2 className="h-6 w-6 text-brand-primary" />} />
                <SummaryCard title="Pending Validations" value={pendingValidations} icon={<Shield className="h-6 w-6 text-brand-primary" />} />
                <SummaryCard title="All Submitted Offers" value={totalOffers} icon={<FileStack className="h-6 w-6 text-brand-primary" />} />
            </div>

            <div className="border-b border-slate-200">
                <nav className="-mb-px flex space-x-6" aria-label="Tabs">
                    <TabButton id="dashboard" activeTab={activeTab} setActiveTab={setActiveTab} icon={<LayoutGrid />}>Dashboard</TabButton>
                    <TabButton id="users" activeTab={activeTab} setActiveTab={setActiveTab} icon={<Users />}>User Management</TabButton>
                    <TabButton id="verifications" activeTab={activeTab} setActiveTab={setActiveTab} icon={<FileCheck2 />}>Verifications</TabButton>
                    <TabButton id="offers" activeTab={activeTab} setActiveTab={setActiveTab} icon={<HelpCircle />}>Offer Approvals</TabButton>
                    <TabButton id="validations" activeTab={activeTab} setActiveTab={setActiveTab} icon={<Shield />}>Startup Nation Validations</TabButton>
                    <TabButton id="data" activeTab={activeTab} setActiveTab={setActiveTab} icon={<Database />}>Data Management</TabButton>
                    <TabButton id="complianceRules" activeTab={activeTab} setActiveTab={setActiveTab} icon={<Settings />}>Compliance Rules</TabButton>
                </nav>
            </div>

            <div className="animate-fade-in">
                {renderTabContent()}
            </div>
            <style>{`
                @keyframes fade-in {
                    from { opacity: 0; transform: translateY(10px); }
                    to { opacity: 1; transform: translateY(0); }
                }
                .animate-fade-in {
                    animation: fade-in 0.4s ease-in-out forwards;
                }
            `}</style>
        </div>
    )
};

const TabButton: React.FC<{id: AdminTab, activeTab: AdminTab, setActiveTab: (id: AdminTab) => void, icon: React.ReactElement, children: React.ReactNode}> = ({ id, activeTab, setActiveTab, icon, children }) => {
    const iconProps = { className: 'h-5 w-5' };
    return (
        <button
            onClick={() => setActiveTab(id)}
            className={`${
                activeTab === id
                ? 'border-brand-primary text-brand-primary'
                : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
            } flex items-center gap-2 whitespace-nowrap py-3 px-1 border-b-2 font-medium text-sm transition-colors focus:outline-none`}
        >
            {React.cloneElement(icon, iconProps)}
            {children}
        </button>
    );
};


const TimeFilterButton: React.FC<{
    filter: TimeFilter,
    currentFilter: TimeFilter,
    setTimeFilter: (filter: TimeFilter) => void,
    children: React.ReactNode
}> = ({ filter, currentFilter, setTimeFilter, children }) => (
    <button
        type="button"
        onClick={() => setTimeFilter(filter)}
        className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
            currentFilter === filter
                ? 'bg-brand-primary text-white'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
        }`}
    >
        {children}
    </button>
);

const DashboardTab: React.FC<{ 
    startups: Startup[], 
    users: User[],
    onViewStartup: (id: number) => void,
    timeFilter: TimeFilter,
    setTimeFilter: (filter: TimeFilter) => void 
}> = ({ startups, users, onViewStartup, timeFilter, setTimeFilter }) => (
    <div className="space-y-8">
        <Card>
            <div className="flex flex-wrap justify-between items-center mb-4 gap-4">
                 <h3 className="text-lg font-semibold text-slate-700">Platform Analytics</h3>
                 <div className="flex items-center gap-2">
                    <TimeFilterButton filter="30d" currentFilter={timeFilter} setTimeFilter={setTimeFilter}>30 Days</TimeFilterButton>
                    <TimeFilterButton filter="90d" currentFilter={timeFilter} setTimeFilter={setTimeFilter}>90 Days</TimeFilterButton>
                    <TimeFilterButton filter="all" currentFilter={timeFilter} setTimeFilter={setTimeFilter}>All Time</TimeFilterButton>
                 </div>
            </div>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <UserGrowthChart users={users} />
                <UserRoleDistributionChart users={users} />
            </div>
        </Card>
        
        <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">All Startups</h3>
            <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-slate-200">
                    <thead className="bg-slate-50">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Name</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Sector</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Valuation</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Status</th>
                            <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-slate-200">
                        {startups.map(s => (
                            <tr key={s.id}>
                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">{s.name}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{s.sector}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{formatCurrency(s.currentValuation)}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500"><Badge status={s.complianceStatus} /></td>
                                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                    <Button size="sm" variant="outline" onClick={() => onViewStartup(s.id)}><Eye className="mr-2 h-4 w-4" /> View Details</Button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </Card>
    </div>
);


const UsersTab: React.FC<{ users: User[] }> = ({ users }) => (
    <Card>
        <h3 className="text-lg font-semibold mb-4 text-slate-700">User Management</h3>
        <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200">
                <thead className="bg-slate-50">
                    <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Name</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Email</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Role</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Registration Date</th>
                    </tr>
                </thead>
                <tbody className="bg-white divide-y divide-slate-200">
                    {users.map(u => (
                        <tr key={u.id}>
                            <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">{u.name}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{u.email}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{u.role}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{u.registrationDate}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    </Card>
);

const VerificationsTab: React.FC<{ requests: VerificationRequest[], onProcessVerification: AdminViewProps['onProcessVerification'] }> = ({ requests, onProcessVerification }) => (
     <Card>
        <h3 className="text-lg font-semibold mb-4 text-slate-700">"Startup Nation" Verification Requests</h3>
        <div className="overflow-x-auto">
             <table className="min-w-full divide-y divide-slate-200">
                <thead className="bg-slate-50">
                    <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Startup Name</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Request Date</th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody className="bg-white divide-y divide-slate-200">
                    {requests.length > 0 ? requests.map(req => (
                        <tr key={req.id}>
                            <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">{req.startupName}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{req.requestDate}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                                <Button size="sm" className="bg-red-600 hover:bg-red-700" onClick={() => onProcessVerification(req.id, 'rejected')}><X className="mr-1 h-4 w-4" /> Reject</Button>
                                <Button size="sm" className="bg-green-600 hover:bg-green-700" onClick={() => onProcessVerification(req.id, 'approved')}><Check className="mr-1 h-4 w-4" /> Approve</Button>
                            </td>
                        </tr>
                    )) : (
                        <tr><td colSpan={3} className="text-center py-10 text-slate-500">No pending verification requests.</td></tr>
                    )}
                </tbody>
            </table>
        </div>
    </Card>
);

const OffersTab: React.FC<{ offers: InvestmentOffer[], onProcessOffer: AdminViewProps['onProcessOffer'] }> = ({ offers, onProcessOffer }) => (
    <Card>
        <h3 className="text-lg font-semibold mb-4 text-slate-700">Investment Offer Approvals</h3>
        <div className="overflow-x-auto">
             <table className="min-w-full divide-y divide-slate-200">
                <thead className="bg-slate-50">
                    <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Investor</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Startup</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Offer</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Status</th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody className="bg-white divide-y divide-slate-200">
                    {offers.length > 0 ? offers.map(o => (
                        <tr key={o.id}>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{o.investorEmail}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">{o.startupName}</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{formatCurrency(o.offerAmount)} for {o.equityPercentage}%</td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                                <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                                    o.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                    o.status === 'approved' ? 'bg-green-100 text-green-800' :
                                    'bg-red-100 text-red-800'
                                }`}>
                                    {o.status}
                                </span>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                                {o.status === 'pending' && (
                                    <>
                                        <Button size="sm" className="bg-red-600 hover:bg-red-700" onClick={() => onProcessOffer(o.id, 'rejected')}><X className="mr-1 h-4 w-4" /> Reject</Button>
                                        <Button size="sm" className="bg-green-600 hover:bg-green-700" onClick={() => onProcessOffer(o.id, 'approved')}><Check className="mr-1 h-4 w-4" /> Approve</Button>
                                    </>
                                )}
                            </td>
                        </tr>
                    )) : (
                         <tr><td colSpan={5} className="text-center py-10 text-slate-500">No investment offers have been made.</td></tr>
                    )}
                </tbody>
            </table>
        </div>
    </Card>
);

const ValidationsTab: React.FC<{ requests: ValidationRequest[], onProcessValidationRequest: AdminViewProps['onProcessValidationRequest'] }> = ({ requests, onProcessValidationRequest }) => {
    const [processingRequest, setProcessingRequest] = useState<number | null>(null);
    const [notes, setNotes] = useState<string>('');

    const handleProcess = async (requestId: number, status: 'approved' | 'rejected') => {
        setProcessingRequest(requestId);
        try {
            await onProcessValidationRequest(requestId, status, notes);
            setNotes('');
        } finally {
            setProcessingRequest(null);
        }
    };

    return (
        <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">Startup Nation Validation Requests</h3>
            <div className="mb-4">
                <label className="block text-sm font-medium text-slate-700 mb-2">Admin Notes (optional)</label>
                <textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent"
                    placeholder="Add notes for the startup..."
                    rows={3}
                />
            </div>
            <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-slate-200">
                    <thead className="bg-slate-50">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Startup Name</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Request Date</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Status</th>
                            <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-slate-200">
                        {requests.length > 0 ? requests.map(req => (
                            <tr key={req.id}>
                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">{req.startupName}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                                    {new Date(req.requestDate).toLocaleDateString()}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                                    <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                                        req.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                        req.status === 'approved' ? 'bg-green-100 text-green-800' :
                                        'bg-red-100 text-red-800'
                                    }`}>
                                        {req.status}
                                    </span>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                                    {req.status === 'pending' && (
                                        <>
                                            <Button 
                                                size="sm" 
                                                className="bg-red-600 hover:bg-red-700" 
                                                onClick={() => handleProcess(req.id, 'rejected')}
                                                disabled={processingRequest === req.id}
                                            >
                                                <X className="mr-1 h-4 w-4" /> 
                                                {processingRequest === req.id ? 'Processing...' : 'Reject'}
                                            </Button>
                                            <Button 
                                                size="sm" 
                                                className="bg-green-600 hover:bg-green-700" 
                                                onClick={() => handleProcess(req.id, 'approved')}
                                                disabled={processingRequest === req.id}
                                            >
                                                <Check className="mr-1 h-4 w-4" /> 
                                                {processingRequest === req.id ? 'Processing...' : 'Approve'}
                                            </Button>
                                        </>
                                    )}
                                    {req.status !== 'pending' && req.adminNotes && (
                                        <span className="text-xs text-slate-500" title={req.adminNotes}>
                                            Has notes
                                        </span>
                                    )}
                                </td>
                            </tr>
                        )) : (
                            <tr><td colSpan={4} className="text-center py-10 text-slate-500">No validation requests found.</td></tr>
                        )}
                    </tbody>
                </table>
            </div>
        </Card>
    );
};

export default AdminView;

// Structured, table-based manager (country → company type → phase rules)
const ComplianceRulesManager: React.FC = () => {
    const [loading, setLoading] = useState(true);
    const [rows, setRows] = useState<any[]>([]);
    const [selectedCountry, setSelectedCountry] = useState<string>('');
    const [companyType, setCompanyType] = useState<string>('default');
    const [rulesJson, setRulesJson] = useState<any>({});
    const [newRule, setNewRule] = useState<{ phase: 'firstYear' | 'annual'; name: string; caRequired: boolean; csRequired: boolean }>({ phase: 'annual', name: '', caRequired: false, csRequired: false });

    const load = async () => {
        setLoading(true);
        const data = await complianceRulesService.listAll();
        setRows(data);
        if (data.length > 0 && !selectedCountry) {
            setSelectedCountry(data[0].country_code);
            setRulesJson(data[0].rules || {});
            const types = Object.keys(data[0].rules || { default: {} });
            setCompanyType(types[0] || 'default');
        }
        setLoading(false);
    };

    useEffect(() => { load(); }, []);

    useEffect(() => {
        const row = rows.find(r => r.country_code === selectedCountry);
        if (row) {
            setRulesJson(row.rules || {});
            const types = Object.keys(row.rules || { default: {} });
            if (!types.includes(companyType)) {
                setCompanyType(types[0] || 'default');
            }
        }
    }, [selectedCountry]);

    const countryOptions = rows.map(r => r.country_code).sort();
    const currentCompany = rulesJson[companyType] || { annual: [], firstYear: [] };

    const addRule = () => {
        if (!newRule.name.trim()) return;
        const idPrefix = `${selectedCountry.toLowerCase()}-${companyType.toLowerCase().replace(/\s+/g,'')}-${newRule.phase === 'annual' ? 'an' : 'fy'}`;
        const rule = { id: `${idPrefix}-${Date.now()}`, name: newRule.name.trim(), caRequired: newRule.caRequired, csRequired: newRule.csRequired };
        const updated = { ...rulesJson };
        const bucket = (updated[companyType] ||= { annual: [], firstYear: [] });
        bucket[newRule.phase] = [...(bucket[newRule.phase] || []), rule];
        setRulesJson(updated);
        setNewRule({ phase: 'annual', name: '', caRequired: false, csRequired: false });
    };

    const removeRule = (phase: 'annual' | 'firstYear', id: string) => {
        const updated = { ...rulesJson };
        updated[companyType][phase] = updated[companyType][phase].filter((r: any) => r.id !== id);
        setRulesJson(updated);
    };

    const updateRuleField = (phase: 'annual' | 'firstYear', id: string, field: 'name' | 'caRequired' | 'csRequired', value: any) => {
        const updated = { ...rulesJson };
        updated[companyType][phase] = updated[companyType][phase].map((r: any) => r.id === id ? { ...r, [field]: value } : r);
        setRulesJson(updated);
    };

    const saveCountry = async () => {
        if (!selectedCountry) return;
        await complianceRulesService.upsertCountryRules(selectedCountry, rulesJson);
        await load();
    };

    const addCountry = async () => {
        const code = prompt('Enter new country code (e.g., IN, US):');
        if (!code) return;
        await complianceRulesService.upsertCountryRules(code.toUpperCase(), { default: { annual: [], firstYear: [] } });
        await load();
        setSelectedCountry(code.toUpperCase());
        setCompanyType('default');
    };

    const addCompanyType = () => {
        const type = prompt('Enter company type label (e.g., Private Limited Company):');
        if (!type) return;
        if (!rulesJson[type]) {
            const updated = { ...rulesJson, [type]: { annual: [], firstYear: [] } };
            setRulesJson(updated);
            setCompanyType(type);
        } else {
            setCompanyType(type);
        }
    };

    const removeCountry = async (country_code: string) => {
        if (!confirm(`Remove rules for ${country_code}?`)) return;
        await complianceRulesService.deleteCountry(country_code);
        await load();
    };

    return (
        <Card>
            <div className="p-4 space-y-6">
                <div className="flex flex-wrap gap-3 items-center justify-between">
                    <h3 className="text-lg font-semibold text-slate-700">Compliance Rules (Global)</h3>
                    <div className="flex gap-2">
                        <Button variant="outline" onClick={addCountry}>Add Country</Button>
                        {selectedCountry && <Button className="bg-red-600 hover:bg-red-700" variant="default" onClick={() => removeCountry(selectedCountry)}>Delete Country</Button>}
                        <Button onClick={saveCountry}>Save Changes</Button>
                    </div>
                </div>

                {loading ? (
                    <div className="text-slate-500">Loading...</div>
                ) : (
                    <div className="grid gap-4">
                        <div className="flex flex-wrap gap-3 items-center">
                            <label className="text-sm text-slate-600">Country</label>
                            <select value={selectedCountry} onChange={(e) => setSelectedCountry(e.target.value)} className="border border-slate-300 rounded-md px-3 py-1 text-sm">
                                {countryOptions.map(c => <option key={c} value={c}>{c}</option>)}
                            </select>
                            <label className="text-sm text-slate-600 ml-2">Company Type</label>
                            <select value={companyType} onChange={(e) => setCompanyType(e.target.value)} className="border border-slate-300 rounded-md px-3 py-1 text-sm">
                                {Object.keys(rulesJson || {}).map((t: string) => (
                                    <option key={t} value={t}>{t}</option>
                                ))}
                            </select>
                            <Button variant="outline" onClick={addCompanyType}>Add Company Type</Button>
                        </div>

                        {/* First Year Rules Table */}
                        <div>
                            <h4 className="text-sm font-semibold text-slate-700 mb-2">First Year Rules</h4>
                            <div className="overflow-x-auto">
                                <table className="min-w-full divide-y divide-slate-200">
                                    <thead className="bg-slate-50">
                                        <tr>
                                            <th className="px-4 py-2 text-left text-xs font-semibold text-slate-600 uppercase tracking-wider">Rule Name</th>
                                            <th className="px-4 py-2 text-center text-xs font-semibold text-slate-600 uppercase tracking-wider">CA Required</th>
                                            <th className="px-4 py-2 text-center text-xs font-semibold text-slate-600 uppercase tracking-wider">CS Required</th>
                                            <th className="px-4 py-2 text-right text-xs font-semibold text-slate-600 uppercase tracking-wider">Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-slate-200 bg-white">
                                        {(currentCompany.firstYear || []).map((r: any) => (
                                            <tr key={r.id}>
                                                <td className="px-4 py-2">
                                                    <input value={r.name} onChange={(e) => updateRuleField('firstYear', r.id, 'name', e.target.value)} className="w-full border border-slate-300 rounded-md px-2 py-1 text-sm" />
                                                </td>
                                                <td className="px-4 py-2 text-center">
                                                    <input type="checkbox" checked={!!r.caRequired} onChange={(e) => updateRuleField('firstYear', r.id, 'caRequired', e.target.checked)} />
                                                </td>
                                                <td className="px-4 py-2 text-center">
                                                    <input type="checkbox" checked={!!r.csRequired} onChange={(e) => updateRuleField('firstYear', r.id, 'csRequired', e.target.checked)} />
                                                </td>
                                                <td className="px-4 py-2 text-right">
                                                    <Button size="sm" className="bg-red-600 hover:bg-red-700" onClick={() => removeRule('firstYear', r.id)}>Remove</Button>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        {/* Annual Rules Table */}
                        <div>
                            <h4 className="text-sm font-semibold text-slate-700 mb-2">Annual Rules</h4>
                            <div className="overflow-x-auto">
                                <table className="min-w-full divide-y divide-slate-200">
                                    <thead className="bg-slate-50">
                                        <tr>
                                            <th className="px-4 py-2 text-left text-xs font-semibold text-slate-600 uppercase tracking-wider">Rule Name</th>
                                            <th className="px-4 py-2 text-center text-xs font-semibold text-slate-600 uppercase tracking-wider">CA Required</th>
                                            <th className="px-4 py-2 text-center text-xs font-semibold text-slate-600 uppercase tracking-wider">CS Required</th>
                                            <th className="px-4 py-2 text-right text-xs font-semibold text-slate-600 uppercase tracking-wider">Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-slate-200 bg-white">
                                        {(currentCompany.annual || []).map((r: any) => (
                                            <tr key={r.id}>
                                                <td className="px-4 py-2">
                                                    <input value={r.name} onChange={(e) => updateRuleField('annual', r.id, 'name', e.target.value)} className="w-full border border-slate-300 rounded-md px-2 py-1 text-sm" />
                                                </td>
                                                <td className="px-4 py-2 text-center">
                                                    <input type="checkbox" checked={!!r.caRequired} onChange={(e) => updateRuleField('annual', r.id, 'caRequired', e.target.checked)} />
                                                </td>
                                                <td className="px-4 py-2 text-center">
                                                    <input type="checkbox" checked={!!r.csRequired} onChange={(e) => updateRuleField('annual', r.id, 'csRequired', e.target.checked)} />
                                                </td>
                                                <td className="px-4 py-2 text-right">
                                                    <Button size="sm" className="bg-red-600 hover:bg-red-700" onClick={() => removeRule('annual', r.id)}>Remove</Button>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        {/* Add Rule */}
                        <div className="flex flex-wrap items-end gap-2">
                            <div>
                                <label className="block text-xs text-slate-600 mb-1">Phase</label>
                                <select value={newRule.phase} onChange={(e) => setNewRule(prev => ({ ...prev, phase: e.target.value as any }))} className="border border-slate-300 rounded-md px-2 py-1 text-sm">
                                    <option value="annual">Annual</option>
                                    <option value="firstYear">First Year</option>
                                </select>
                            </div>
                            <div className="flex-1 min-w-[240px]">
                                <label className="block text-xs text-slate-600 mb-1">Rule Name</label>
                                <input value={newRule.name} onChange={(e) => setNewRule(prev => ({ ...prev, name: e.target.value }))} className="w-full border border-slate-300 rounded-md px-2 py-1 text-sm" placeholder="e.g., File Annual Return (MGT-7)" />
                            </div>
                            <label className="flex items-center gap-2 text-sm text-slate-700">
                                <input type="checkbox" checked={newRule.caRequired} onChange={(e) => setNewRule(prev => ({ ...prev, caRequired: e.target.checked }))} /> CA Required
                            </label>
                            <label className="flex items-center gap-2 text-sm text-slate-700">
                                <input type="checkbox" checked={newRule.csRequired} onChange={(e) => setNewRule(prev => ({ ...prev, csRequired: e.target.checked }))} /> CS Required
                            </label>
                            <Button onClick={addRule}>Add Rule</Button>
                        </div>
                    </div>
                )}
            </div>
        </Card>
    );
};