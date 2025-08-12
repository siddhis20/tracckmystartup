import React, { useState } from 'react';
import { Startup, ComplianceStatus, VerificationRequest } from '../types';
import Card from './ui/Card';
import Button from './ui/Button';
import { Shield, CheckCircle, XCircle, AlertTriangle, FileText, Scale } from 'lucide-react';

interface CSViewProps {
  startups: Startup[];
  verificationRequests: VerificationRequest[];
  onProcessVerification: (requestId: number, status: 'approved' | 'rejected') => void;
  onViewStartup: (startup: Startup) => void;
}

const CSView: React.FC<CSViewProps> = ({ 
  startups, 
  verificationRequests, 
  onProcessVerification, 
  onViewStartup 
}) => {
  const [selectedTab, setSelectedTab] = useState<'startups' | 'verifications'>('startups');
  const [searchTerm, setSearchTerm] = useState('');

  const filteredStartups = startups.filter(startup =>
    startup.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    startup.sector.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const pendingVerifications = verificationRequests.filter(req => 
    req.startupName.toLowerCase().includes(searchTerm.toLowerCase())
  );

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
          <h1 className="text-2xl font-bold text-slate-900">CS Legal Panel</h1>
          <p className="text-slate-600">Manage legal compliance and corporate governance</p>
        </div>
        <div className="flex items-center gap-2">
          <Scale className="h-8 w-8 text-blue-600" />
          <span className="text-sm font-medium text-slate-600">Company Secretary</span>
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
              <p className="text-sm font-medium text-slate-600">Pending Verifications</p>
              <p className="text-2xl font-bold text-yellow-600">{verificationRequests.length}</p>
            </div>
            <AlertTriangle className="h-8 w-8 text-yellow-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Legally Compliant</p>
              <p className="text-2xl font-bold text-green-600">
                {startups.filter(s => s.complianceStatus === ComplianceStatus.Compliant).length}
              </p>
            </div>
            <Shield className="h-8 w-8 text-green-500" />
          </div>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-600">Legal Issues</p>
              <p className="text-2xl font-bold text-red-600">
                {startups.filter(s => s.complianceStatus === ComplianceStatus.NonCompliant).length}
              </p>
            </div>
            <XCircle className="h-8 w-8 text-red-500" />
          </div>
        </Card>
      </div>

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
              variant={selectedTab === 'verifications' ? 'primary' : 'secondary'}
              onClick={() => setSelectedTab('verifications')}
            >
              Verifications ({verificationRequests.length})
            </Button>
          </div>
          <div className="flex-1">
            <input
              type="text"
              placeholder={`Search ${selectedTab === 'startups' ? 'startups' : 'verifications'}...`}
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
          <h2 className="text-lg font-semibold text-slate-900">Startup Legal Compliance</h2>
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
                        Investment: ${startup.investmentValue.toLocaleString()}
                      </span>
                      <span className="text-sm text-slate-500">
                        Equity: {startup.equityAllocation}%
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium border ${getComplianceColor(startup.complianceStatus)}`}>
                    {startup.complianceStatus}
                  </span>
                  
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onViewStartup(startup)}
                  >
                    Review Legal
                  </Button>
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
      )}

      {selectedTab === 'verifications' && (
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-slate-900">Verification Requests</h2>
          {pendingVerifications.map((request) => (
            <Card key={request.id} className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <AlertTriangle className="h-5 w-5 text-yellow-500" />
                  <div>
                    <h3 className="text-lg font-semibold text-slate-900">{request.startupName}</h3>
                    <p className="text-sm text-slate-600">Verification Request</p>
                    <p className="text-sm text-slate-500 mt-1">
                      Requested on: {new Date(request.requestDate).toLocaleDateString()}
                    </p>
                  </div>
                </div>
                
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onProcessVerification(request.id, 'approved')}
                    className="text-green-600 border-green-600 hover:bg-green-50"
                  >
                    Approve
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onProcessVerification(request.id, 'rejected')}
                    className="text-red-600 border-red-600 hover:bg-red-50"
                  >
                    Reject
                  </Button>
                </div>
              </div>
            </Card>
          ))}
          
          {pendingVerifications.length === 0 && (
            <Card className="p-8 text-center">
              <Shield className="h-12 w-12 text-slate-400 mx-auto mb-4" />
              <p className="text-slate-600">No verification requests found</p>
            </Card>
          )}
        </div>
      )}
    </div>
  );
};

export default CSView;
