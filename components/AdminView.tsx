import React, { useState, useMemo } from 'react';
import { User, Startup, VerificationRequest, InvestmentOffer, ComplianceStatus, UserRole } from '../types';
import Card from './ui/Card';
import Button from './ui/Button';
import Badge from './ui/Badge';
import { Users, Building2, HelpCircle, FileCheck2, LayoutGrid, Eye, Check, X, UserCheck, NotebookPen, BookUser, FileStack, Database } from 'lucide-react';
import UserGrowthChart from './admin/UserGrowthChart';
import UserRoleDistributionChart from './admin/UserRoleDistributionChart';
import DataManager from './DataManager';


interface AdminViewProps {
  users: User[];
  startups: Startup[];
  verificationRequests: VerificationRequest[];
  investmentOffers: InvestmentOffer[];
  onProcessVerification: (requestId: number, status: 'approved' | 'rejected') => void;
  onProcessOffer: (offerId: number, status: 'approved' | 'rejected') => void;
  onViewStartup: (id: number) => void;
}

type AdminTab = 'dashboard' | 'users' | 'verifications' | 'offers' | 'data';
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

const AdminView: React.FC<AdminViewProps> = ({ users, startups, verificationRequests, investmentOffers, onProcessVerification, onProcessOffer, onViewStartup }) => {
    const [activeTab, setActiveTab] = useState<AdminTab>('dashboard');
    const [timeFilter, setTimeFilter] = useState<TimeFilter>('all');

    const investorCount = useMemo(() => users.filter(u => u.role === 'Investor').length, [users]);
    const caCount = useMemo(() => users.filter(u => u.role === 'CA').length, [users]);
    const csCount = useMemo(() => users.filter(u => u.role === 'CS').length, [users]);
    const totalOffers = investmentOffers.length;
    
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
            case 'data': return <DataManager />;
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
                <SummaryCard title="All Submitted Offers" value={totalOffers} icon={<FileStack className="h-6 w-6 text-brand-primary" />} />
            </div>

            <div className="border-b border-slate-200">
                <nav className="-mb-px flex space-x-6" aria-label="Tabs">
                    <TabButton id="dashboard" activeTab={activeTab} setActiveTab={setActiveTab} icon={<LayoutGrid />}>Dashboard</TabButton>
                    <TabButton id="users" activeTab={activeTab} setActiveTab={setActiveTab} icon={<Users />}>User Management</TabButton>
                    <TabButton id="verifications" activeTab={activeTab} setActiveTab={setActiveTab} icon={<FileCheck2 />}>Verifications</TabButton>
                    <TabButton id="offers" activeTab={activeTab} setActiveTab={setActiveTab} icon={<HelpCircle />}>Offer Approvals</TabButton>
                    <TabButton id="data" activeTab={activeTab} setActiveTab={setActiveTab} icon={<Database />}>Data Management</TabButton>
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

export default AdminView;