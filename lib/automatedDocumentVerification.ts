import { DocumentVerificationStatus } from '../types';

export interface AutomatedVerificationResult {
    status: DocumentVerificationStatus;
    confidence: number;
    reasons: string[];
    autoVerified: boolean;
}

export class AutomatedDocumentVerification {
    
    // Basic file validation
    static validateFile(file: File, documentType: string): AutomatedVerificationResult {
        const reasons: string[] = [];
        let confidence = 0.5; // Start with 50% confidence
        
        // Check file type
        const allowedTypes = this.getAllowedFileTypes(documentType);
        if (!allowedTypes.includes(file.type)) {
            return {
                status: DocumentVerificationStatus.Rejected,
                confidence: 0.0,
                reasons: [`Invalid file type: ${file.type}. Allowed: ${allowedTypes.join(', ')}`],
                autoVerified: false
            };
        }
        
        // Check file size
        const maxSize = this.getMaxFileSize(documentType);
        if (file.size > maxSize) {
            return {
                status: DocumentVerificationStatus.Rejected,
                confidence: 0.0,
                reasons: [`File too large: ${(file.size / 1024 / 1024).toFixed(2)}MB. Max: ${(maxSize / 1024 / 1024).toFixed(2)}MB`],
                autoVerified: false
            };
        }
        
        // Check file name
        if (this.isSuspiciousFileName(file.name)) {
            reasons.push('Suspicious file name detected');
            confidence -= 0.2;
        }
        
        // Check file extension
        if (this.isSuspiciousExtension(file.name)) {
            reasons.push('Suspicious file extension detected');
            confidence -= 0.3;
        }
        
        // If all checks pass, auto-verify
        if (reasons.length === 0) {
            return {
                status: DocumentVerificationStatus.Verified,
                confidence: 0.8,
                reasons: ['File passed automated validation'],
                autoVerified: true
            };
        }
        
        // If minor issues, mark for review
        if (confidence > 0.3) {
            return {
                status: DocumentVerificationStatus.UnderReview,
                confidence: confidence,
                reasons: reasons,
                autoVerified: false
            };
        }
        
        // If major issues, reject
        return {
            status: DocumentVerificationStatus.Rejected,
            confidence: confidence,
            reasons: reasons,
            autoVerified: false
        };
    }
    
    // Get allowed file types for document type
    private static getAllowedFileTypes(documentType: string): string[] {
        const typeMap: Record<string, string[]> = {
            'compliance_document': ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
            'ip_trademark_document': ['application/pdf', 'image/jpeg', 'image/png', 'image/gif'],
            'financial_document': ['application/pdf', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'text/csv'],
            'government_id': ['application/pdf', 'image/jpeg', 'image/png'],
            'license_document': ['application/pdf', 'image/jpeg', 'image/png']
        };
        
        return typeMap[documentType] || ['application/pdf'];
    }
    
    // Get max file size for document type
    private static getMaxFileSize(documentType: string): number {
        const sizeMap: Record<string, number> = {
            'compliance_document': 50 * 1024 * 1024, // 50MB
            'ip_trademark_document': 25 * 1024 * 1024, // 25MB
            'financial_document': 10 * 1024 * 1024, // 10MB
            'government_id': 5 * 1024 * 1024, // 5MB
            'license_document': 10 * 1024 * 1024 // 10MB
        };
        
        return sizeMap[documentType] || 10 * 1024 * 1024; // Default 10MB
    }
    
    // Check for suspicious file names
    private static isSuspiciousFileName(fileName: string): boolean {
        const suspiciousPatterns = [
            /\.exe$/i,
            /\.bat$/i,
            /\.cmd$/i,
            /\.scr$/i,
            /\.pif$/i,
            /\.com$/i,
            /\.vbs$/i,
            /\.js$/i,
            /\.jar$/i,
            /\.zip$/i,
            /\.rar$/i,
            /\.7z$/i
        ];
        
        return suspiciousPatterns.some(pattern => pattern.test(fileName));
    }
    
    // Check for suspicious extensions
    private static isSuspiciousExtension(fileName: string): boolean {
        const suspiciousExtensions = ['.exe', '.bat', '.cmd', '.scr', '.pif', '.com', '.vbs', '.js', '.jar'];
        const extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
        return suspiciousExtensions.includes(extension);
    }
    
    // Advanced validation using file content analysis
    static async validateFileContent(file: File, documentType: string): Promise<AutomatedVerificationResult> {
        const basicValidation = this.validateFile(file, documentType);
        
        if (basicValidation.status === DocumentVerificationStatus.Rejected) {
            return basicValidation;
        }
        
        // Additional content validation
        const reasons: string[] = [...basicValidation.reasons];
        let confidence = basicValidation.confidence;
        
        // Check if file is actually a PDF (for PDF files)
        if (file.type === 'application/pdf') {
            const isRealPDF = await this.validatePDFContent(file);
            if (!isRealPDF) {
                reasons.push('File appears to be corrupted or not a valid PDF');
                confidence -= 0.3;
            }
        }
        
        // Check for password protection
        if (file.type === 'application/pdf') {
            const isPasswordProtected = await this.checkPasswordProtection(file);
            if (isPasswordProtected) {
                reasons.push('Password-protected files are not allowed');
                confidence -= 0.5;
            }
        }
        
        // Determine final status
        if (confidence >= 0.7) {
            return {
                status: DocumentVerificationStatus.Verified,
                confidence: confidence,
                reasons: reasons,
                autoVerified: true
            };
        } else if (confidence >= 0.4) {
            return {
                status: DocumentVerificationStatus.UnderReview,
                confidence: confidence,
                reasons: reasons,
                autoVerified: false
            };
        } else {
            return {
                status: DocumentVerificationStatus.Rejected,
                confidence: confidence,
                reasons: reasons,
                autoVerified: false
            };
        }
    }
    
    // Validate PDF content
    private static async validatePDFContent(file: File): Promise<boolean> {
        try {
            const arrayBuffer = await file.arrayBuffer();
            const uint8Array = new Uint8Array(arrayBuffer);
            
            // Check PDF header
            const header = String.fromCharCode(...uint8Array.slice(0, 4));
            if (header !== '%PDF') {
                return false;
            }
            
            // Check for PDF structure
            const content = String.fromCharCode(...uint8Array.slice(0, 1024));
            if (!content.includes('obj') || !content.includes('endobj')) {
                return false;
            }
            
            return true;
        } catch (error) {
            console.error('Error validating PDF content:', error);
            return false;
        }
    }
    
    // Check if PDF is password protected
    private static async checkPasswordProtection(file: File): Promise<boolean> {
        try {
            const arrayBuffer = await file.arrayBuffer();
            const uint8Array = new Uint8Array(arrayBuffer);
            const content = String.fromCharCode(...uint8Array.slice(0, 2048));
            
            // Look for encryption markers
            return content.includes('/Encrypt') || content.includes('/P ');
        } catch (error) {
            console.error('Error checking password protection:', error);
            return false;
        }
    }
    
    // OCR-based validation (for images)
    static async validateImageContent(file: File): Promise<AutomatedVerificationResult> {
        if (!file.type.startsWith('image/')) {
            return {
                status: DocumentVerificationStatus.Rejected,
                confidence: 0.0,
                reasons: ['File is not an image'],
                autoVerified: false
            };
        }
        
        const reasons: string[] = [];
        let confidence = 0.6;
        
        // Check image dimensions
        const dimensions = await this.getImageDimensions(file);
        if (dimensions.width < 100 || dimensions.height < 100) {
            reasons.push('Image too small (minimum 100x100 pixels)');
            confidence -= 0.2;
        }
        
        // Check image quality (basic)
        const quality = await this.checkImageQuality(file);
        if (quality < 0.5) {
            reasons.push('Image quality too low');
            confidence -= 0.3;
        }
        
        if (reasons.length === 0) {
            return {
                status: DocumentVerificationStatus.Verified,
                confidence: 0.8,
                reasons: ['Image passed automated validation'],
                autoVerified: true
            };
        }
        
        return {
            status: DocumentVerificationStatus.UnderReview,
            confidence: confidence,
            reasons: reasons,
            autoVerified: false
        };
    }
    
    // Get image dimensions
    private static async getImageDimensions(file: File): Promise<{ width: number; height: number }> {
        return new Promise((resolve) => {
            const img = new Image();
            img.onload = () => {
                resolve({ width: img.width, height: img.height });
            };
            img.onerror = () => {
                resolve({ width: 0, height: 0 });
            };
            img.src = URL.createObjectURL(file);
        });
    }
    
    // Check image quality (basic)
    private static async checkImageQuality(file: File): Promise<number> {
        // This is a simplified quality check
        // In a real implementation, you'd use more sophisticated algorithms
        const fileSize = file.size;
        const expectedSize = 500 * 1024; // 500KB
        
        if (fileSize < expectedSize * 0.1) {
            return 0.3; // Very low quality
        } else if (fileSize < expectedSize * 0.5) {
            return 0.6; // Medium quality
        } else {
            return 0.8; // Good quality
        }
    }
}

export const automatedDocumentVerification = new AutomatedDocumentVerification();

