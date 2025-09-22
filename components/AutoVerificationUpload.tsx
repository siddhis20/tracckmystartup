import React, { useState } from 'react';
import { uploadWithAutoVerification } from '../lib/uploadWithAutoVerification';
import { DocumentVerificationStatus } from '../types';
import { Upload, CheckCircle, XCircle, AlertTriangle, Loader2 } from 'lucide-react';
import Button from './ui/Button';

interface AutoVerificationUploadProps {
    startupId: number;
    taskId: string;
    uploadedBy: string;
    documentType?: string;
    onUploadSuccess?: (uploadId: string) => void;
    onUploadError?: (error: string) => void;
    className?: string;
}

const AutoVerificationUpload: React.FC<AutoVerificationUploadProps> = ({
    startupId,
    taskId,
    uploadedBy,
    documentType = 'compliance_document',
    onUploadSuccess,
    onUploadError,
    className = ''
}) => {
    const [isUploading, setIsUploading] = useState(false);
    const [uploadStatus, setUploadStatus] = useState<'idle' | 'uploading' | 'verifying' | 'success' | 'error' | 'warning'>('idle');
    const [message, setMessage] = useState('');
    const [file, setFile] = useState<File | null>(null);

    const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
        const selectedFile = event.target.files?.[0];
        if (selectedFile) {
            setFile(selectedFile);
            setUploadStatus('idle');
            setMessage('');
        }
    };

    const handleUpload = async () => {
        if (!file) {
            setMessage('❌ Please select a file first');
            setUploadStatus('error');
            return;
        }

        setIsUploading(true);
        setUploadStatus('uploading');
        setMessage('📤 Uploading file...');

        try {
            // Upload with automatic verification
            const result = await uploadWithAutoVerification.uploadAndVerify(
                startupId,
                taskId,
                file,
                uploadedBy,
                documentType
            );

            if (result.success) {
                if (result.autoVerified) {
                    setUploadStatus('success');
                    setMessage(result.message);
                    onUploadSuccess?.(result.uploadId!);
                } else {
                    setUploadStatus('warning');
                    setMessage(result.message);
                    onUploadSuccess?.(result.uploadId!);
                }
            } else {
                setUploadStatus('error');
                setMessage(result.message);
                onUploadError?.(result.error || 'Upload failed');
            }
        } catch (error) {
            setUploadStatus('error');
            setMessage('❌ Upload failed: ' + (error instanceof Error ? error.message : 'Unknown error'));
            onUploadError?.(error instanceof Error ? error.message : 'Unknown error');
        } finally {
            setIsUploading(false);
        }
    };

    const getStatusIcon = () => {
        switch (uploadStatus) {
            case 'uploading':
            case 'verifying':
                return <Loader2 className="w-5 h-5 animate-spin text-blue-600" />;
            case 'success':
                return <CheckCircle className="w-5 h-5 text-green-600" />;
            case 'error':
                return <XCircle className="w-5 h-5 text-red-600" />;
            case 'warning':
                return <AlertTriangle className="w-5 h-5 text-yellow-600" />;
            default:
                return <Upload className="w-5 h-5 text-gray-600" />;
        }
    };

    const getStatusColor = () => {
        switch (uploadStatus) {
            case 'success':
                return 'border-green-200 bg-green-50';
            case 'error':
                return 'border-red-200 bg-red-50';
            case 'warning':
                return 'border-yellow-200 bg-yellow-50';
            case 'uploading':
            case 'verifying':
                return 'border-blue-200 bg-blue-50';
            default:
                return 'border-gray-200 bg-white';
        }
    };

    return (
        <div className={`space-y-4 ${className}`}>
            {/* File Input */}
            <div className="space-y-2">
                <label className="block text-sm font-medium text-gray-700">
                    Select Document
                </label>
                <input
                    type="file"
                    onChange={handleFileSelect}
                    accept=".pdf,.doc,.docx,.jpg,.jpeg,.png,.gif"
                    className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
                    disabled={isUploading}
                />
            </div>

            {/* Upload Button */}
            <Button
                onClick={handleUpload}
                disabled={!file || isUploading}
                className="w-full"
            >
                {isUploading ? (
                    <>
                        <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                        {uploadStatus === 'uploading' ? 'Uploading...' : 'Verifying...'}
                    </>
                ) : (
                    <>
                        <Upload className="w-4 h-4 mr-2" />
                        Upload & Verify
                    </>
                )}
            </Button>

            {/* Status Message */}
            {message && (
                <div className={`p-4 rounded-lg border ${getStatusColor()}`}>
                    <div className="flex items-center">
                        {getStatusIcon()}
                        <span className="ml-2 text-sm font-medium">{message}</span>
                    </div>
                </div>
            )}

            {/* File Info */}
            {file && (
                <div className="text-sm text-gray-600">
                    <p><strong>File:</strong> {file.name}</p>
                    <p><strong>Size:</strong> {(file.size / 1024 / 1024).toFixed(2)} MB</p>
                    <p><strong>Type:</strong> {file.type}</p>
                </div>
            )}
        </div>
    );
};

export default AutoVerificationUpload;

