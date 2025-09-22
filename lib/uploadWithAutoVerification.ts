import { supabase } from './supabase';
import { hybridDocumentVerification } from './hybridDocumentVerification';
import { DocumentVerificationStatus } from '../types';

export interface UploadWithVerificationResult {
    success: boolean;
    message: string;
    uploadId?: string;
    verificationStatus: DocumentVerificationStatus;
    autoVerified: boolean;
    error?: string;
}

export class UploadWithAutoVerification {
    
    // Main method: Upload file and verify automatically
    static async uploadAndVerify(
        startupId: number,
        taskId: string,
        file: File,
        uploadedBy: string,
        documentType: string = 'compliance_document'
    ): Promise<UploadWithVerificationResult> {
        try {
            console.log('🚀 Starting upload with auto-verification...');
            
            // Step 1: Upload file to storage
            const uploadResult = await this.uploadFileToStorage(startupId, taskId, file);
            if (!uploadResult.success) {
                return {
                    success: false,
                    message: '❌ Upload failed: ' + uploadResult.error,
                    verificationStatus: DocumentVerificationStatus.Pending,
                    autoVerified: false,
                    error: uploadResult.error
                };
            }
            
            console.log('✅ File uploaded successfully');
            
            // Step 2: Save upload record to database
            const recordResult = await this.saveUploadRecord(
                startupId, 
                taskId, 
                file, 
                uploadedBy, 
                uploadResult.fileUrl
            );
            
            if (!recordResult.success) {
                return {
                    success: false,
                    message: '❌ Failed to save upload record: ' + recordResult.error,
                    verificationStatus: DocumentVerificationStatus.Pending,
                    autoVerified: false,
                    error: recordResult.error
                };
            }
            
            console.log('✅ Upload record saved');
            
            // Step 3: Automatically verify the document
            console.log('🔍 Starting automatic verification...');
            const verificationResult = await hybridDocumentVerification.verifyWithStrategy(file, documentType);
            
            console.log('📊 Verification result:', verificationResult);
            
            // Step 4: Update verification status in database
            await this.updateVerificationStatus(
                recordResult.uploadId!,
                verificationResult.status,
                verificationResult.confidence,
                verificationResult.reasons.join(', '),
                verificationResult.autoVerified
            );
            
            // Step 5: Return appropriate message based on verification result
            if (verificationResult.autoVerified) {
                return {
                    success: true,
                    message: '✅ Document uploaded and verified successfully!',
                    uploadId: recordResult.uploadId,
                    verificationStatus: verificationResult.status,
                    autoVerified: true
                };
            } else if (verificationResult.status === DocumentVerificationStatus.UnderReview) {
                return {
                    success: true,
                    message: '⚠️ Document uploaded successfully, but requires manual review',
                    uploadId: recordResult.uploadId,
                    verificationStatus: verificationResult.status,
                    autoVerified: false
                };
            } else {
                return {
                    success: false,
                    message: '❌ Document upload failed verification: ' + verificationResult.reasons.join(', '),
                    uploadId: recordResult.uploadId,
                    verificationStatus: verificationResult.status,
                    autoVerified: false,
                    error: verificationResult.reasons.join(', ')
                };
            }
            
        } catch (error) {
            console.error('❌ Upload with verification failed:', error);
            return {
                success: false,
                message: '❌ Upload failed: ' + (error instanceof Error ? error.message : 'Unknown error'),
                verificationStatus: DocumentVerificationStatus.Pending,
                autoVerified: false,
                error: error instanceof Error ? error.message : 'Unknown error'
            };
        }
    }
    
    // Upload file to Supabase storage
    private static async uploadFileToStorage(
        startupId: number, 
        taskId: string, 
        file: File
    ): Promise<{ success: boolean; fileUrl?: string; error?: string }> {
        try {
            const safeName = file.name.replace(/[^a-zA-Z0-9_.-]/g, '_');
            const fileName = `${startupId}/${taskId}/${Date.now()}_${safeName}`;
            
            const { data: uploadData, error: uploadError } = await supabase.storage
                .from('compliance-documents')
                .upload(fileName, file, {
                    upsert: true,
                    contentType: file.type || 'application/pdf',
                    cacheControl: '3600'
                });

            if (uploadError) {
                console.error('Storage upload error:', uploadError);
                return { success: false, error: uploadError.message };
            }

            // Get public URL
            const { data: urlData } = supabase.storage
                .from('compliance-documents')
                .getPublicUrl(fileName);

            return { success: true, fileUrl: urlData.publicUrl };
            
        } catch (error) {
            console.error('File upload error:', error);
            return { 
                success: false, 
                error: error instanceof Error ? error.message : 'Upload failed' 
            };
        }
    }
    
    // Save upload record to database
    private static async saveUploadRecord(
        startupId: number,
        taskId: string,
        file: File,
        uploadedBy: string,
        fileUrl: string
    ): Promise<{ success: boolean; uploadId?: string; error?: string }> {
        try {
            const { data: recordData, error: recordError } = await supabase
                .from('compliance_uploads')
                .insert({
                    startup_id: startupId,
                    task_id: taskId,
                    file_name: file.name,
                    file_url: fileUrl,
                    uploaded_by: uploadedBy,
                    file_size: file.size,
                    file_type: file.type,
                    verification_status: 'pending' // Will be updated after verification
                })
                .select()
                .single();

            if (recordError) {
                console.error('Database insert error:', recordError);
                return { success: false, error: recordError.message };
            }

            return { success: true, uploadId: recordData.id };
            
        } catch (error) {
            console.error('Database save error:', error);
            return { 
                success: false, 
                error: error instanceof Error ? error.message : 'Database save failed' 
            };
        }
    }
    
    // Update verification status in database
    private static async updateVerificationStatus(
        uploadId: string,
        status: DocumentVerificationStatus,
        confidence: number,
        notes: string,
        autoVerified: boolean
    ): Promise<void> {
        try {
            // Update compliance_uploads table
            await supabase
                .from('compliance_uploads')
                .update({
                    verification_status: status,
                    verified_by: autoVerified ? 'system@automated' : null,
                    verified_at: autoVerified ? new Date().toISOString() : null,
                    verification_notes: notes,
                    verification_expiry: autoVerified ? new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString() : null
                })
                .eq('id', uploadId);
            
            // Create verification record
            await supabase
                .from('document_verifications')
                .insert({
                    document_id: uploadId,
                    document_type: 'compliance_document',
                    verification_status: status,
                    verified_by: autoVerified ? 'system@automated' : null,
                    verified_at: autoVerified ? new Date().toISOString() : null,
                    verification_notes: notes,
                    expiry_date: autoVerified ? new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString() : null,
                    confidence_score: confidence
                });
                
        } catch (error) {
            console.error('Error updating verification status:', error);
        }
    }
    
    // Quick upload with basic verification
    static async quickUploadAndVerify(
        startupId: number,
        taskId: string,
        file: File,
        uploadedBy: string
    ): Promise<UploadWithVerificationResult> {
        return this.uploadAndVerify(startupId, taskId, file, uploadedBy, 'compliance_document');
    }
    
    // Upload with strict verification
    static async strictUploadAndVerify(
        startupId: number,
        taskId: string,
        file: File,
        uploadedBy: string,
        documentType: string
    ): Promise<UploadWithVerificationResult> {
        // Use stricter verification for important documents
        const result = await this.uploadAndVerify(startupId, taskId, file, uploadedBy, documentType);
        
        // If verification failed, delete the uploaded file
        if (!result.success && result.uploadId) {
            try {
                await supabase
                    .from('compliance_uploads')
                    .delete()
                    .eq('id', result.uploadId);
            } catch (error) {
                console.error('Error cleaning up failed upload:', error);
            }
        }
        
        return result;
    }
}

export const uploadWithAutoVerification = new UploadWithAutoVerification();

