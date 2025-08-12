import React, { useState } from 'react';
import { Startup, FundraisingDetails, InvestmentRecord, UserRole, Founder } from '../types';
import Button from './ui/Button';
import Card from './ui/Card';
import { ArrowLeft, LayoutDashboard, User, ShieldCheck, Banknote, Users, TableProperties, Building2 } from 'lucide-react';

import StartupDashboardTab from './startup-health/StartupDashboardTab';
import ProfileTab from './startup-health/ProfileTab';
import ComplianceTab from './startup-health/ComplianceTab';
import FinancialsTab from './startup-health/FinancialsTab';
import EmployeesTab from './startup-health/EmployeesTab';
import CapTableTab from './startup-health/CapTableTab';


interface StartupHealthViewProps {
  startup: Startup;
  userRole?: UserRole;
  onBack: () => void;
  onActivateFundraising: (details: FundraisingDetails, startup: Startup) => void;
  onInvestorAdded: (investment: InvestmentRecord, startup: Startup) => void;
  onUpdateFounders: (startupId: number, founders: Founder[]) => void;
}

type TabId = 'dashboard' | 'profile' | 'compliance' | 'financials' | 'employees' | 'capTable';

const StartupHealthView: React.FC<StartupHealthViewProps> = ({ startup, userRole, onBack, onActivateFundraising, onInvestorAdded, onUpdateFounders }) => {
    const [activeTab, setActiveTab] = useState<TabId>('dashboard');

    const tabs: { id: TabId; name: string; icon: React.ReactNode }[] = [
        { id: 'dashboard', name: 'Dashboard', icon: <LayoutDashboard className="w-4 h-4" /> },
        { id: 'profile', name: 'Profile', icon: <Building2 className="w-4 h-4" /> },
        { id: 'compliance', name: 'Compliance', icon: <ShieldCheck className="w-4 h-4" /> },
        { id: 'financials', name: 'Financials', icon: <Banknote className="w-4 h-4" /> },
        { id: 'employees', name: 'Employees', icon: <Users className="w-4 h-4" /> },
        { id: 'capTable', name: 'Cap Table', icon: <TableProperties className="w-4 h-4" /> },
    ];

    const renderTabContent = () => {
        switch (activeTab) {
            case 'dashboard':
                return <StartupDashboardTab startup={startup} />;
            case 'profile':
                return <ProfileTab startup={startup} userRole={userRole} />;
            case 'compliance':
                return <ComplianceTab startup={startup} userRole={userRole} />;
            case 'financials':
                return <FinancialsTab startup={startup} userRole={userRole} />;
            case 'employees':
                return <EmployeesTab startup={startup} userRole={userRole} />;
            case 'capTable':
                return <CapTableTab 
                            startup={startup}
                            userRole={userRole}
                            onActivateFundraising={onActivateFundraising}
                            onInvestorAdded={onInvestorAdded}
                            onUpdateFounders={onUpdateFounders}
                        />;
            default:
                return null;
        }
    };
    
  return (
    <div className="min-h-screen bg-slate-50">
        <div className="bg-white shadow-sm border-b">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between items-center py-4">
                    <div className="flex items-center space-x-3">
                        <div className="bg-blue-100 p-2 rounded-lg">
                            <Building2 className="h-6 w-6 text-blue-600" />
                        </div>
                        <div>
                            <h1 className="text-xl font-semibold text-slate-900">{startup.name} Health</h1>
                            <p className="text-sm text-slate-500">Comprehensive startup monitoring dashboard</p>
                        </div>
                    </div>
                    <div className="flex items-center space-x-4">
                        {userRole !== 'Startup' && onBack && (
                            <Button onClick={onBack} variant="secondary">
                                <ArrowLeft className="mr-2 h-4 w-4" />
                                Back to Portfolio
                            </Button>
                        )}
                    </div>
                </div>
            </div>
        </div>

      <Card className="!p-0 sm:!p-0">
        <div className="border-b border-slate-200">
            <nav className="-mb-px flex space-x-1 sm:space-x-4 px-4 overflow-x-auto" aria-label="Tabs">
                {tabs.map(tab => (
                    <button 
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id)} 
                        className={`${activeTab === tab.id ? 'border-brand-primary text-brand-primary' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'} flex items-center whitespace-nowrap py-4 px-1 sm:px-2 border-b-2 font-medium text-sm transition-colors`}
                    >
                       {tab.icon}
                       <span className="ml-2">{tab.name}</span>
                    </button>
                ))}
            </nav>
        </div>
        <div className="p-4 sm:p-6">
            {renderTabContent()}
        </div>
      </Card>
    </div>
  );
};

export default StartupHealthView;