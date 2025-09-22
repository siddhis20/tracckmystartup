import { DocumentVerificationStatus } from '../types';
import { AutomatedDocumentVerification } from './automatedDocumentVerification';
import { AIDocumentVerification } from './aiDocumentVerification';

export interface HybridVerificationResult {
    status: DocumentVerificationStatus;
    confidence: number;
    reasons: string[];
    autoVerified: boolean;
    verificationMethod: 'automated' | 'ai' | 'manual' | 'hybrid';
    details: {
        automatedResult?: any;
        aiResult?: any;
        finalDecision: string;
    };
}

export class HybridDocumentVerification {
    
    // Main verification method that combines multiple approaches
    static async verifyDocument(file: File, documentType: string, options: {
        useAutomated?: boolean;
        useAI?: boolean;
        requireManual?: boolean;
        confidenceThreshold?: number;
    } = {}): Promise<HybridVerificationResult> {
        
        const {
            useAutomated = true,
            useAI = false,
            requireManual = false,
            confidenceThreshold = 0.8
        } = options;
        
        const results: any[] = [];
        const reasons: string[] = [];
        let finalStatus: DocumentVerificationStatus = DocumentVerificationStatus.Pending;
        let finalConfidence = 0.5;
        let autoVerified = false;
        let verificationMethod: 'automated' | 'ai' | 'manual' | 'hybrid' = 'manual';
        
        // Step 1: Automated validation
        if (useAutomated) {
            try {
                const automatedResult = await AutomatedDocumentVerification.validateFileContent(file, documentType);
                results.push({ type: 'automated', result: automatedResult });
                
                if (automatedResult.status === DocumentVerificationStatus.Rejected) {
                    return {
                        status: DocumentVerificationStatus.Rejected,
                        confidence: automatedResult.confidence,
                        reasons: automatedResult.reasons,
                        autoVerified: false,
                        verificationMethod: 'automated',
                        details: {
                            automatedResult,
                            finalDecision: 'Automated validation failed'
                        }
                    };
                }
                
                if (automatedResult.autoVerified && automatedResult.confidence >= confidenceThreshold) {
                    return {
                        status: DocumentVerificationStatus.Verified,
                        confidence: automatedResult.confidence,
                        reasons: automatedResult.reasons,
                        autoVerified: true,
                        verificationMethod: 'automated',
                        details: {
                            automatedResult,
                            finalDecision: 'Automated validation passed'
                        }
                    };
                }
                
                reasons.push(...automatedResult.reasons);
                finalConfidence = Math.max(finalConfidence, automatedResult.confidence);
                
            } catch (error) {
                console.error('Automated verification failed:', error);
                reasons.push('Automated verification failed');
            }
        }
        
        // Step 2: AI verification (if enabled)
        if (useAI) {
            try {
                const aiResult = await AIDocumentVerification.verifyWithAI(file, documentType);
                results.push({ type: 'ai', result: aiResult });
                
                if (aiResult.status === DocumentVerificationStatus.Rejected) {
                    return {
                        status: DocumentVerificationStatus.Rejected,
                        confidence: aiResult.confidence,
                        reasons: aiResult.reasons,
                        autoVerified: false,
                        verificationMethod: 'ai',
                        details: {
                            aiResult,
                            finalDecision: 'AI verification failed'
                        }
                    };
                }
                
                if (aiResult.autoVerified && aiResult.confidence >= confidenceThreshold) {
                    return {
                        status: DocumentVerificationStatus.Verified,
                        confidence: aiResult.confidence,
                        reasons: aiResult.reasons,
                        autoVerified: true,
                        verificationMethod: 'ai',
                        details: {
                            aiResult,
                            finalDecision: 'AI verification passed'
                        }
                    };
                }
                
                reasons.push(...aiResult.reasons);
                finalConfidence = Math.max(finalConfidence, aiResult.confidence);
                
            } catch (error) {
                console.error('AI verification failed:', error);
                reasons.push('AI verification failed');
            }
        }
        
        // Step 3: Determine final status
        if (requireManual || finalConfidence < confidenceThreshold) {
            finalStatus = DocumentVerificationStatus.UnderReview;
            verificationMethod = 'manual';
            reasons.push('Manual review required');
        } else if (finalConfidence >= confidenceThreshold) {
            finalStatus = DocumentVerificationStatus.Verified;
            autoVerified = true;
            verificationMethod = results.length > 1 ? 'hybrid' : (useAI ? 'ai' : 'automated');
            reasons.push('Document verified through automated process');
        } else {
            finalStatus = DocumentVerificationStatus.UnderReview;
            verificationMethod = 'manual';
            reasons.push('Confidence score below threshold');
        }
        
        return {
            status: finalStatus,
            confidence: finalConfidence,
            reasons: reasons,
            autoVerified: autoVerified,
            verificationMethod: verificationMethod,
            details: {
                automatedResult: results.find(r => r.type === 'automated')?.result,
                aiResult: results.find(r => r.type === 'ai')?.result,
                finalDecision: `Final decision based on ${verificationMethod} verification`
            }
        };
    }
    
    // Quick verification for low-risk documents
    static async quickVerify(file: File, documentType: string): Promise<HybridVerificationResult> {
        return this.verifyDocument(file, documentType, {
            useAutomated: true,
            useAI: false,
            requireManual: false,
            confidenceThreshold: 0.7
        });
    }
    
    // Full verification with AI for high-risk documents
    static async fullVerify(file: File, documentType: string): Promise<HybridVerificationResult> {
        return this.verifyDocument(file, documentType, {
            useAutomated: true,
            useAI: true,
            requireManual: false,
            confidenceThreshold: 0.8
        });
    }
    
    // Manual verification required
    static async requireManualVerify(file: File, documentType: string): Promise<HybridVerificationResult> {
        return this.verifyDocument(file, documentType, {
            useAutomated: true,
            useAI: true,
            requireManual: true,
            confidenceThreshold: 0.9
        });
    }
    
    // Get verification strategy based on document type
    static getVerificationStrategy(documentType: string): {
        useAutomated: boolean;
        useAI: boolean;
        requireManual: boolean;
        confidenceThreshold: number;
    } {
        const strategies: Record<string, any> = {
            'compliance_document': {
                useAutomated: true,
                useAI: false,
                requireManual: false,
                confidenceThreshold: 0.7
            },
            'ip_trademark_document': {
                useAutomated: true,
                useAI: true,
                requireManual: false,
                confidenceThreshold: 0.8
            },
            'financial_document': {
                useAutomated: true,
                useAI: true,
                requireManual: true,
                confidenceThreshold: 0.9
            },
            'government_id': {
                useAutomated: true,
                useAI: true,
                requireManual: true,
                confidenceThreshold: 0.95
            },
            'license_document': {
                useAutomated: true,
                useAI: true,
                requireManual: false,
                confidenceThreshold: 0.8
            }
        };
        
        return strategies[documentType] || {
            useAutomated: true,
            useAI: false,
            requireManual: true,
            confidenceThreshold: 0.8
        };
    }
    
    // Verify with strategy
    static async verifyWithStrategy(file: File, documentType: string): Promise<HybridVerificationResult> {
        const strategy = this.getVerificationStrategy(documentType);
        return this.verifyDocument(file, documentType, strategy);
    }
}

export const hybridDocumentVerification = new HybridDocumentVerification();

