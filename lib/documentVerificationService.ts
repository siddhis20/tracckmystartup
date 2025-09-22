import { supabase } from './supabase';
import { 
    DocumentVerification, 
    DocumentVerificationRule, 
    DocumentVerificationHistory,
    DocumentVerificationStatus,
    VerifyDocumentData
} from '../types';
import { hybridDocumentVerification } from './hybridDocumentVerification';

export class DocumentVerificationService {
    // Get document verification status
    async getDocumentVerificationStatus(documentId: string): Promise<DocumentVerificationStatus> {
        try {
            const { data, error } = await supabase
                .from('document_verifications')
                .select('verification_status')
                .eq('document_id', documentId)
                .order('created_at', { ascending: false })
                .limit(1)
                .single();

            if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
                console.error('Error fetching document verification status:', error);
                throw error;
            }

            return data?.verification_status || DocumentVerificationStatus.Pending;
        } catch (error) {
            console.error('Error in getDocumentVerificationStatus:', error);
            return DocumentVerificationStatus.Pending;
        }
    }

    // Get full document verification details
    async getDocumentVerification(documentId: string): Promise<DocumentVerification | null> {
        try {
            const { data, error } = await supabase
                .from('document_verifications')
                .select('*')
                .eq('document_id', documentId)
                .order('created_at', { ascending: false })
                .limit(1)
                .single();

            if (error && error.code !== 'PGRST116') {
                console.error('Error fetching document verification:', error);
                throw error;
            }

            if (!data) return null;

            return {
                id: data.id,
                documentId: data.document_id,
                documentType: data.document_type,
                verificationStatus: data.verification_status,
                verifiedBy: data.verified_by,
                verifiedAt: data.verified_at,
                verificationNotes: data.verification_notes,
                rejectionReason: data.rejection_reason,
                expiryDate: data.expiry_date,
                verificationMethod: data.verification_method,
                confidenceScore: data.confidence_score,
                createdAt: data.created_at,
                updatedAt: data.updated_at
            };
        } catch (error) {
            console.error('Error in getDocumentVerification:', error);
            return null;
        }
    }

    // Verify a document
    async verifyDocument(verifyData: VerifyDocumentData): Promise<boolean> {
        try {
            const { data, error } = await supabase.rpc('verify_document', {
                document_id_param: verifyData.documentId,
                verifier_email: verifyData.verifierEmail,
                verification_status_param: verifyData.verificationStatus,
                verification_notes_param: verifyData.verificationNotes || null,
                confidence_score_param: verifyData.confidenceScore || null
            });

            if (error) {
                console.error('Error verifying document:', error);
                throw error;
            }

            return data === true;
        } catch (error) {
            console.error('Error in verifyDocument:', error);
            throw error;
        }
    }

    // Get verification history for a document
    async getDocumentVerificationHistory(documentId: string): Promise<DocumentVerificationHistory[]> {
        try {
            const { data, error } = await supabase
                .from('document_verification_history')
                .select(`
                    *,
                    document_verification:document_verifications!inner(document_id)
                `)
                .eq('document_verification.document_id', documentId)
                .order('changed_at', { ascending: false });

            if (error) {
                console.error('Error fetching document verification history:', error);
                throw error;
            }

            return (data || []).map(history => ({
                id: history.id,
                documentVerificationId: history.document_verification_id,
                previousStatus: history.previous_status,
                newStatus: history.new_status,
                changedBy: history.changed_by,
                changeReason: history.change_reason,
                changedAt: history.changed_at
            }));
        } catch (error) {
            console.error('Error in getDocumentVerificationHistory:', error);
            return [];
        }
    }

    // Get all verification rules
    async getVerificationRules(): Promise<DocumentVerificationRule[]> {
        try {
            const { data, error } = await supabase
                .from('document_verification_rules')
                .select('*')
                .order('document_type');

            if (error) {
                console.error('Error fetching verification rules:', error);
                throw error;
            }

            return (data || []).map(rule => ({
                id: rule.id,
                documentType: rule.document_type,
                verificationRequired: rule.verification_required,
                autoVerification: rule.auto_verification,
                verificationExpiryDays: rule.verification_expiry_days,
                requiredVerifierRole: rule.required_verifier_role,
                verificationCriteria: rule.verification_criteria,
                createdAt: rule.created_at,
                updatedAt: rule.updated_at
            }));
        } catch (error) {
            console.error('Error in getVerificationRules:', error);
            return [];
        }
    }

    // Get documents pending verification
    async getPendingVerifications(verifierRole?: string): Promise<DocumentVerification[]> {
        try {
            let query = supabase
                .from('document_verifications')
                .select('*')
                .eq('verification_status', DocumentVerificationStatus.Pending)
                .order('created_at', { ascending: true });

            if (verifierRole) {
                query = query.eq('required_verifier_role', verifierRole);
            }

            const { data, error } = await query;

            if (error) {
                console.error('Error fetching pending verifications:', error);
                throw error;
            }

            return (data || []).map(verification => ({
                id: verification.id,
                documentId: verification.document_id,
                documentType: verification.document_type,
                verificationStatus: verification.verification_status,
                verifiedBy: verification.verified_by,
                verifiedAt: verification.verified_at,
                verificationNotes: verification.verification_notes,
                rejectionReason: verification.rejection_reason,
                expiryDate: verification.expiry_date,
                verificationMethod: verification.verification_method,
                confidenceScore: verification.confidence_score,
                createdAt: verification.created_at,
                updatedAt: verification.updated_at
            }));
        } catch (error) {
            console.error('Error in getPendingVerifications:', error);
            return [];
        }
    }

    // Get documents by verification status
    async getDocumentsByStatus(status: DocumentVerificationStatus, limit: number = 50): Promise<DocumentVerification[]> {
        try {
            const { data, error } = await supabase
                .from('document_verifications')
                .select('*')
                .eq('verification_status', status)
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) {
                console.error('Error fetching documents by status:', error);
                throw error;
            }

            return (data || []).map(verification => ({
                id: verification.id,
                documentId: verification.document_id,
                documentType: verification.document_type,
                verificationStatus: verification.verification_status,
                verifiedBy: verification.verified_by,
                verifiedAt: verification.verified_at,
                verificationNotes: verification.verification_notes,
                rejectionReason: verification.rejection_reason,
                expiryDate: verification.expiry_date,
                verificationMethod: verification.verification_method,
                confidenceScore: verification.confidence_score,
                createdAt: verification.created_at,
                updatedAt: verification.updated_at
            }));
        } catch (error) {
            console.error('Error in getDocumentsByStatus:', error);
            return [];
        }
    }

    // Check if document verification has expired
    async checkExpiredVerifications(): Promise<DocumentVerification[]> {
        try {
            const { data, error } = await supabase
                .from('document_verifications')
                .select('*')
                .eq('verification_status', DocumentVerificationStatus.Verified)
                .lt('expiry_date', new Date().toISOString());

            if (error) {
                console.error('Error checking expired verifications:', error);
                throw error;
            }

            return (data || []).map(verification => ({
                id: verification.id,
                documentId: verification.document_id,
                documentType: verification.document_type,
                verificationStatus: verification.verification_status,
                verifiedBy: verification.verified_by,
                verifiedAt: verification.verified_at,
                verificationNotes: verification.verification_notes,
                rejectionReason: verification.rejection_reason,
                expiryDate: verification.expiry_date,
                verificationMethod: verification.verification_method,
                confidenceScore: verification.confidence_score,
                createdAt: verification.created_at,
                updatedAt: verification.updated_at
            }));
        } catch (error) {
            console.error('Error in checkExpiredVerifications:', error);
            return [];
        }
    }

    // Get verification statistics
    async getVerificationStats(): Promise<{
        total: number;
        pending: number;
        verified: number;
        rejected: number;
        expired: number;
        underReview: number;
    }> {
        try {
            const { data, error } = await supabase
                .from('document_verifications')
                .select('verification_status');

            if (error) {
                console.error('Error fetching verification stats:', error);
                throw error;
            }

            const stats = {
                total: data?.length || 0,
                pending: 0,
                verified: 0,
                rejected: 0,
                expired: 0,
                underReview: 0
            };

            data?.forEach(verification => {
                switch (verification.verification_status) {
                    case DocumentVerificationStatus.Pending:
                        stats.pending++;
                        break;
                    case DocumentVerificationStatus.Verified:
                        stats.verified++;
                        break;
                    case DocumentVerificationStatus.Rejected:
                        stats.rejected++;
                        break;
                    case DocumentVerificationStatus.Expired:
                        stats.expired++;
                        break;
                    case DocumentVerificationStatus.UnderReview:
                        stats.underReview++;
                        break;
                }
            });

            return stats;
        } catch (error) {
            console.error('Error in getVerificationStats:', error);
            return {
                total: 0,
                pending: 0,
                verified: 0,
                rejected: 0,
                expired: 0,
                underReview: 0
            };
        }
    }

    // Create verification rule
    async createVerificationRule(rule: Omit<DocumentVerificationRule, 'id' | 'createdAt' | 'updatedAt'>): Promise<DocumentVerificationRule> {
        try {
            const { data, error } = await supabase
                .from('document_verification_rules')
                .insert({
                    document_type: rule.documentType,
                    verification_required: rule.verificationRequired,
                    auto_verification: rule.autoVerification,
                    verification_expiry_days: rule.verificationExpiryDays,
                    required_verifier_role: rule.requiredVerifierRole,
                    verification_criteria: rule.verificationCriteria
                })
                .select()
                .single();

            if (error) {
                console.error('Error creating verification rule:', error);
                throw error;
            }

            return {
                id: data.id,
                documentType: data.document_type,
                verificationRequired: data.verification_required,
                autoVerification: data.auto_verification,
                verificationExpiryDays: data.verification_expiry_days,
                requiredVerifierRole: data.required_verifier_role,
                verificationCriteria: data.verification_criteria,
                createdAt: data.created_at,
                updatedAt: data.updated_at
            };
        } catch (error) {
            console.error('Error in createVerificationRule:', error);
            throw error;
        }
    }

    // Automated document verification
    async verifyDocumentAutomatically(file: File, documentType: string): Promise<{
        success: boolean;
        status: DocumentVerificationStatus;
        confidence: number;
        reasons: string[];
        autoVerified: boolean;
    }> {
        try {
            const result = await hybridDocumentVerification.verifyWithStrategy(file, documentType);
            
            return {
                success: true,
                status: result.status,
                confidence: result.confidence,
                reasons: result.reasons,
                autoVerified: result.autoVerified
            };
        } catch (error) {
            console.error('Error in automated verification:', error);
            return {
                success: false,
                status: DocumentVerificationStatus.UnderReview,
                confidence: 0.0,
                reasons: ['Automated verification failed'],
                autoVerified: false
            };
        }
    }

    // Upload and auto-verify document
    async uploadAndVerifyDocument(
        startupId: number,
        taskId: string,
        file: File,
        uploadedBy: string,
        documentType: string = 'compliance_document'
    ): Promise<{
        uploadId?: string;
        verificationStatus: DocumentVerificationStatus;
        autoVerified: boolean;
        error?: string;
    }> {
        try {
            // First, upload the document
            const uploadResult = await this.uploadDocument(startupId, taskId, file, uploadedBy);
            
            if (!uploadResult.success || !uploadResult.uploadId) {
                return {
                    verificationStatus: DocumentVerificationStatus.Pending,
                    autoVerified: false,
                    error: uploadResult.error
                };
            }

            // Then, attempt automated verification
            const verificationResult = await this.verifyDocumentAutomatically(file, documentType);
            
            // If auto-verified, update the verification status
            if (verificationResult.autoVerified) {
                await this.verifyDocument({
                    documentId: uploadResult.uploadId,
                    verifierEmail: 'system@automated',
                    verificationStatus: verificationResult.status,
                    verificationNotes: `Automated verification: ${verificationResult.reasons.join(', ')}`,
                    confidenceScore: verificationResult.confidence
                });
            }

            return {
                uploadId: uploadResult.uploadId,
                verificationStatus: verificationResult.status,
                autoVerified: verificationResult.autoVerified
            };
            
        } catch (error) {
            console.error('Error in upload and verify:', error);
            return {
                verificationStatus: DocumentVerificationStatus.Pending,
                autoVerified: false,
                error: error instanceof Error ? error.message : 'Unknown error'
            };
        }
    }

    // Upload document (helper method)
    private async uploadDocument(
        startupId: number,
        taskId: string,
        file: File,
        uploadedBy: string
    ): Promise<{ success: boolean; uploadId?: string; error?: string }> {
        try {
            // Upload file to storage
            const safeName = file.name.replace(/[^a-zA-Z0-9_.-]/g, '_');
            const fileName = `${startupId}/${taskId}/${Date.now()}_${safeName}`;
            
            const { data: uploadData, error: uploadError } = await supabase.storage
                .from('compliance-documents')
                .upload(fileName, file, {
                    upsert: true,
                    contentType: file.type || 'application/pdf',
                    cacheControl: '3600'
                });

            if (uploadError) throw uploadError;

            // Get public URL
            const { data: urlData } = supabase.storage
                .from('compliance-documents')
                .getPublicUrl(fileName);

            // Save upload record to database
            const { data: recordData, error: recordError } = await supabase
                .from('compliance_uploads')
                .insert({
                    startup_id: startupId,
                    task_id: taskId,
                    file_name: file.name,
                    file_url: urlData.publicUrl,
                    uploaded_by: uploadedBy,
                    file_size: file.size,
                    file_type: file.type
                })
                .select()
                .single();

            if (recordError) throw recordError;

            return { success: true, uploadId: recordData.id };
        } catch (error) {
            console.error('Error uploading document:', error);
            return { 
                success: false, 
                error: error instanceof Error ? error.message : 'Upload failed' 
            };
        }
    }
}

// Export a singleton instance
export const documentVerificationService = new DocumentVerificationService();
