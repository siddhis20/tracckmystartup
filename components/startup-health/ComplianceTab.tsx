import React, { useState } from 'react';
import { Startup } from '../../types';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import { CheckCircle, XCircle, Clock, AlertTriangle, Edit3, Save, X } from 'lucide-react';

interface ComplianceTabProps {
  startup: Startup;
  userRole?: string;
}

// Dynamic data generation based on startup
const generateComplianceRequirements = (startup: Startup) => {
  const sector = startup.sector || 'Technology';
  const totalFunding = startup.totalFunding || 1000000;
  
  const baseRequirements = [
    { id: 'tax', name: 'Tax Compliance', status: 'compliant', dueDate: '2024-12-31', description: 'Annual tax filing and payments' },
    { id: 'regulatory', name: 'Regulatory Compliance', status: 'pending', dueDate: '2024-10-15', description: 'Industry-specific regulations' },
    { id: 'data', name: 'Data Protection', status: 'compliant', dueDate: '2024-12-31', description: 'GDPR, CCPA compliance' }
  ];
  
  // Add sector-specific requirements
  if (sector === 'FinTech') {
    baseRequirements.push(
      { id: 'fintech', name: 'Financial Regulations', status: 'pending', dueDate: '2024-09-30', description: 'SEC, FINRA compliance' },
      { id: 'aml', name: 'AML/KYC', status: 'non-compliant', dueDate: '2024-08-15', description: 'Anti-money laundering checks' }
    );
  } else if (sector === 'HealthTech') {
    baseRequirements.push(
      { id: 'hipaa', name: 'HIPAA Compliance', status: 'pending', dueDate: '2024-09-30', description: 'Patient data protection' },
      { id: 'fda', name: 'FDA Regulations', status: 'non-compliant', dueDate: '2024-08-15', description: 'Medical device approvals' }
    );
  }
  
  // Add funding-based requirements
  if (totalFunding > 5000000) {
    baseRequirements.push(
      { id: 'sox', name: 'SOX Compliance', status: 'pending', dueDate: '2024-11-30', description: 'Sarbanes-Oxley requirements' }
    );
  }
  
  return baseRequirements;
};

const generateComplianceScore = (startup: Startup) => {
  const requirements = generateComplianceRequirements(startup);
  const compliant = requirements.filter(r => r.status === 'compliant').length;
  const total = requirements.length;
  return Math.round((compliant / total) * 100);
};

const getStatusIcon = (status: string) => {
  switch (status) {
    case 'compliant':
      return <CheckCircle className="h-5 w-5 text-green-500" />;
    case 'pending':
      return <Clock className="h-5 w-5 text-yellow-500" />;
    case 'non-compliant':
      return <XCircle className="h-5 w-5 text-red-500" />;
    default:
      return <AlertTriangle className="h-5 w-5 text-gray-500" />;
  }
};

const getStatusColor = (status: string) => {
  switch (status) {
    case 'compliant':
      return 'text-green-600 bg-green-50 border-green-200';
    case 'pending':
      return 'text-yellow-600 bg-yellow-50 border-yellow-200';
    case 'non-compliant':
      return 'text-red-600 bg-red-50 border-red-200';
    default:
      return 'text-gray-600 bg-gray-50 border-gray-200';
  }
};

const ComplianceTab: React.FC<ComplianceTabProps> = ({ startup, userRole }) => {
    const [isEditing, setIsEditing] = useState(false);
    const canEdit = userRole === 'Startup';
    
    // Generate dynamic data based on startup
    const complianceRequirements = generateComplianceRequirements(startup);
    const complianceScore = generateComplianceScore(startup);

    return (
        <div className="space-y-6">
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Compliance Overview</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="bg-white p-6 rounded-lg shadow-sm">
                        <h4 className="text-md font-semibold mb-2 text-slate-700">Compliance Score</h4>
                        <div className="flex items-center">
                            <span className="text-4xl font-bold text-slate-900">{complianceScore}%</span>
                            <span className="ml-2 text-sm text-slate-500">Overall Compliance</span>
                        </div>
                        <p className="mt-2 text-sm text-slate-500">Based on your startup's sector and funding level.</p>
                    </div>
                    <div className="bg-white p-6 rounded-lg shadow-sm">
                        <h4 className="text-md font-semibold mb-2 text-slate-700">Key Compliance Areas</h4>
                        <ul className="space-y-2">
                            {complianceRequirements.map(req => (
                                <li key={req.id} className="flex items-center text-sm text-slate-900">
                                    <span className={`mr-2 ${getStatusColor(req.status)} rounded-full p-1`}>
                                        {getStatusIcon(req.status)}
                                    </span>
                                    {req.name}
                                    <span className="ml-2 text-xs text-slate-500">Due: {req.dueDate}</span>
                                </li>
                            ))}
                        </ul>
                    </div>
                </div>
            </Card>

            {canEdit && (
                <Card>
                    <h3 className="text-lg font-semibold mb-4 text-slate-700">Edit Compliance Requirements</h3>
                    <form className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <Select label="Sector" id="sector" value={startup.sector || ''} onChange={e => setStartup({ ...startup, sector: e.target.value })}>
                            <option value="Technology">Technology</option>
                            <option value="FinTech">FinTech</option>
                            <option value="HealthTech">HealthTech</option>
                            <option value="Other">Other</option>
                        </Select>
                        <Input label="Total Funding (USD)" id="total-funding" type="number" value={startup.totalFunding || ''} onChange={e => setStartup({ ...startup, totalFunding: Number(e.target.value) })} />
                        <div className="md:col-span-2">
                            <Button type="submit" onClick={() => setIsEditing(false)}>
                                <Save className="h-4 w-4 mr-2" /> Save Changes
                            </Button>
                        </div>
                    </form>
                </Card>
            )}
        </div>
    );
};

export default ComplianceTab;