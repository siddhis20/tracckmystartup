import React, { useState } from 'react';
import { Startup, NewInvestment, InvestmentOffer } from '../types';
import Card from './ui/Card';
import Button from './ui/Button';
import AddStartupModal from './AddStartupModal';
import { 
  Building2, 
  TrendingUp, 
  Users, 
  FileText, 
  DollarSign, 
  BarChart3,
  Eye,
  Plus,
  Upload,
  Settings
} from 'lucide-react';

interface StartupViewProps {
  startups: Startup[];
  newInvestments: NewInvestment[];
  investmentOffers: InvestmentOffer[];
  onViewStartup: (startup: Startup) => void;
  onMakeOffer: (investmentId: number, offerAmount: number, equityPercentage: number) => void;
}

const StartupView: React.FC<StartupViewProps> = ({
  startups,
  newInvestments,
  investmentOffers,
  onViewStartup,
  onMakeOffer
}) => {
  const [selectedTab, setSelectedTab] = useState<'overview' | 'investments' | 'offers' | 'documents'>('overview');
  const [isAddStartupModalOpen, setIsAddStartupModalOpen] = useState(false);

  // Since we're now filtering by user_id in the database, all startups returned are for the current user
  const userStartups = startups;

  // Auto-select the first startup for startup users
  React.useEffect(() => {
    if (userStartups.length === 1) {
      onViewStartup(userStartups[0]);
    }
  }, [userStartups, onViewStartup]);

  const userInvestments = newInvestments.filter(investment => 
    userStartups.some(startup => startup.name === investment.name)
  );

  const userOffers = investmentOffers.filter(offer => 
    userStartups.some(startup => startup.name === offer.startup_name)
  );

  const totalFunding = userStartups.reduce((sum, startup) => sum + startup.total_funding, 0);
  const totalRevenue = userStartups.reduce((sum, startup) => sum + startup.total_revenue, 0);
  const averageValuation = userStartups.length > 0 
    ? userStartups.reduce((sum, startup) => sum + startup.current_valuation, 0) / userStartups.length 
    : 0;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Startup Dashboard</h1>
          <p className="text-slate-600 mt-1">Manage your startup portfolio and investments</p>
        </div>
        <div className="flex gap-3">
          <Button onClick={() => setSelectedTab('documents')} className="flex items-center gap-2">
            <Upload className="h-4 w-4" />
            Upload Documents
          </Button>
          <Button onClick={() => setIsAddStartupModalOpen(true)} className="flex items-center gap-2">
            <Plus className="h-4 w-4" />
            Add Startup
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Total Startups</p>
              <p className="text-2xl font-bold text-slate-900">{userStartups.length}</p>
            </div>
            <Building2 className="h-8 w-8 text-brand-primary" />
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Total Funding</p>
              <p className="text-2xl font-bold text-slate-900">₹{totalFunding.toLocaleString()}L</p>
            </div>
            <DollarSign className="h-8 w-8 text-green-500" />
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Total Revenue</p>
              <p className="text-2xl font-bold text-slate-900">₹{totalRevenue.toLocaleString()}L</p>
            </div>
            <TrendingUp className="h-8 w-8 text-blue-500" />
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Avg Valuation</p>
              <p className="text-2xl font-bold text-slate-900">₹{averageValuation.toLocaleString()}L</p>
            </div>
            <BarChart3 className="h-8 w-8 text-purple-500" />
          </div>
        </Card>
      </div>

      {/* Tabs */}
      <div className="border-b border-slate-200">
        <nav className="flex space-x-8">
          <button
            onClick={() => setSelectedTab('overview')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              selectedTab === 'overview'
                ? 'border-brand-primary text-brand-primary'
                : 'border-transparent text-slate-500 hover:text-slate-700'
            }`}
          >
            Overview
          </button>
          <button
            onClick={() => setSelectedTab('investments')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              selectedTab === 'investments'
                ? 'border-brand-primary text-brand-primary'
                : 'border-transparent text-slate-500 hover:text-slate-700'
            }`}
          >
            Investments ({userInvestments.length})
          </button>
          <button
            onClick={() => setSelectedTab('offers')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              selectedTab === 'offers'
                ? 'border-brand-primary text-brand-primary'
                : 'border-transparent text-slate-500 hover:text-slate-700'
            }`}
          >
            Offers ({userOffers.length})
          </button>
          <button
            onClick={() => setSelectedTab('documents')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              selectedTab === 'documents'
                ? 'border-brand-primary text-brand-primary'
                : 'border-transparent text-slate-500 hover:text-slate-700'
            }`}
          >
            Documents
          </button>
        </nav>
      </div>

      {/* Tab Content */}
      <div className="mt-6">
        {selectedTab === 'overview' && (
          <div className="space-y-6">
            <h2 className="text-xl font-semibold text-slate-900">Your Startups</h2>
            {userStartups.length === 0 ? (
              <Card className="p-8 text-center">
                <Building2 className="h-12 w-12 text-slate-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-slate-900 mb-2">No Startups Found</h3>
                <p className="text-slate-600 mb-4">You haven't registered any startups yet.</p>
                <Button onClick={() => setSelectedTab('overview')} className="flex items-center gap-2 mx-auto">
                  <Plus className="h-4 w-4" />
                  Add Your First Startup
                </Button>
              </Card>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {userStartups.map((startup) => (
                  <Card key={startup.id} className="p-6 hover:shadow-lg transition-shadow">
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        <h3 className="text-lg font-semibold text-slate-900">{startup.name}</h3>
                        <p className="text-sm text-slate-600">{startup.sector}</p>
                      </div>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                        startup.compliance_status === 'Compliant' 
                          ? 'bg-green-100 text-green-800'
                          : startup.compliance_status === 'Pending'
                          ? 'bg-yellow-100 text-yellow-800'
                          : 'bg-red-100 text-red-800'
                      }`}>
                        {startup.compliance_status}
                      </span>
                    </div>
                    
                    <div className="space-y-2 mb-4">
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-600">Valuation:</span>
                        <span className="font-medium">₹{startup.current_valuation}L</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-600">Funding:</span>
                        <span className="font-medium">₹{startup.total_funding}L</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-600">Revenue:</span>
                        <span className="font-medium">₹{startup.total_revenue}L</span>
                      </div>
                    </div>
                    
                    <Button 
                      onClick={() => onViewStartup(startup)}
                      className="w-full flex items-center justify-center gap-2"
                    >
                      <Eye className="h-4 w-4" />
                      View Details
                    </Button>
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}

        {selectedTab === 'investments' && (
          <div className="space-y-6">
            <h2 className="text-xl font-semibold text-slate-900">Investment Opportunities</h2>
            {userInvestments.length === 0 ? (
              <Card className="p-8 text-center">
                <TrendingUp className="h-12 w-12 text-slate-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-slate-900 mb-2">No Investment Opportunities</h3>
                <p className="text-slate-600">No investment opportunities available for your startups.</p>
              </Card>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {userInvestments.map((investment) => (
                  <Card key={investment.id} className="p-6">
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        <h3 className="text-lg font-semibold text-slate-900">{investment.name}</h3>
                        <p className="text-sm text-slate-600">{investment.sector}</p>
                      </div>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                        investment.compliance_status === 'Compliant' 
                          ? 'bg-green-100 text-green-800'
                          : 'bg-yellow-100 text-yellow-800'
                      }`}>
                        {investment.compliance_status}
                      </span>
                    </div>
                    
                    <div className="space-y-2 mb-4">
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-600">Investment Value:</span>
                        <span className="font-medium">₹{investment.investment_value}L</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-600">Equity Allocation:</span>
                        <span className="font-medium">{investment.equity_allocation}%</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-600">Type:</span>
                        <span className="font-medium">{investment.investment_type}</span>
                      </div>
                    </div>
                    
                    <Button className="w-full">
                      View Details
                    </Button>
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}

        {selectedTab === 'offers' && (
          <div className="space-y-6">
            <h2 className="text-xl font-semibold text-slate-900">Investment Offers</h2>
            {userOffers.length === 0 ? (
              <Card className="p-8 text-center">
                <DollarSign className="h-12 w-12 text-slate-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-slate-900 mb-2">No Offers Received</h3>
                <p className="text-slate-600">No investment offers have been made for your startups.</p>
              </Card>
            ) : (
              <div className="space-y-4">
                {userOffers.map((offer) => (
                  <Card key={offer.id} className="p-6">
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        <h3 className="text-lg font-semibold text-slate-900">{offer.startup_name}</h3>
                        <p className="text-sm text-slate-600">From: {offer.investor_email}</p>
                      </div>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                        offer.status === 'accepted' 
                          ? 'bg-green-100 text-green-800'
                          : offer.status === 'pending'
                          ? 'bg-yellow-100 text-yellow-800'
                          : 'bg-red-100 text-red-800'
                      }`}>
                        {offer.status}
                      </span>
                    </div>
                    
                    <div className="grid grid-cols-2 gap-4 mb-4">
                      <div>
                        <p className="text-sm text-slate-600">Offer Amount</p>
                        <p className="text-lg font-semibold text-slate-900">₹{offer.offer_amount}L</p>
                      </div>
                      <div>
                        <p className="text-sm text-slate-600">Equity Percentage</p>
                        <p className="text-lg font-semibold text-slate-900">{offer.equity_percentage}%</p>
                      </div>
                    </div>
                    
                    <div className="flex gap-2">
                      <Button className="flex-1 bg-green-600 hover:bg-green-700">
                        Accept
                      </Button>
                      <Button className="flex-1 bg-red-600 hover:bg-red-700">
                        Decline
                      </Button>
                    </div>
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}

        {selectedTab === 'documents' && (
          <div className="space-y-6">
            <h2 className="text-xl font-semibold text-slate-900">Document Management</h2>
            <Card className="p-8 text-center">
              <FileText className="h-12 w-12 text-slate-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-slate-900 mb-2">Upload Your Documents</h3>
              <p className="text-slate-600 mb-4">Upload your startup documents, pitch decks, and other important files.</p>
              <div className="flex gap-3 justify-center">
                <Button className="flex items-center gap-2">
                  <Upload className="h-4 w-4" />
                  Upload Pitch Deck
                </Button>
                <Button className="flex items-center gap-2">
                  <Upload className="h-4 w-4" />
                  Upload Financial Documents
                </Button>
                <Button className="flex items-center gap-2">
                  <Upload className="h-4 w-4" />
                  Upload Legal Documents
                </Button>
              </div>
            </Card>
          </div>
        )}
      </div>

      {/* Add Startup Modal */}
      <AddStartupModal
        isOpen={isAddStartupModalOpen}
        onClose={() => setIsAddStartupModalOpen(false)}
        onStartupAdded={() => {
          // Refresh the startups list
          window.location.reload();
        }}
      />
    </div>
  );
};

export default StartupView;
