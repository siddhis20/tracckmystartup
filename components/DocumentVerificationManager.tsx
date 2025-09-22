import React, { useState, useEffect } from 'react';
import { 
    DocumentVerification, 
    DocumentVerificationStatus, 
    DocumentVerificationRule,
    VerifyDocumentData,
    UserRole
} from '../types';
import { documentVerificationService } from '../lib/documentVerificationService';
import { 
    CheckCircle, 
    XCircle, 
    Clock, 
    AlertTriangle, 
    Eye, 
    FileText, 
    Calendar,
    User,
    MessageSquare,
    Shield,
    RefreshCw
} from 'lucide-react';
import Card from './ui/Card';
import Button from './ui/Button';
import Modal from './ui/Modal';

interface DocumentVerificationManagerProps {
    userRole?: UserRole;
    userEmail?: string;
    onVerificationUpdate?: () => void;
}

const DocumentVerificationManager: React.FC<DocumentVerificationManagerProps> = ({
    userRole,
    userEmail,
    onVerificationUpdate
}) => {
    const [verifications, setVerifications] = useState<DocumentVerification[]>([]);
    const [rules, setRules] = useState<DocumentVerificationRule[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [selectedVerification, setSelectedVerification] = useState<DocumentVerification | null>(null);
    const [showVerifyModal, setShowVerifyModal] = useState(false);
    const [showDetailsModal, setShowDetailsModal] = useState(false);
    const [verificationNotes, setVerificationNotes] = useState('');
    const [confidenceScore, setConfidenceScore] = useState<number>(1.0);
    const [stats, setStats] = useState({
        total: 0,
        pending: 0,
        verified: 0,
        rejected: 0,
        expired: 0,
        underReview: 0
    });

    // Load data on component mount
    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setIsLoading(true);
            const [verificationsData, rulesData, statsData] = await Promise.all([
                documentVerificationService.getPendingVerifications(userRole),
                documentVerificationService.getVerificationRules(),
                documentVerificationService.getVerificationStats()
            ]);
            
            setVerifications(verificationsData);
            setRules(rulesData);
            setStats(statsData);
        } catch (error) {
            console.error('Error loading verification data:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleVerifyDocument = async (status: DocumentVerificationStatus) => {
        if (!selectedVerification || !userEmail) return;

        try {
            const verifyData: VerifyDocumentData = {
                documentId: selectedVerification.documentId,
                verifierEmail: userEmail,
                verificationStatus: status,
                verificationNotes: verificationNotes,
                confidenceScore: confidenceScore
            };

            await documentVerificationService.verifyDocument(verifyData);
            
            setShowVerifyModal(false);
            setSelectedVerification(null);
            setVerificationNotes('');
            setConfidenceScore(1.0);
            
            // Reload data
            await loadData();
            
            // Notify parent component
            onVerificationUpdate?.();
        } catch (error) {
            console.error('Error verifying document:', error);
        }
    };

    const getStatusIcon = (status: DocumentVerificationStatus) => {
        switch (status) {
            case DocumentVerificationStatus.Verified:
                return <CheckCircle className="w-5 h-5 text-green-600" />;
            case DocumentVerificationStatus.Rejected:
                return <XCircle className="w-5 h-5 text-red-600" />;
            case DocumentVerificationStatus.Pending:
                return <Clock className="w-5 h-5 text-yellow-600" />;
            case DocumentVerificationStatus.Expired:
                return <AlertTriangle className="w-5 h-5 text-orange-600" />;
            case DocumentVerificationStatus.UnderReview:
                return <RefreshCw className="w-5 h-5 text-blue-600" />;
            default:
                return <FileText className="w-5 h-5 text-gray-600" />;
        }
    };

    const getStatusColor = (status: DocumentVerificationStatus) => {
        switch (status) {
            case DocumentVerificationStatus.Verified:
                return 'bg-green-100 text-green-800';
            case DocumentVerificationStatus.Rejected:
                return 'bg-red-100 text-red-800';
            case DocumentVerificationStatus.Pending:
                return 'bg-yellow-100 text-yellow-800';
            case DocumentVerificationStatus.Expired:
                return 'bg-orange-100 text-orange-800';
            case DocumentVerificationStatus.UnderReview:
                return 'bg-blue-100 text-blue-800';
            default:
                return 'bg-gray-100 text-gray-800';
        }
    };

    const canVerify = (verification: DocumentVerification): boolean => {
        if (!userRole || !userEmail) return false;
        
        // Admin can verify anything
        if (userRole === 'Admin') return true;
        
        // Check if user role matches required verifier role
        const rule = rules.find(r => r.documentType === verification.documentType);
        return rule?.requiredVerifierRole === userRole;
    };

    if (isLoading) {
        return (
            <Card>
                <div className="p-6 text-center">
                    <RefreshCw className="w-8 h-8 animate-spin text-blue-600 mx-auto mb-4" />
                    <p className="text-gray-600">Loading document verifications...</p>
                </div>
            </Card>
        );
    }

    return (
        <div className="space-y-6">
            {/* Statistics Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4">
                <Card>
                    <div className="p-4 text-center">
                        <div className="text-2xl font-bold text-gray-900">{stats.total}</div>
                        <div className="text-sm text-gray-600">Total Documents</div>
                    </div>
                </Card>
                <Card>
                    <div className="p-4 text-center">
                        <div className="text-2xl font-bold text-yellow-600">{stats.pending}</div>
                        <div className="text-sm text-gray-600">Pending</div>
                    </div>
                </Card>
                <Card>
                    <div className="p-4 text-center">
                        <div className="text-2xl font-bold text-green-600">{stats.verified}</div>
                        <div className="text-sm text-gray-600">Verified</div>
                    </div>
                </Card>
                <Card>
                    <div className="p-4 text-center">
                        <div className="text-2xl font-bold text-red-600">{stats.rejected}</div>
                        <div className="text-sm text-gray-600">Rejected</div>
                    </div>
                </Card>
                <Card>
                    <div className="p-4 text-center">
                        <div className="text-2xl font-bold text-orange-600">{stats.expired}</div>
                        <div className="text-sm text-gray-600">Expired</div>
                    </div>
                </Card>
                <Card>
                    <div className="p-4 text-center">
                        <div className="text-2xl font-bold text-blue-600">{stats.underReview}</div>
                        <div className="text-sm text-gray-600">Under Review</div>
                    </div>
                </Card>
            </div>

            {/* Pending Verifications */}
            <Card>
                <div className="p-6">
                    <div className="flex justify-between items-center mb-4">
                        <h3 className="text-lg font-semibold text-slate-700">Pending Verifications</h3>
                        <Button onClick={loadData} variant="secondary" size="sm">
                            <RefreshCw className="w-4 h-4 mr-2" />
                            Refresh
                        </Button>
                    </div>

                    {verifications.length === 0 ? (
                        <div className="text-center py-8">
                            <Shield className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                            <h4 className="text-lg font-medium text-gray-900 mb-2">No Pending Verifications</h4>
                            <p className="text-gray-600">All documents are up to date!</p>
                        </div>
                    ) : (
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead className="bg-slate-50">
                                    <tr>
                                        <th className="p-4 text-sm font-semibold text-slate-600 uppercase tracking-wider">Document</th>
                                        <th className="p-4 text-sm font-semibold text-slate-600 uppercase tracking-wider">Type</th>
                                        <th className="p-4 text-sm font-semibold text-slate-600 uppercase tracking-wider">Status</th>
                                        <th className="p-4 text-sm font-semibold text-slate-600 uppercase tracking-wider">Uploaded</th>
                                        <th className="p-4 text-sm font-semibold text-slate-600 uppercase tracking-wider">Actions</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-200">
                                    {verifications.map((verification) => (
                                        <tr key={verification.id} className="hover:bg-slate-50">
                                            <td className="p-4">
                                                <div className="flex items-center">
                                                    <FileText className="w-5 h-5 text-gray-400 mr-3" />
                                                    <div>
                                                        <div className="font-medium text-slate-900">
                                                            Document {verification.documentId.slice(0, 8)}...
                                                        </div>
                                                        <div className="text-sm text-gray-500">
                                                            {verification.documentType}
                                                        </div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="p-4 text-sm text-slate-600">
                                                {verification.documentType}
                                            </td>
                                            <td className="p-4">
                                                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(verification.verificationStatus)}`}>
                                                    {getStatusIcon(verification.verificationStatus)}
                                                    <span className="ml-1">{verification.verificationStatus}</span>
                                                </span>
                                            </td>
                                            <td className="p-4 text-sm text-slate-600">
                                                {new Date(verification.createdAt).toLocaleDateString()}
                                            </td>
                                            <td className="p-4">
                                                <div className="flex gap-2">
                                                    <Button
                                                        variant="secondary"
                                                        size="sm"
                                                        onClick={() => {
                                                            setSelectedVerification(verification);
                                                            setShowDetailsModal(true);
                                                        }}
                                                    >
                                                        <Eye className="w-4 h-4" />
                                                    </Button>
                                                    {canVerify(verification) && (
                                                        <Button
                                                            size="sm"
                                                            onClick={() => {
                                                                setSelectedVerification(verification);
                                                                setShowVerifyModal(true);
                                                            }}
                                                        >
                                                            <Shield className="w-4 h-4 mr-1" />
                                                            Verify
                                                        </Button>
                                                    )}
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </Card>

            {/* Verification Modal */}
            <Modal isOpen={showVerifyModal} onClose={() => setShowVerifyModal(false)}>
                <div className="p-6">
                    <h3 className="text-lg font-semibold text-slate-900 mb-4">Verify Document</h3>
                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Verification Notes</label>
                            <textarea
                                value={verificationNotes}
                                onChange={(e) => setVerificationNotes(e.target.value)}
                                className="w-full border border-gray-300 rounded-md px-3 py-2"
                                rows={3}
                                placeholder="Enter verification notes..."
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">
                                Confidence Score: {confidenceScore}
                            </label>
                            <input
                                type="range"
                                min="0"
                                max="1"
                                step="0.1"
                                value={confidenceScore}
                                onChange={(e) => setConfidenceScore(parseFloat(e.target.value))}
                                className="w-full"
                            />
                            <div className="flex justify-between text-xs text-gray-500 mt-1">
                                <span>0.0 (Low)</span>
                                <span>1.0 (High)</span>
                            </div>
                        </div>
                    </div>
                    <div className="flex justify-end gap-3 mt-6">
                        <Button variant="secondary" onClick={() => setShowVerifyModal(false)}>
                            Cancel
                        </Button>
                        <Button
                            onClick={() => handleVerifyDocument(DocumentVerificationStatus.Rejected)}
                            className="bg-red-600 hover:bg-red-700 text-white"
                        >
                            Reject
                        </Button>
                        <Button
                            onClick={() => handleVerifyDocument(DocumentVerificationStatus.Verified)}
                            className="bg-green-600 hover:bg-green-700 text-white"
                        >
                            Approve
                        </Button>
                    </div>
                </div>
            </Modal>

            {/* Details Modal */}
            <Modal isOpen={showDetailsModal} onClose={() => setShowDetailsModal(false)}>
                <div className="p-6">
                    <h3 className="text-lg font-semibold text-slate-900 mb-4">Document Details</h3>
                    {selectedVerification && (
                        <div className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700">Document ID</label>
                                    <p className="text-sm text-gray-900">{selectedVerification.documentId}</p>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700">Document Type</label>
                                    <p className="text-sm text-gray-900">{selectedVerification.documentType}</p>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700">Status</label>
                                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(selectedVerification.verificationStatus)}`}>
                                    {getStatusIcon(selectedVerification.verificationStatus)}
                                    <span className="ml-1">{selectedVerification.verificationStatus}</span>
                                </span>
                            </div>
                            {selectedVerification.verificationNotes && (
                                <div>
                                    <label className="block text-sm font-medium text-gray-700">Verification Notes</label>
                                    <p className="text-sm text-gray-900">{selectedVerification.verificationNotes}</p>
                                </div>
                            )}
                            {selectedVerification.verifiedBy && (
                                <div>
                                    <label className="block text-sm font-medium text-gray-700">Verified By</label>
                                    <p className="text-sm text-gray-900">{selectedVerification.verifiedBy}</p>
                                </div>
                            )}
                            {selectedVerification.verifiedAt && (
                                <div>
                                    <label className="block text-sm font-medium text-gray-700">Verified At</label>
                                    <p className="text-sm text-gray-900">{new Date(selectedVerification.verifiedAt).toLocaleString()}</p>
                                </div>
                            )}
                        </div>
                    )}
                    <div className="flex justify-end mt-6">
                        <Button variant="secondary" onClick={() => setShowDetailsModal(false)}>
                            Close
                        </Button>
                    </div>
                </div>
            </Modal>
        </div>
    );
};

export default DocumentVerificationManager;

