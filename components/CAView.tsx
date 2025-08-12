import React, { useState } from 'react';
import { Startup, ComplianceStatus, FinancialRecord } from '../types';
import Card from './ui/Card';
import Button from './ui/Button';
import { FileText, CheckCircle, XCircle, AlertTriangle, TrendingUp, DollarSign } from 'lucide-react';

interface CAViewProps {
  startups: Startup[];
  onUpdateCompliance: (startupId: number, status: ComplianceStatus) => void;
  onViewStartup: (startup: Startup) => void;
}

const CAView: React.FC<CAViewProps> = ({ startups, onUpdateCompliance, onViewStartup }) => {
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'pending' | 'compliant' | 'non-compliant'>('all');
  const [searchTerm, setSearchTerm] = useState('');

  const filteredStartups = startups.filter(startup => {
    const matchesFilter = selectedFilter === 'all' || 
      (selectedFilter === 'pending' && startup.complianceStatus === ComplianceStatus.Pending) ||
      (selectedFilter === 'compliant' && startup.complianceStatus === ComplianceStatus.Compliant) ||
      (selectedFilter === 'non-compliant' && startup.complianceStatus === ComplianceStatus.NonCompliant);
    
    const matchesSearch = startup.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         startup.sector.toLowerCase().includes(searchTerm.toLowerCase());
    
    return matchesFilter && matchesSearch;
  });

  const getComplianceIcon = (status: ComplianceStatus) => {
    switch (status) {
      case ComplianceStatus.Compliant:
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case ComplianceStatus.NonCompliant:
        return <XCircle className="h-5 w-5 text-red-500" />;
      case ComplianceStatus.Pending:
        return <AlertTriangle className="h-5 w-5 text-yellow-500" />;
      default:
        return <FileText className="h-5 w-5 text-gray-500" />;
    }
  };

  const getComplianceColor = (status: ComplianceStatus) => {
    switch (status) {
      case ComplianceStatus.Compliant:
        return 'text-green-700 bg-green-50 border-green-200';
      case ComplianceStatus.NonCompliant:
        return 'text-red-700 bg-red-50 border-red-200';
      case ComplianceStatus.Pending:
        return 'text-yellow-700 bg-yellow-50 border-yellow-200';
      default:
        return 'text-gray-700 bg-gray-50 border-gray-200';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">CA Compliance Panel</h1>
          <p className="text-slate-600">Manage financial compliance and audit requirements</p>
        </div>
        <div className="flex items-center gap-2">
          <DollarSign className="h-8 w-8 text-green-600" />
          <span className="text-sm font-medium text-slate-600">Chartered Accountant</span>
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
            <FileText className="h-8 w-8 text-blue-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Pending Review</p>
              <p className="text-2xl font-bold text-yellow-600">
                {startups.filter(s => s.complianceStatus === ComplianceStatus.Pending).length}
              </p>
            </div>
            <AlertTriangle className="h-8 w-8 text-yellow-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Compliant</p>
              <p className="text-2xl font-bold text-green-600">
                {startups.filter(s => s.complianceStatus === ComplianceStatus.Compliant).length}
              </p>
            </div>
            <CheckCircle className="h-8 w-8 text-green-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Non-Compliant</p>
              <p className="text-2xl font-bold text-red-600">
                {startups.filter(s => s.complianceStatus === ComplianceStatus.NonCompliant).length}
              </p>
            </div>
            <XCircle className="h-8 w-8 text-red-500" />
          </div>
        </Card>
      </div>

      {/* Filters */}
      <Card className="p-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <input
              type="text"
              placeholder="Search startups..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary"
            />
          </div>
          <div className="flex gap-2">
            <Button
              variant={selectedFilter === 'all' ? 'primary' : 'secondary'}
              onClick={() => setSelectedFilter('all')}
            >
              All
            </Button>
            <Button
              variant={selectedFilter === 'pending' ? 'primary' : 'secondary'}
              onClick={() => setSelectedFilter('pending')}
            >
              Pending
            </Button>
            <Button
              variant={selectedFilter === 'compliant' ? 'primary' : 'secondary'}
              onClick={() => setSelectedFilter('compliant')}
            >
              Compliant
            </Button>
            <Button
              variant={selectedFilter === 'non-compliant' ? 'primary' : 'secondary'}
              onClick={() => setSelectedFilter('non-compliant')}
            >
              Non-Compliant
            </Button>
          </div>
        </div>
      </Card>

      {/* Startups List */}
      <div className="space-y-4">
        {filteredStartups.map((startup) => (
          <Card key={startup.id} className="p-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                {getComplianceIcon(startup.complianceStatus)}
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
                  </div>
                </div>
              </div>
              
              <div className="flex items-center gap-3">
                <span className={`px-3 py-1 rounded-full text-sm font-medium border ${getComplianceColor(startup.complianceStatus)}`}>
                  {startup.complianceStatus}
                </span>
                
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onViewStartup(startup)}
                  >
                    View Details
                  </Button>
                  
                  {startup.complianceStatus === ComplianceStatus.Pending && (
                    <>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => onUpdateCompliance(startup.id, ComplianceStatus.Compliant)}
                        className="text-green-600 border-green-600 hover:bg-green-50"
                      >
                        Approve
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => onUpdateCompliance(startup.id, ComplianceStatus.NonCompliant)}
                        className="text-red-600 border-red-600 hover:bg-red-50"
                      >
                        Reject
                      </Button>
                    </>
                  )}
                </div>
              </div>
            </div>
          </Card>
        ))}
        
        {filteredStartups.length === 0 && (
          <Card className="p-8 text-center">
            <FileText className="h-12 w-12 text-slate-400 mx-auto mb-4" />
            <p className="text-slate-600">No startups found matching your criteria</p>
          </Card>
        )}
      </div>
    </div>
  );
};

export default CAView;
