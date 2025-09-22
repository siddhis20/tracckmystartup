import React, { useState } from 'react';
import { UserRole } from '../types';
import { authService, AuthUser } from '../lib/auth';
import Card from './ui/Card';
import Input from './ui/Input';
import Select from './ui/Select';
import Button from './ui/Button';
import { UserPlus, Loader2 } from 'lucide-react';

interface CompleteProfilePageProps {
    onProfileComplete: (user: AuthUser) => void;
}

const CompleteProfilePage: React.FC<CompleteProfilePageProps> = ({ onProfileComplete }) => {
    const [name, setName] = useState('');
    const [role, setRole] = useState<UserRole>('Investor');
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);
        setError(null);

        try {
            const { user, error: profileError } = await authService.createProfile(name, role);
            
            if (profileError) {
                setError(profileError);
            } else if (user) {
                onProfileComplete(user);
            } else {
                setError('Failed to create profile. Please try again.');
            }
        } catch (err: any) {
            console.error('Profile creation error:', err);
            setError(err.message || 'An unexpected error occurred. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Card className="w-full max-w-md">
            <div className="text-center mb-8">
                <UserPlus className="mx-auto h-12 w-12 text-brand-primary" />
                <h2 className="mt-4 text-2xl font-bold tracking-tight text-slate-900">Complete Your Profile</h2>
                <p className="mt-2 text-sm text-slate-600">
                    Please provide your details to complete your account setup
                </p>
            </div>
            <form onSubmit={handleSubmit} className="space-y-6">
                <Input 
                    label="Full Name"
                    id="name"
                    type="text"
                    autoComplete="name"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                />
                <Select
                    label="Role"
                    id="role"
                    value={role}
                    onChange={(e) => setRole(e.target.value as UserRole)}
                    required
                >
                    <option value="Investor">Investor</option>
                    <option value="Startup">Startup</option>
                    <option value="CA">CA</option>
                    <option value="CS">CS</option>
                    <option value="Startup Facilitation Center">Startup Facilitation Center</option>
                    <option value="Investment Advisor">Investment Advisor</option>
                </Select>

                {error && (
                    <div className="bg-red-50 border border-red-200 rounded-md p-3">
                        <p className="text-red-800 text-sm">{error}</p>
                    </div>
                )}

                <div>
                    <Button type="submit" className="w-full" disabled={isLoading}>
                        {isLoading ? (
                            <>
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                Creating Profile...
                            </>
                        ) : (
                            'Complete Profile'
                        )}
                    </Button>
                </div>
            </form>
        </Card>
    );
};

export default CompleteProfilePage;
