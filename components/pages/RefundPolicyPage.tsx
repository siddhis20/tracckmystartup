import React from 'react';
import { ArrowLeft } from 'lucide-react';

const RefundPolicyPage: React.FC = () => {
  const handleBack = () => {
    window.history.back();
  };

  return (
    <div className="min-h-screen bg-slate-50">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <button
          onClick={handleBack}
          className="flex items-center gap-2 text-brand-primary hover:text-brand-secondary mb-6 transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          Back
        </button>

        <div className="max-w-4xl mx-auto">
          <h1 className="text-3xl font-bold text-slate-900 mb-2">Refund Policy</h1>
          <p className="text-slate-600 mb-8">E AND P Community Farms</p>

          <div className="bg-white rounded-lg shadow-sm p-6 sm:p-8">
            <div className="prose prose-slate max-w-none">
              <h2 className="text-xl font-semibold text-slate-900 mb-4">Refund Eligibility</h2>
              <p className="text-slate-600 mb-4">
                E AND P Community Farms offers refunds for products and services under specific conditions. 
                Refunds must be requested within 30 days of purchase.
              </p>

              <h2 className="text-xl font-semibold text-slate-900 mb-4">Refund Process</h2>
              <p className="text-slate-600 mb-4">
                To request a refund, please contact our customer service team with your order number and reason for the refund. 
                We will review your request and process approved refunds within 5-7 business days.
              </p>

              <h2 className="text-xl font-semibold text-slate-900 mb-4">Non-Refundable Items</h2>
              <p className="text-slate-600 mb-4">
                Custom orders, digital products, and services that have been fully delivered are generally not eligible for refunds. 
                Please contact us for specific cases.
              </p>

              <h2 className="text-xl font-semibold text-slate-900 mb-4">Refund Methods</h2>
              <p className="text-slate-600 mb-4">
                Refunds will be processed using the same payment method used for the original purchase. 
                Processing times may vary depending on your financial institution.
              </p>

              <h2 className="text-xl font-semibold text-slate-900 mb-4">Contact Us</h2>
              <p className="text-slate-600">
                For refund requests or questions about this policy, please contact us at:
                <br />
                Email: <a href="mailto:support@trackmystartup.com" className="text-brand-primary hover:underline">support@trackmystartup.com</a>
                <br />
                Phone: <a href="tel:+919146169956" className="text-brand-primary hover:underline">+91 91461 69956</a>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RefundPolicyPage;
