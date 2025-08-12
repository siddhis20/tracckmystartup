import React, { useState } from 'react';
import { InvestmentType } from '../types';
import { startupService } from '../lib/database';
import Modal from './ui/Modal';
import Button from './ui/Button';
import Input from './ui/Input';
import Select from './ui/Select';

interface AddStartupModalProps {
  isOpen: boolean;
  onClose: () => void;
  onStartupAdded: () => void;
}

const AddStartupModal: React.FC<AddStartupModalProps> = ({
  isOpen,
  onClose,
  onStartupAdded
}) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string>('');
  
  const [formData, setFormData] = useState({
    name: '',
    investment_type: InvestmentType.Seed,
    investment_value: '',
    equity_allocation: '',
    current_valuation: '',
    sector: '',
    total_funding: '',
    total_revenue: '',
    registration_date: '',
    founders: [{ name: '', email: '' }]
  });

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleFounderChange = (index: number, field: 'name' | 'email', value: string) => {
    const newFounders = [...formData.founders];
    newFounders[index] = { ...newFounders[index], [field]: value };
    setFormData(prev => ({ ...prev, founders: newFounders }));
  };

  const addFounder = () => {
    setFormData(prev => ({
      ...prev,
      founders: [...prev.founders, { name: '', email: '' }]
    }));
  };

  const removeFounder = (index: number) => {
    if (formData.founders.length > 1) {
      const newFounders = formData.founders.filter((_, i) => i !== index);
      setFormData(prev => ({ ...prev, founders: newFounders }));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      // Validate required fields
      if (!formData.name || !formData.sector || !formData.registration_date) {
        throw new Error('Please fill in all required fields');
      }

      // Validate numeric fields
      const numericFields = ['investment_value', 'equity_allocation', 'current_valuation', 'total_funding', 'total_revenue'];
      for (const field of numericFields) {
        if (isNaN(Number(formData[field as keyof typeof formData]))) {
          throw new Error(`${field.replace('_', ' ')} must be a valid number`);
        }
      }

      // Validate founders
      const validFounders = formData.founders.filter(f => f.name && f.email);
      if (validFounders.length === 0) {
        throw new Error('At least one founder is required');
      }

      const startupData = {
        name: formData.name,
        investment_type: formData.investment_type,
        investment_value: Number(formData.investment_value),
        equity_allocation: Number(formData.equity_allocation),
        current_valuation: Number(formData.current_valuation),
        sector: formData.sector,
        total_funding: Number(formData.total_funding),
        total_revenue: Number(formData.total_revenue),
        registration_date: formData.registration_date,
        founders: validFounders
      };

      await startupService.createStartup(startupData);
      
      // Reset form
      setFormData({
        name: '',
        investment_type: InvestmentType.Seed,
        investment_value: '',
        equity_allocation: '',
        current_valuation: '',
        sector: '',
        total_funding: '',
        total_revenue: '',
        registration_date: '',
        founders: [{ name: '', email: '' }]
      });

      onStartupAdded();
      onClose();
    } catch (error) {
      console.error('Error creating startup:', error);
      setError(error instanceof Error ? error.message : 'Failed to create startup');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Add New Startup">
      <form onSubmit={handleSubmit} className="space-y-6">
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md">
            {error}
          </div>
        )}

        {/* Basic Information */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Startup Name *
            </label>
            <Input
              type="text"
              value={formData.name}
              onChange={(e) => handleInputChange('name', e.target.value)}
              placeholder="Enter startup name"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Sector *
            </label>
            <Input
              type="text"
              value={formData.sector}
              onChange={(e) => handleInputChange('sector', e.target.value)}
              placeholder="e.g., FinTech, HealthTech"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Investment Type
            </label>
            <Select
              value={formData.investment_type}
              onChange={(e) => handleInputChange('investment_type', e.target.value)}
            >
              {Object.values(InvestmentType).map(type => (
                <option key={type} value={type}>{type}</option>
              ))}
            </Select>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Registration Date *
            </label>
            <Input
              type="date"
              value={formData.registration_date}
              onChange={(e) => handleInputChange('registration_date', e.target.value)}
              required
            />
          </div>
        </div>

        {/* Financial Information */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Investment Value (Lakhs)
            </label>
            <Input
              type="number"
              value={formData.investment_value}
              onChange={(e) => handleInputChange('investment_value', e.target.value)}
              placeholder="0"
              min="0"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Equity Allocation (%)
            </label>
            <Input
              type="number"
              value={formData.equity_allocation}
              onChange={(e) => handleInputChange('equity_allocation', e.target.value)}
              placeholder="0"
              min="0"
              max="100"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Current Valuation (Lakhs)
            </label>
            <Input
              type="number"
              value={formData.current_valuation}
              onChange={(e) => handleInputChange('current_valuation', e.target.value)}
              placeholder="0"
              min="0"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Total Funding (Lakhs)
            </label>
            <Input
              type="number"
              value={formData.total_funding}
              onChange={(e) => handleInputChange('total_funding', e.target.value)}
              placeholder="0"
              min="0"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Total Revenue (Lakhs)
            </label>
            <Input
              type="number"
              value={formData.total_revenue}
              onChange={(e) => handleInputChange('total_revenue', e.target.value)}
              placeholder="0"
              min="0"
            />
          </div>
        </div>

        {/* Founders */}
        <div>
          <div className="flex justify-between items-center mb-4">
            <label className="block text-sm font-medium text-slate-700">
              Founders *
            </label>
            <Button
              type="button"
              onClick={addFounder}
              className="text-sm bg-blue-600 hover:bg-blue-700"
            >
              Add Founder
            </Button>
          </div>

          <div className="space-y-3">
            {formData.founders.map((founder, index) => (
              <div key={index} className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 border border-slate-200 rounded-md">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    Founder Name
                  </label>
                  <Input
                    type="text"
                    value={founder.name}
                    onChange={(e) => handleFounderChange(index, 'name', e.target.value)}
                    placeholder="Enter founder name"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    Founder Email
                  </label>
                  <Input
                    type="email"
                    value={founder.email}
                    onChange={(e) => handleFounderChange(index, 'email', e.target.value)}
                    placeholder="Enter founder email"
                  />
                </div>
                {formData.founders.length > 1 && (
                  <div className="md:col-span-2">
                    <Button
                      type="button"
                      onClick={() => removeFounder(index)}
                      className="text-sm bg-red-600 hover:bg-red-700"
                    >
                      Remove Founder
                    </Button>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Actions */}
        <div className="flex justify-end gap-3">
          <Button
            type="button"
            onClick={onClose}
            className="bg-slate-300 hover:bg-slate-400 text-slate-700"
            disabled={isLoading}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            className="bg-brand-primary hover:bg-brand-primary-dark"
            disabled={isLoading}
          >
            {isLoading ? 'Creating...' : 'Create Startup'}
          </Button>
        </div>
      </form>
    </Modal>
  );
};

export default AddStartupModal;


