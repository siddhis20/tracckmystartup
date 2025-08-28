import React, { useState } from 'react';
import Card from './ui/Card';
import Button from './ui/Button';
import Input from './ui/Input';
import { UserRole } from '../types';
import { Mail, CheckCircle } from 'lucide-react';
import LogoTMS from './public/logoTMS.svg';
import { authService } from '../lib/auth';

interface BasicRegistrationStepProps {
  onEmailVerified: (userData: {
    name: string;
    email: string;
    password: string;
    role: UserRole;
    startupName?: string;
    country: string;
  }) => void;
  onNavigateToLogin: () => void;
  onNavigateToLanding?: () => void;
}

export const BasicRegistrationStep: React.FC<BasicRegistrationStepProps> = ({
  onEmailVerified,
  onNavigateToLogin,
  onNavigateToLanding
}) => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    country: 'India',
    role: 'Investor' as UserRole,
    startupName: ''
  });

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [emailSent, setEmailSent] = useState(false);

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    // Validation
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      setIsLoading(false);
      return;
    }

    if (formData.role === 'Startup' && !formData.startupName.trim()) {
      setError('Startup name is required for Startup role');
      setIsLoading(false);
      return;
    }

    try {
      // Create user account with email verification required
      const { user, error: signUpError, confirmationRequired } = await authService.signUp({
        email: formData.email,
        password: formData.password,
        name: formData.name,
        role: formData.role,
        startupName: formData.role === 'Startup' ? formData.startupName : undefined,
        founders: [],
        fileUrls: {}
      });

      if (signUpError) {
        setError(signUpError);
        setIsLoading(false);
        return;
      }

      if (confirmationRequired) {
        // Email confirmation required - show verification screen
        setEmailSent(true);
        setShowConfirmation(true);
        console.log('Email verification required for:', formData.email);
        // User needs to verify email, then login separately
      } else if (user) {
        // User already verified - move to Step 2
        onEmailVerified({
          name: formData.name,
          email: formData.email,
          password: formData.password,
          role: formData.role,
          startupName: formData.role === 'Startup' ? formData.startupName : undefined,
          country: formData.country
        });
      }

    } catch (err: any) {
      setError(err.message || 'An error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  if (showConfirmation) {
    return (
      <Card className="w-full max-w-md">
        <div className="text-center">
          <Mail className="mx-auto h-12 w-12 text-blue-500" />
          <h2 className="mt-4 text-2xl font-bold text-slate-900">Check Your Email</h2>
          <p className="mt-2 text-sm text-slate-600">
            We've sent a verification link to <strong>{formData.email}</strong>
          </p>
          <p className="mt-4 text-xs text-slate-500">
            Please check your email and click the verification link to continue.
          </p>
          {emailSent && (
            <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded-md">
              <div className="flex items-center text-green-800">
                <CheckCircle className="h-4 w-4 mr-2" />
                <span className="text-sm">Verification email sent successfully!</span>
              </div>
            </div>
          )}
          
          {/* Email Verification Instructions */}
          <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-md">
            <p className="text-sm text-blue-800 mb-3">
              <strong>Next Steps:</strong>
            </p>
            <p className="text-xs text-blue-600">
              1. Check your email for the verification link<br/>
              2. Click the verification link in your email<br/>
              3. Come back here and click "Continue to Login"
            </p>
          </div>
          
          {/* Continue to Login Button */}
          <div className="mt-4">
            <Button
              onClick={() => {
                setShowConfirmation(false);
                setEmailSent(false);
                onNavigateToLogin();
              }}
              className="w-full"
            >
              Continue to Login
            </Button>
          </div>
          
          {/* Back to Form Button */}
          <div className="mt-4">
            <button
              onClick={() => {
                setShowConfirmation(false);
                setEmailSent(false);
              }}
              className="text-sm text-slate-500 hover:text-slate-700 underline"
            >
              ← Back to Registration Form
            </button>
          </div>
        </div>
      </Card>
    );
  }

  return (
    <>
      {onNavigateToLanding && (
        <div className="w-full max-w-2xl mx-auto mb-4">
          <button
            onClick={onNavigateToLanding}
            className="text-sm text-slate-500 hover:text-slate-700 underline"
            aria-label="Back to Landing"
          >
            ← Back to Landing
          </button>
        </div>
      )}
    <Card className="w-full max-w-2xl">
      <div className="text-center mb-8">
        <img src={LogoTMS} alt="TrackMyStartup" className="mx-auto h-40 w-40" />
        <h2 className="mt-4 text-3xl font-bold tracking-tight text-slate-900">Create a new account</h2>
        <p className="mt-2 text-sm text-slate-600">
          Or{' '}
          <button
            onClick={onNavigateToLogin}
            className="text-brand-primary hover:text-brand-primary-dark underline"
          >
            sign in to your existing account
          </button>
        </p>
        {onNavigateToLanding && (
          <p className="mt-2 text-xs text-slate-500">
            <button
              onClick={onNavigateToLanding}
              className="underline hover:text-slate-700"
            >
              ← Back to Landing
            </button>
          </p>
        )}
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Basic Information */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Input
            label="Full Name"
            id="name"
            name="name"
            type="text"
            required
            value={formData.name}
            onChange={(e) => handleInputChange('name', e.target.value)}
          />
          
          <Input
            label="Email address"
            id="email"
            name="email"
            type="email"
            required
            value={formData.email}
            onChange={(e) => handleInputChange('email', e.target.value)}
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Input
            label="Password"
            id="password"
            name="password"
            type="password"
            required
            value={formData.password}
            onChange={(e) => handleInputChange('password', e.target.value)}
          />
          
          <Input
            label="Confirm Password"
            id="confirmPassword"
            name="confirmPassword"
            type="password"
            required
            value={formData.confirmPassword}
            onChange={(e) => handleInputChange('confirmPassword', e.target.value)}
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label htmlFor="country" className="block text-sm font-medium text-slate-700 mb-2">
              Country
            </label>
            <select
              id="country"
              name="country"
              required
              value={formData.country}
              onChange={(e) => handleInputChange('country', e.target.value)}
              className="block w-full px-3 py-2 border border-slate-300 rounded-md shadow-sm focus:outline-none focus:ring-brand-primary focus:border-brand-primary"
            >
              <option value="India">India</option>
              <option value="USA">USA</option>
              <option value="UK">UK</option>
              <option value="Canada">Canada</option>
              <option value="Australia">Australia</option>
            </select>
          </div>

          <div>
            <label htmlFor="role" className="block text-sm font-medium text-slate-700 mb-2">
              Role
            </label>
            <select
              id="role"
              name="role"
              required
              value={formData.role}
              onChange={(e) => handleInputChange('role', e.target.value as UserRole)}
              className="block w-full px-3 py-2 border border-slate-300 rounded-md shadow-sm focus:outline-none focus:ring-brand-primary focus:border-brand-primary"
            >
              <option value="Investor">Investor</option>
              <option value="Startup">Startup</option>
              <option value="CA">CA</option>
              <option value="CS">CS</option>
              <option value="Startup Facilitation Center">Startup Facilitation Center</option>
            </select>
          </div>
        </div>

        {/* Startup Name - Only show if role is Startup */}
        {formData.role === 'Startup' && (
          <Input
            label="Startup Name"
            id="startupName"
            name="startupName"
            type="text"
            required
            placeholder="Enter your startup name"
            value={formData.startupName}
            onChange={(e) => handleInputChange('startupName', e.target.value)}
          />
        )}

        {/* Error Display */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-md p-4">
            <div className="text-sm text-red-800">
              <strong>Error:</strong> {error}
            </div>
          </div>
        )}

        {/* Submit Button */}
        <Button
          type="submit"
          className="w-full"
          disabled={isLoading}
        >
          {isLoading ? 'Creating Account...' : 'Create Account'}
        </Button>
      </form>
    </Card>
    </>
  );
};
