import React from 'react';
import { AlertCircle, Mail, CheckCircle } from 'lucide-react';

interface EmailConfirmationBannerProps {
  isEmailConfirmed: boolean;
  email: string;
  onResendEmail?: () => void;
}

export const EmailConfirmationBanner: React.FC<EmailConfirmationBannerProps> = ({
  isEmailConfirmed,
  email,
  onResendEmail
}) => {
  if (isEmailConfirmed) {
    return (
      <div className="bg-green-50 border border-green-200 rounded-md p-4 mb-4">
        <div className="flex items-center">
          <CheckCircle className="h-5 w-5 text-green-400 mr-2" />
          <div className="text-sm text-green-800">
            <strong>Email confirmed!</strong> Your account is fully verified.
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4 mb-4">
      <div className="flex items-start">
        <AlertCircle className="h-5 w-5 text-yellow-400 mr-2 mt-0.5" />
        <div className="flex-1">
          <div className="text-sm text-yellow-800">
            <strong>Please confirm your email address.</strong>
            <br />
            We sent a confirmation link to <strong>{email}</strong>
          </div>
          <div className="mt-2 text-xs text-yellow-600">
            You can use the app while waiting, but please check your email and click the confirmation link.
          </div>
          {onResendEmail && (
            <button
              onClick={onResendEmail}
              className="mt-2 inline-flex items-center text-xs text-yellow-700 hover:text-yellow-800 underline"
            >
              <Mail className="h-3 w-3 mr-1" />
              Resend confirmation email
            </button>
          )}
        </div>
      </div>
    </div>
    );
};
