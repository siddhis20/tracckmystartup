
import React from 'react';
import { ComplianceStatus } from '../../types';

interface BadgeProps {
  status: ComplianceStatus;
}

const Badge: React.FC<BadgeProps> = ({ status }) => {
  const statusStyles: Record<ComplianceStatus, string> = {
    [ComplianceStatus.Compliant]: 'bg-green-100 text-status-compliant',
    [ComplianceStatus.Pending]: 'bg-orange-100 text-status-pending',
    [ComplianceStatus.NonCompliant]: 'bg-red-100 text-status-noncompliant',
  };

  return (
    <span className={`px-2.5 py-0.5 text-xs font-medium rounded-full inline-block ${statusStyles[status]}`}>
      {status}
    </span>
  );
};

export default Badge;
