import React, { useState, useEffect } from 'react';
import { DocumentVerificationStatus as VerificationStatus } from '../types';
import { documentVerificationService } from '../lib/documentVerificationService';
import { 
    CheckCircle, 
    XCircle, 
    Clock, 
    AlertTriangle, 
    RefreshCw,
    Shield,
    FileText
} from 'lucide-react';

interface DocumentVerificationStatusProps {
    documentId: string;
    showLabel?: boolean;
    showIcon?: boolean;
    size?: 'sm' | 'md' | 'lg';
    className?: string;
}

const DocumentVerificationStatus: React.FC<DocumentVerificationStatusProps> = ({
    documentId,
    showLabel = true,
    showIcon = true,
    size = 'md',
    className = ''
}) => {
    const [status, setStatus] = useState<VerificationStatus>(VerificationStatus.Pending);
    const [isLoading, setIsLoading] = useState(true);
    const [verificationDetails, setVerificationDetails] = useState<any>(null);

    useEffect(() => {
        loadVerificationStatus();
    }, [documentId]);

    const loadVerificationStatus = async () => {
        try {
            setIsLoading(true);
            const [statusResult, detailsResult] = await Promise.all([
                documentVerificationService.getDocumentVerificationStatus(documentId),
                documentVerificationService.getDocumentVerification(documentId)
            ]);
            
            setStatus(statusResult);
            setVerificationDetails(detailsResult);
        } catch (error) {
            console.error('Error loading verification status:', error);
            setStatus(VerificationStatus.Pending);
        } finally {
            setIsLoading(false);
        }
    };

    const getStatusConfig = (status: VerificationStatus) => {
        switch (status) {
            case VerificationStatus.Verified:
                return {
                    icon: CheckCircle,
                    color: 'text-green-600',
                    bgColor: 'bg-green-100',
                    label: 'Verified',
                    description: 'Document has been verified'
                };
            case VerificationStatus.Rejected:
                return {
                    icon: XCircle,
                    color: 'text-red-600',
                    bgColor: 'bg-red-100',
                    label: 'Rejected',
                    description: 'Document verification failed'
                };
            case VerificationStatus.Pending:
                return {
                    icon: Clock,
                    color: 'text-yellow-600',
                    bgColor: 'bg-yellow-100',
                    label: 'Pending',
                    description: 'Awaiting verification'
                };
            case VerificationStatus.Expired:
                return {
                    icon: AlertTriangle,
                    color: 'text-orange-600',
                    bgColor: 'bg-orange-100',
                    label: 'Expired',
                    description: 'Verification has expired'
                };
            case VerificationStatus.UnderReview:
                return {
                    icon: RefreshCw,
                    color: 'text-blue-600',
                    bgColor: 'bg-blue-100',
                    label: 'Under Review',
                    description: 'Document is being reviewed'
                };
            default:
                return {
                    icon: FileText,
                    color: 'text-gray-600',
                    bgColor: 'bg-gray-100',
                    label: 'Unknown',
                    description: 'Verification status unknown'
                };
        }
    };

    const getSizeClasses = (size: string) => {
        switch (size) {
            case 'sm':
                return {
                    icon: 'w-3 h-3',
                    text: 'text-xs',
                    padding: 'px-1.5 py-0.5'
                };
            case 'lg':
                return {
                    icon: 'w-6 h-6',
                    text: 'text-base',
                    padding: 'px-3 py-1.5'
                };
            default: // md
                return {
                    icon: 'w-4 h-4',
                    text: 'text-sm',
                    padding: 'px-2 py-1'
                };
        }
    };

    if (isLoading) {
        return (
            <div className={`inline-flex items-center ${className}`}>
                <RefreshCw className={`${getSizeClasses(size).icon} animate-spin text-gray-400`} />
                {showLabel && (
                    <span className={`ml-1 ${getSizeClasses(size).text} text-gray-500`}>
                        Loading...
                    </span>
                )}
            </div>
        );
    }

    const config = getStatusConfig(status);
    const sizeClasses = getSizeClasses(size);
    const IconComponent = config.icon;

    return (
        <div className={`inline-flex items-center ${className}`}>
            <span 
                className={`inline-flex items-center ${sizeClasses.padding} rounded-full ${config.bgColor} ${config.color} ${sizeClasses.text} font-medium`}
                title={config.description}
            >
                {showIcon && <IconComponent className={`${sizeClasses.icon} mr-1`} />}
                {showLabel && config.label}
            </span>
            
            {/* Additional info tooltip */}
            {verificationDetails && (
                <div className="ml-2 text-xs text-gray-500">
                    {verificationDetails.verifiedBy && (
                        <div>By: {verificationDetails.verifiedBy}</div>
                    )}
                    {verificationDetails.verifiedAt && (
                        <div>
                            {new Date(verificationDetails.verifiedAt).toLocaleDateString()}
                        </div>
                    )}
                    {verificationDetails.expiryDate && (
                        <div>
                            Expires: {new Date(verificationDetails.expiryDate).toLocaleDateString()}
                        </div>
                    )}
                </div>
            )}
        </div>
    );
};

// Compact version for tables and lists
export const DocumentVerificationBadge: React.FC<{
    documentId: string;
    className?: string;
}> = ({ documentId, className = '' }) => {
    return (
        <DocumentVerificationStatus
            documentId={documentId}
            showLabel={true}
            showIcon={true}
            size="sm"
            className={className}
        />
    );
};

// Icon-only version for minimal display
export const DocumentVerificationIcon: React.FC<{
    documentId: string;
    className?: string;
}> = ({ documentId, className = '' }) => {
    return (
        <DocumentVerificationStatus
            documentId={documentId}
            showLabel={false}
            showIcon={true}
            size="sm"
            className={className}
        />
    );
};

// Full version with all details
export const DocumentVerificationFull: React.FC<{
    documentId: string;
    className?: string;
}> = ({ documentId, className = '' }) => {
    return (
        <DocumentVerificationStatus
            documentId={documentId}
            showLabel={true}
            showIcon={true}
            size="lg"
            className={className}
        />
    );
};

export default DocumentVerificationStatus;

