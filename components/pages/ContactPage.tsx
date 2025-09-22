import React, { useState } from 'react';
import { ArrowLeft, Mail, Phone, MapPin, Send } from 'lucide-react';

const ContactPage: React.FC = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    subject: '',
    message: ''
  });

  const handleBack = () => {
    window.history.back();
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Handle form submission here
    alert('Thank you for your message! We will get back to you soon.');
    setFormData({ name: '', email: '', subject: '', message: '' });
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
          <h1 className="text-3xl font-bold text-slate-900 mb-2">Contact Us</h1>
          <p className="text-slate-600 mb-8">E&P Community Farms</p>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Contact Information */}
            <div className="space-y-6">
              <div className="bg-white rounded-lg shadow-sm p-6">
                <h2 className="text-xl font-semibold text-slate-900 mb-4">Get in Touch</h2>
                <p className="text-slate-600 mb-6">
                  We'd love to hear from you. Send us a message and we'll respond as soon as possible.
                </p>

                <div className="space-y-4">
                  <div className="flex items-start space-x-3">
                    <a href="mailto:support@trackmystartup.com" className="flex items-start space-x-3 hover:opacity-80 transition-opacity">
                      <Mail className="h-5 w-5 text-brand-primary mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-slate-600 text-sm">General Support</p>
                        <p className="text-slate-900 font-medium">support@trackmystartup.com</p>
                      </div>
                    </a>
                  </div>

                  <div className="flex items-start space-x-3">
                    <a href="mailto:startup@trackmystartup.com" className="flex items-start space-x-3 hover:opacity-80 transition-opacity">
                      <Mail className="h-5 w-5 text-brand-primary mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-slate-600 text-sm">Startup Support</p>
                        <p className="text-slate-900 font-medium">startup@trackmystartup.com</p>
                      </div>
                    </a>
                  </div>

                  <div className="flex items-start space-x-3">
                    <a href="mailto:investor@trackmystartup.com" className="flex items-start space-x-3 hover:opacity-80 transition-opacity">
                      <Mail className="h-5 w-5 text-brand-primary mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-slate-600 text-sm">Investor Relations</p>
                        <p className="text-slate-900 font-medium">investor@trackmystartup.com</p>
                      </div>
                    </a>
                  </div>

                  <div className="flex items-start space-x-3">
                    <a href="mailto:incubation_center@trackmystartup.com" className="flex items-start space-x-3 hover:opacity-80 transition-opacity">
                      <Mail className="h-5 w-5 text-brand-primary mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-slate-600 text-sm">Incubation Centers</p>
                        <p className="text-slate-900 font-medium">incubation_center@trackmystartup.com</p>
                      </div>
                    </a>
                  </div>

                  <div className="flex items-start space-x-3">
                    <a href="mailto:investment_advisor@trackmystartup.com" className="flex items-start space-x-3 hover:opacity-80 transition-opacity">
                      <Mail className="h-5 w-5 text-brand-primary mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-slate-600 text-sm">Investment Advisors</p>
                        <p className="text-slate-900 font-medium">investment_advisor@trackmystartup.com</p>
                      </div>
                    </a>
                  </div>

                  <div className="flex items-start space-x-3">
                    <a href="tel:+919146169956" className="flex items-start space-x-3 hover:opacity-80 transition-opacity">
                      <Phone className="h-5 w-5 text-brand-primary mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-slate-600 text-sm">Phone</p>
                        <p className="text-slate-900 font-medium">+91 91461 69956</p>
                      </div>
                    </a>
                  </div>

                  <div className="flex items-start space-x-3">
                    <MapPin className="h-5 w-5 text-brand-primary mt-0.5 flex-shrink-0" />
                    <div>
                      <p className="text-slate-600 text-sm">Address</p>
                      <p className="text-slate-900 font-medium">
                        E&P Community Farms<br />
                        1956/2 Wada Road<br />
                        Rajgurunagar 410505, India
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg shadow-sm p-6">
                <h3 className="text-lg font-semibold text-slate-900 mb-3">Business Hours</h3>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-slate-600">Monday - Friday</span>
                    <span className="text-slate-900">8:00 AM - 6:00 PM</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-600">Saturday</span>
                    <span className="text-slate-900">9:00 AM - 4:00 PM</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-600">Sunday</span>
                    <span className="text-slate-900">Closed</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Contact Form */}
            <div className="bg-white rounded-lg shadow-sm p-6">
              <h2 className="text-xl font-semibold text-slate-900 mb-4">Send us a Message</h2>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label htmlFor="name" className="block text-sm font-medium text-slate-700 mb-1">
                    Name
                  </label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent"
                  />
                </div>

                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-slate-700 mb-1">
                    Email
                  </label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent"
                  />
                </div>

                <div>
                  <label htmlFor="subject" className="block text-sm font-medium text-slate-700 mb-1">
                    Subject
                  </label>
                  <input
                    type="text"
                    id="subject"
                    name="subject"
                    value={formData.subject}
                    onChange={handleInputChange}
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent"
                  />
                </div>

                <div>
                  <label htmlFor="message" className="block text-sm font-medium text-slate-700 mb-1">
                    Message
                  </label>
                  <textarea
                    id="message"
                    name="message"
                    value={formData.message}
                    onChange={handleInputChange}
                    required
                    rows={4}
                    className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-transparent"
                  />
                </div>

                <button
                  type="submit"
                  className="w-full bg-brand-primary text-white py-2 px-4 rounded-md hover:bg-brand-secondary transition-colors duration-200 flex items-center justify-center gap-2"
                >
                  <Send className="h-4 w-4" />
                  Send Message
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ContactPage;
