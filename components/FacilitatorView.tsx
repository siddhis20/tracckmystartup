import React, { useState } from 'react';
import { Startup, NewInvestment, StartupAdditionRequest } from '../types';
import Card from './ui/Card';
import Button from './ui/Button';
import { Building2, TrendingUp, Users, Target, FileText, Lightbulb } from 'lucide-react';

interface FacilitatorViewProps {
  startups: Startup[];
  newInvestments: NewInvestment[];
  startupAdditionRequests: StartupAdditionRequest[];
  onViewStartup: (startup: Startup) => void;
  onAcceptRequest: (requestId: number) => void;
}

const FacilitatorView: React.FC<FacilitatorViewProps> = ({ 
  startups, 
  newInvestments, 
  startupAdditionRequests, 
  onViewStartup, 
  onAcceptRequest 
}) => {
  const [selectedTab, setSelectedTab] = useState<'startups' | 'investments' | 'requests'>('startups');
  const [searchTerm, setSearchTerm] = useState('');

  const filteredStartups = startups.filter(startup =>
    startup.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    startup.sector.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredInvestments = newInvestments.filter(investment =>
    investment.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    investment.sector.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredRequests = startupAdditionRequests.filter(request =>
    request.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    request.sector.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getSectorStats = () => {
    const sectorCounts: { [key: string]: number } = {};
    startups.forEach(startup => {
      sectorCounts[startup.sector] = (sectorCounts[startup.sector] || 0) + 1;
    });
    return sectorCounts;
  };

  const sectorStats = getSectorStats();

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Startup Facilitation Center</h1>
          <p className="text-slate-600">Supporting startups with resources and guidance</p>
        </div>
        <div className="flex items-center gap-2">
          <Lightbulb className="h-8 w-8 text-purple-600" />
          <span className="text-sm font-medium text-slate-600">Facilitator</span>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Total Startups</p>
              <p className="text-2xl font-bold text-slate-900">{startups.length}</p>
            </div>
            <Building2 className="h-8 w-8 text-blue-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Active Investments</p>
              <p className="text-2xl font-bold text-green-600">{newInvestments.length}</p>
            </div>
            <TrendingUp className="h-8 w-8 text-green-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Pending Requests</p>
              <p className="text-2xl font-bold text-yellow-600">{startupAdditionRequests.length}</p>
            </div>
            <Users className="h-8 w-8 text-yellow-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Top Sector</p>
              <p className="text-lg font-bold text-purple-600">
                {Object.keys(sectorStats).length > 0 
                  ? Object.entries(sectorStats).sort(([,a], [,b]) => b - a)[0][0]
                  : 'N/A'
                }
              </p>
            </div>
            <Target className="h-8 w-8 text-purple-500" />
          </div>
        </Card>
      </div>

      {/* Sector Distribution */}
      <Card className="p-6">
        <h2 className="text-lg font-semibold text-slate-900 mb-4">Sector Distribution</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {Object.entries(sectorStats).map(([sector, count]) => (
            <div key={sector} className="text-center p-3 bg-slate-50 rounded-lg">
              <p className="text-sm font-medium text-slate-600">{sector}</p>
              <p className="text-xl font-bold text-slate-900">{count}</p>
            </div>
          ))}
        </div>
      </Card>

      {/* Tabs */}
      <Card className="p-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex gap-2">
            <Button
              variant={selectedTab === 'startups' ? 'primary' : 'secondary'}
              onClick={() => setSelectedTab('startups')}
            >
              Startups ({startups.length})
            </Button>
            <Button
              variant={selectedTab === 'investments' ? 'primary' : 'secondary'}
              onClick={() => setSelectedTab('investments')}
            >
              Investments ({newInvestments.length})
            </Button>
            <Button
              variant={selectedTab === 'requests' ? 'primary' : 'secondary'}
              onClick={() => setSelectedTab('requests')}
            >
              Requests ({startupAdditionRequests.length})
            </Button>
          </div>
          <div className="flex-1">
            <input
              type="text"
              placeholder={`Search ${selectedTab}...`}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary"
            />
          </div>
        </div>
      </Card>

      {/* Content */}
      {selectedTab === 'startups' && (
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-slate-900">Startup Portfolio</h2>
          {filteredStartups.map((startup) => (
            <Card key={startup.id} className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <Building2 className="h-5 w-5 text-blue-500" />
                  <div>
                    <h3 className="text-lg font-semibold text-slate-900">{startup.name}</h3>
                    <p className="text-sm text-slate-600">{startup.sector}</p>
                    <div className="flex items-center gap-4 mt-2">
                      <span className="text-sm text-slate-500">
                        Funding: ${startup.totalFunding.toLocaleString()}
                      </span>
                      <span className="text-sm text-slate-500">
                        Revenue: ${startup.totalRevenue.toLocaleString()}
                      </span>
                      <span className="text-sm text-slate-500">
                        Stage: {startup.investmentType}
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                    startup.complianceStatus === 'Compliant' 
                      ? 'text-green-700 bg-green-50 border border-green-200'
                      : startup.complianceStatus === 'Pending'
                      ? 'text-yellow-700 bg-yellow-50 border border-yellow-200'
                      : 'text-red-700 bg-red-50 border border-red-200'
                  }`}>
                    {startup.complianceStatus}
                  </span>
                  
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onViewStartup(startup)}
                  >
                    Support
                  </Button>
                </div>
              </div>
            </Card>
          ))}
          
          {filteredStartups.length === 0 && (
            <Card className="p-8 text-center">
              <Building2 className="h-12 w-12 text-slate-400 mx-auto mb-4" />
              <p className="text-slate-600">No startups found matching your criteria</p>
            </Card>
          )}
        </div>
      )}

      {selectedTab === 'investments' && (
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-slate-900">Investment Opportunities</h2>
          {filteredInvestments.map((investment) => (
            <Card key={investment.id} className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <TrendingUp className="h-5 w-5 text-green-500" />
                  <div>
                    <h3 className="text-lg font-semibold text-slate-900">{investment.name}</h3>
                    <p className="text-sm text-slate-600">{investment.sector}</p>
                    <div className="flex items-center gap-4 mt-2">
                      <span className="text-sm text-slate-500">
                        Investment: ${investment.investmentValue.toLocaleString()}
                      </span>
                      <span className="text-sm text-slate-500">
                        Equity: {investment.equityAllocation}%
                      </span>
                      <span className="text-sm text-slate-500">
                        Stage: {investment.investmentType}
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                    investment.complianceStatus === 'Compliant' 
                      ? 'text-green-700 bg-green-50 border border-green-200'
                      : 'text-yellow-700 bg-yellow-50 border border-yellow-200'
                  }`}>
                    {investment.complianceStatus}
                  </span>
                  
                  <Button
                    variant="outline"
                    size="sm"
                  >
                    Facilitate
                  </Button>
                </div>
              </div>
            </Card>
          ))}
          
          {filteredInvestments.length === 0 && (
            <Card className="p-8 text-center">
              <TrendingUp className="h-12 w-12 text-slate-400 mx-auto mb-4" />
              <p className="text-slate-600">No investment opportunities found</p>
            </Card>
          )}
        </div>
      )}

      {selectedTab === 'requests' && (
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-slate-900">Startup Addition Requests</h2>
          {filteredRequests.map((request) => (
            <Card key={request.id} className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <Users className="h-5 w-5 text-purple-500" />
                  <div>
                    <h3 className="text-lg font-semibold text-slate-900">{request.name}</h3>
                    <p className="text-sm text-slate-600">{request.sector}</p>
                    <div className="flex items-center gap-4 mt-2">
                      <span className="text-sm text-slate-500">
                        Investment: ${request.investmentValue.toLocaleString()}
                      </span>
                      <span className="text-sm text-slate-500">
                        Equity: {request.equityAllocation}%
                      </span>
                      <span className="text-sm text-slate-500">
                        Stage: {request.investmentType}
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onAcceptRequest(request.id)}
                    className="text-green-600 border-green-600 hover:bg-green-50"
                  >
                    Facilitate
                  </Button>
                </div>
              </div>
            </Card>
          ))}
          
          {filteredRequests.length === 0 && (
            <Card className="p-8 text-center">
              <Users className="h-12 w-12 text-slate-400 mx-auto mb-4" />
              <p className="text-slate-600">No requests found</p>
            </Card>
          )}
        </div>
      )}
    </div>
  );
};

export default FacilitatorView;
