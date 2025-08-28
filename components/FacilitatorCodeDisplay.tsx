import React, { useEffect, useState } from 'react';
import { facilitatorCodeService } from '../lib/facilitatorCodeService';
import { AuthUser } from '../lib/auth';

interface FacilitatorCodeDisplayProps {
    className?: string;
    currentUser?: AuthUser | null;
}

export const FacilitatorCodeDisplay: React.FC<FacilitatorCodeDisplayProps> = ({ className = '', currentUser }) => {
    const [facilitatorCode, setFacilitatorCode] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const loadFacilitatorCode = async () => {
            if (currentUser?.id) {
                try {
                    const code = await facilitatorCodeService.getFacilitatorCodeByUserId(currentUser.id);
                    setFacilitatorCode(code);
                } catch (error) {
                    console.error('Error loading facilitator code:', error);
                } finally {
                    setLoading(false);
                }
            } else {
                setLoading(false);
            }
        };

        loadFacilitatorCode();
    }, [currentUser?.id]);

    if (loading) {
        return (
            <div className={`bg-blue-100 text-blue-800 px-3 py-1 rounded-md text-sm font-medium ${className}`}>
                Loading...
            </div>
        );
    }

    if (!facilitatorCode) {
        return null;
    }

    return (
        <div className={`bg-blue-100 text-blue-800 px-3 py-1 rounded-md text-sm font-medium ${className}`}>
            Facilitator Code: <span className="font-bold">{facilitatorCode}</span>
        </div>
    );
};
