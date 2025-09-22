import React from 'react';
import { Briefcase, BarChart3, Users, TrendingUp, Shield, Globe, ArrowRight } from 'lucide-react';
import Button from './ui/Button';
import LogoTMS from './public/logoTMS.svg';

interface LandingPageProps {
  onNavigateToLogin: () => void;
  onNavigateToRegister: () => void;
}

const LandingPage: React.FC<LandingPageProps> = ({ onNavigateToLogin, onNavigateToRegister }) => {
  return (
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <header className="bg-white shadow-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-3 sm:py-4 flex justify-between items-center">
          <div className="flex items-center gap-2 sm:gap-3">
            <img 
              src={LogoTMS} 
              alt="TrackMyStartup" 
              className="h-7 w-7 sm:h-8 sm:w-8 scale-[5] sm:scale-[5] origin-left cursor-pointer hover:opacity-80 transition-opacity" 
              onClick={() => window.location.reload()}
            />
          </div>
          <div className="flex items-center gap-2 sm:gap-4">
            <Button 
              variant="outline" 
              size="sm" 
              onClick={onNavigateToLogin}
              className="hidden sm:inline-flex"
            >
              Login
            </Button>
            <Button 
              variant="primary" 
              size="sm" 
              onClick={onNavigateToRegister}
              className="px-3 py-1.5"
            >
              Get Started
            </Button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="py-12 sm:py-16 lg:py-20 px-4 sm:px-6 lg:px-8">
        <div className="container mx-auto text-center">
          <div className="max-w-4xl mx-auto">
            <h1 className="text-3xl sm:text-5xl lg:text-6xl font-bold text-slate-900 mb-4 sm:mb-6">
              Track Your Startup's
              <span className="text-brand-primary block">Growth Journey</span>
            </h1>
            <p className="text-base sm:text-xl text-slate-600 mb-6 sm:mb-8 max-w-2xl mx-auto">
              Comprehensive startup tracking platform for investors, founders, and professionals. 
              Monitor compliance, track investments, and manage your startup ecosystem all in one place.
            </p>
            <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center">
              <Button 
                variant="primary" 
                size="md" 
                onClick={onNavigateToRegister}
                className="group w-full sm:w-auto"
              >
                Start Now
                <ArrowRight className="ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform" />
              </Button>
              <Button 
                variant="outline" 
                size="md" 
                onClick={onNavigateToLogin}
                className="w-full sm:w-auto"
              >
                Sign In
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-12 sm:py-16 lg:py-20 px-4 sm:px-6 lg:px-8 bg-white">
        <div className="container mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-2xl sm:text-4xl font-bold text-slate-900 mb-3 sm:mb-4">
              Everything You Need to Track
            </h2>
            <p className="text-base sm:text-xl text-slate-600 max-w-2xl mx-auto">
              From compliance monitoring to investment tracking, we've got you covered
            </p>
          </div>
          
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 sm:gap-8">
            <div className="text-center p-5 sm:p-6">
              <div className="w-16 h-16 mx-auto mb-4 bg-brand-primary/10 rounded-full flex items-center justify-center">
                <BarChart3 className="h-8 w-8 text-brand-primary" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-2">Portfolio Management</h3>
              <p className="text-slate-600">
                Track all your startup investments in one comprehensive dashboard with real-time updates.
              </p>
            </div>
            
            <div className="text-center p-5 sm:p-6">
              <div className="w-16 h-16 mx-auto mb-4 bg-brand-primary/10 rounded-full flex items-center justify-center">
                <Shield className="h-8 w-8 text-brand-primary" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-2">Compliance Tracking</h3>
              <p className="text-slate-600">
                Stay compliant with automated compliance monitoring and task management for your startups.
              </p>
            </div>
            
            <div className="text-center p-5 sm:p-6">
              <div className="w-16 h-16 mx-auto mb-4 bg-brand-primary/10 rounded-full flex items-center justify-center">
                <TrendingUp className="h-8 w-8 text-brand-primary" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-2">Performance Analytics</h3>
              <p className="text-slate-600">
                Get insights into your startup's financial health and growth metrics with detailed analytics.
              </p>
            </div>
            
            <div className="text-center p-5 sm:p-6">
              <div className="w-16 h-16 mx-auto mb-4 bg-brand-primary/10 rounded-full flex items-center justify-center">
                <Users className="h-8 w-8 text-brand-primary" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-2">Team Collaboration</h3>
              <p className="text-slate-600">
                Collaborate with CA, CS, and facilitation teams for seamless startup management.
              </p>
            </div>
            
            <div className="text-center p-5 sm:p-6">
              <div className="w-16 h-16 mx-auto mb-4 bg-brand-primary/10 rounded-full flex items-center justify-center">
                <Globe className="h-8 w-8 text-brand-primary" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-2">Global Compliance</h3>
              <p className="text-slate-600">
                Support for multiple countries and compliance frameworks including Canada, India, and US.
              </p>
            </div>
            
            <div className="text-center p-5 sm:p-6">
              <div className="w-16 h-16 mx-auto mb-4 bg-brand-primary/10 rounded-full flex items-center justify-center">
                <Briefcase className="h-8 w-8 text-brand-primary" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-2">Investment Opportunities</h3>
              <p className="text-slate-600">
                Discover and invest in promising startups with our comprehensive investment platform.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-12 sm:py-16 lg:py-20 px-4 sm:px-6 lg:px-8 bg-slate-100">
        <div className="container mx-auto text-center">
          <div className="max-w-3xl mx-auto">
            <h2 className="text-2xl sm:text-4xl font-bold text-slate-900 mb-3 sm:mb-4">
              Ready to Transform Your Startup Tracking?
            </h2>
            <p className="text-base sm:text-xl text-slate-600 mb-6 sm:mb-8">
              Join thousands of investors and founders who trust TrackMyStartup to manage their startup ecosystem.
            </p>
            <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center">
              <Button 
                variant="primary" 
                size="md" 
                onClick={onNavigateToRegister}
                className="group w-full sm:w-auto"
              >
                Get Started Today
                <ArrowRight className="ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform" />
              </Button>
              <Button 
                variant="outline" 
                size="md" 
                onClick={onNavigateToLogin}
                className="w-full sm:w-auto"
              >
                Already have an account? Sign In
              </Button>
            </div>
          </div>
        </div>
      </section>

    </div>
  );
};

export default LandingPage;


