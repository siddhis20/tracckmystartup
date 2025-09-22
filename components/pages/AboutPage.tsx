import React from 'react';
import { ArrowLeft, Users, Target, Award } from 'lucide-react';

const AboutPage: React.FC = () => {
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
          <h1 className="text-3xl font-bold text-slate-900 mb-2">About Us</h1>
          <p className="text-slate-600 mb-8">Track My Startup</p>

          <div className="bg-white rounded-lg shadow-sm p-6 sm:p-8 mb-8">
            <div className="prose prose-slate max-w-none">
              <h2 className="text-xl font-semibold text-slate-900 mb-4">About Track My Startup</h2>
              <p className="text-slate-600 mb-6">
                Track My Startup is a comprehensive platform designed to facilitate early-stage startups and mentor first-time founders. 
                We bridge the gap between academia and industry through startup facilitation, research collaboration, student entrepreneurship, 
                and professional training programs.
              </p>

              <h2 className="text-xl font-semibold text-slate-900 mb-4">Our Mission</h2>
              <p className="text-slate-600 mb-6">
                We are dedicated to empowering the startup ecosystem by providing robust tools for compliance monitoring, investment tracking, 
                and startup health assessment. Our platform serves investors, incubators, startups, and other stakeholders in creating a 
                more transparent and efficient startup ecosystem.
              </p>

              <h2 className="text-xl font-semibold text-slate-900 mb-4">Leadership</h2>
              <div className="bg-slate-50 rounded-lg p-6 mb-6">
                <h3 className="text-lg font-semibold text-slate-900 mb-3">Dr. Saeel Ismail Momin</h3>
                <p className="text-slate-600 mb-4">
                  <strong>Founder & CEO</strong><br />
                  Polymer scientist with over 9 years of global research experience and 3 years of entrepreneurial experience. 
                  Dr. Momin's expertise lies in polymer science, macromolecules, and nanotechnology.
                </p>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                  <div>
                    <h4 className="font-semibold text-slate-900 mb-2">Education</h4>
                    <ul className="text-sm text-slate-600 space-y-1">
                      <li>• PhD. Polymer Chemistry (University of Strasbourg, France)</li>
                      <li>• MSc. Sustainable Materials Polymer Science (University of Freiburg, Germany)</li>
                      <li>• Graduate Diploma in Science (University of Sydney, Australia)</li>
                      <li>• BSc. Chemistry (University of Sydney, Australia)</li>
                    </ul>
                  </div>
                  <div>
                    <h4 className="font-semibold text-slate-900 mb-2">Key Achievements</h4>
                    <ul className="text-sm text-slate-600 space-y-1">
                      <li>• Led Startup Nation Olympiad 2025 (World's Largest Startup Competition)</li>
                      <li>• India-Australia RISE Accelerator Grant (45 Lakhs)</li>
                      <li>• Startup India Seed Fund (10 Lakhs)</li>
                      <li>• National Finalist UNDP Youth Co:Lab 2022</li>
                    </ul>
                  </div>
                </div>

                <div className="mb-4">
                  <h4 className="font-semibold text-slate-900 mb-2">Patents & Innovations</h4>
                  <ul className="text-sm text-slate-600 space-y-1">
                    <li>• Process for developing self-stratifying aqueous coating (India: 558402)</li>
                    <li>• High speed and high accuracy humidity sensor (World: WO2024156677)</li>
                    <li>• Process to convert waste leachate into plant growth promoter (India: 558759)</li>
                    <li>• Carbon negative food waste processing system (India: IN202121018361)</li>
                  </ul>
                </div>

                <p className="text-slate-600 text-sm">
                  <strong>Languages:</strong> English, Hindi, Marathi, Urdu, French<br />
                  <strong>Specialization:</strong> Problem-solving social issues with robust industrial know-how, 
                  promoting academia-industry collaboration through startup facilitation and research.
                </p>
              </div>

              <h2 className="text-xl font-semibold text-slate-900 mb-4">What We Do</h2>
              <p className="text-slate-600 mb-6">
                E&P Community Farms provides comprehensive services including compliance monitoring, investment tracking, 
                startup health assessment, and mentorship programs. We work with a network of 400+ educational institutions, 
                300+ founders, and 250+ incubation centers and investors across Asia, Africa, Europe, Middle-East, and Oceania.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div className="bg-white rounded-lg shadow-sm p-6 text-center">
              <div className="w-12 h-12 bg-brand-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                <Users className="h-6 w-6 text-brand-primary" />
              </div>
              <h3 className="text-lg font-semibold text-slate-900 mb-2">Global Network</h3>
              <p className="text-slate-600 text-sm">
                We work with 400+ educational institutions, 300+ founders, and 250+ incubation centers across multiple continents.
              </p>
            </div>

            <div className="bg-white rounded-lg shadow-sm p-6 text-center">
              <div className="w-12 h-12 bg-brand-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                <Target className="h-6 w-6 text-brand-primary" />
              </div>
              <h3 className="text-lg font-semibold text-slate-900 mb-2">Research-Driven</h3>
              <p className="text-slate-600 text-sm">
                Our solutions are backed by 9+ years of global research experience and cutting-edge polymer science expertise.
              </p>
            </div>

            <div className="bg-white rounded-lg shadow-sm p-6 text-center">
              <div className="w-12 h-12 bg-brand-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                <Award className="h-6 w-6 text-brand-primary" />
              </div>
              <h3 className="text-lg font-semibold text-slate-900 mb-2">Proven Track Record</h3>
              <p className="text-slate-600 text-sm">
                Led the world's largest startup competition and secured multiple grants including India-Australia RISE Accelerator.
              </p>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm p-6 sm:p-8">
            <h2 className="text-xl font-semibold text-slate-900 mb-4">Contact Us</h2>
            <p className="text-slate-600">
              Ready to learn more about E&P Community Farms? We'd love to hear from you.
              <br />
              General Support: <a href="mailto:support@trackmystartup.com" className="text-brand-primary hover:underline">support@trackmystartup.com</a>
              <br />
              Startup Support: <a href="mailto:startup@trackmystartup.com" className="text-brand-primary hover:underline">startup@trackmystartup.com</a>
              <br />
              Investor Relations: <a href="mailto:investor@trackmystartup.com" className="text-brand-primary hover:underline">investor@trackmystartup.com</a>
              <br />
              Phone: <a href="tel:+919146169956" className="text-brand-primary hover:underline">+91 91461 69956</a>
              <br />
              Address: E&P Community Farms, 1956/2 Wada Road, Rajgurunagar 410505, India
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AboutPage;
