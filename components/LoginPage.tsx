import React, { useState } from 'react';
import { authService, AuthUser } from '../lib/auth';
import Card from './ui/Card';
import Input from './ui/Input';
import Button from './ui/Button';
import { Briefcase, Loader2 } from 'lucide-react';

interface LoginPageProps {
    onLogin: (user: AuthUser) => void;
    onNavigateToRegister: () => void;
}

const LoginPage: React.FC<LoginPageProps> = ({ onLogin, onNavigateToRegister }) => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [isRedirecting, setIsRedirecting] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);
        setError(null);
        setIsRedirecting(false);

        // Add timeout to prevent UI from getting stuck
        const timeoutId = setTimeout(() => {
            setIsLoading(false);
            setError('Login timed out. Please try again.');
        }, 10000); // 10 second timeout

        try {
            const { user, error: loginError } = await authService.signInMinimal({ email, password });
            
            clearTimeout(timeoutId); // Clear timeout if login completes
            
            if (user) {
                onLogin(user);
            } else if (loginError) {
                setError(loginError);
                
                // If user doesn't exist, suggest registration
                if (loginError.includes('does not exist') || loginError.includes('Please register first')) {
                    setIsRedirecting(true);
                    // Auto-redirect to registration after 3 seconds
                    setTimeout(() => {
                        onNavigateToRegister();
                    }, 3000);
                }
            }
        } catch (err: any) {
            clearTimeout(timeoutId); // Clear timeout on error
            console.error('Login error:', err);
            setError(err.message || 'An unexpected error occurred. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Card className="w-full max-w-md">
            <div className="text-center mb-8">
                <Briefcase className="mx-auto h-12 w-12 text-brand-primary" />
                <h2 className="mt-4 text-3xl font-bold tracking-tight text-slate-900">Sign in to your account</h2>
                <p className="mt-2 text-sm text-slate-600">
                    Or{' '}
                    <button onClick={onNavigateToRegister} className="font-medium text-brand-primary hover:text-brand-secondary">
                        create a new account
                    </button>
                </p>
            </div>
            <form onSubmit={handleSubmit} className="space-y-6">
                <Input 
                    label="Email address"
                    id="email"
                    type="email"
                    autoComplete="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                />
                <Input 
                    label="Password"
                    id="password"
                    type="password"
                    autoComplete="current-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                />

                {error && (
                    <div className="bg-red-50 border border-red-200 rounded-md p-3">
                        <p className="text-red-800 text-sm">{error}</p>
                        {isRedirecting && (
                            <div className="flex items-center gap-2 mt-2">
                                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-red-600"></div>
                                <p className="text-red-600 text-xs">
                                    Redirecting to registration...
                                </p>
                            </div>
                        )}
                    </div>
                )}

                <div>
                    <Button type="submit" className="w-full" disabled={isLoading || isRedirecting}>
                        {isLoading ? (
                            <>
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                Signing in...
                            </>
                        ) : isRedirecting ? (
                            <>
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                Redirecting...
                            </>
                        ) : (
                            'Sign in'
                        )}
                    </Button>
                </div>
            </form>
        </Card>
    );
};

export default LoginPage;