import React, { useState, useEffect } from 'react';
import { complianceRulesComprehensiveService, ComplianceRuleComprehensive, ComplianceRuleFormData } from '../lib/complianceRulesComprehensiveService';
import UserSubmittedCompliancesManager from './UserSubmittedCompliancesManager';
import Button from './ui/Button';
import Card from './ui/Card';
import { Plus, Trash2, Edit, Search, Filter, Upload } from 'lucide-react';

const ComplianceRulesComprehensiveManager: React.FC = () => {
  const [rules, setRules] = useState<ComplianceRuleComprehensive[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingRule, setEditingRule] = useState<ComplianceRuleComprehensive | null>(null);
  
  // Form data
  const [formData, setFormData] = useState<ComplianceRuleFormData>({
    country_code: '',
    country_name: '',
    ca_type: '',
    cs_type: '',
    company_type: '',
    compliance_name: '',
    compliance_description: '',
    frequency: 'annual',
    verification_required: 'both'
  });

  // Filter states
  const [filters, setFilters] = useState({
    country: '',
    companyType: '',
    verification: ''
  });

  // Available options for dropdowns
  const [countries, setCountries] = useState<{ country_code: string; country_name: string }[]>([]);
  const [companyTypes, setCompanyTypes] = useState<string[]>([]);
  const [selectedCountryCAType, setSelectedCountryCAType] = useState<string>('');
  const [selectedCountryCSType, setSelectedCountryCSType] = useState<string>('');

  // Bulk upload states
  const [showBulkUpload, setShowBulkUpload] = useState(false);
  const [uploadFile, setUploadFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState<{
    isUploading: boolean;
    success: number;
    errors: Array<{ row: number; error: string; data: any }>;
  }>({ isUploading: false, success: 0, errors: [] });

  // Add country with types states
  const [showAddCountry, setShowAddCountry] = useState(false);
  const [newCountry, setNewCountry] = useState({ 
    code: '', 
    name: '', 
    caTypes: [] as string[], 
    csTypes: [] as string[] 
  });
  const [newCAType, setNewCAType] = useState('');
  const [newCSType, setNewCSType] = useState('');

  // Load data
  const loadData = async () => {
    setLoading(true);
    try {
      const [rulesData, countriesData, companyTypesData] = await Promise.all([
        complianceRulesComprehensiveService.getAllRules(),
        complianceRulesComprehensiveService.getCountries(),
        complianceRulesComprehensiveService.getCompanyTypes()
      ]);
      
      setRules(rulesData);
      setCountries(countriesData);
      setCompanyTypes(companyTypesData);
      
      // Load CA and CS types for selected country if any
      if (formData.country_code) {
        await loadCountrySpecificTypes(formData.country_code);
      }
    } catch (error) {
      console.error('Error loading data:', error);
    }
    setLoading(false);
  };

  // Load CA and CS types for a specific country
  const loadCountrySpecificTypes = async (countryCode: string) => {
    try {
      const [caType, csType] = await Promise.all([
        complianceRulesComprehensiveService.getCATypeByCountry(countryCode),
        complianceRulesComprehensiveService.getCSTypeByCountry(countryCode)
      ]);
      
      setSelectedCountryCAType(caType || '');
      setSelectedCountryCSType(csType || '');
    } catch (error) {
      console.error('Error loading country-specific types:', error);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingRule) {
        await complianceRulesComprehensiveService.updateRule(editingRule.id, formData);
      } else {
        await complianceRulesComprehensiveService.addRule(formData);
      }
      
      setShowAddForm(false);
      setEditingRule(null);
      resetForm();
      await loadData();
    } catch (error) {
      console.error('Error saving rule:', error);
      alert('Error saving compliance rule. Please try again.');
    }
  };

  // Handle delete
  const handleDelete = async (id: number) => {
    if (confirm('Are you sure you want to delete this compliance rule?')) {
      try {
        await complianceRulesComprehensiveService.deleteRule(id);
        await loadData();
      } catch (error) {
        console.error('Error deleting rule:', error);
        alert('Error deleting compliance rule. Please try again.');
      }
    }
  };

  // Handle edit
  const handleEdit = (rule: ComplianceRuleComprehensive) => {
    setEditingRule(rule);
    setFormData({
      country_code: rule.country_code,
      country_name: rule.country_name,
      ca_type: rule.ca_type || '',
      cs_type: rule.cs_type || '',
      company_type: rule.company_type,
      compliance_name: rule.compliance_name,
      compliance_description: rule.compliance_description || '',
      frequency: rule.frequency,
      verification_required: rule.verification_required
    });
    setShowAddForm(true);
  };

  // Reset form
  const resetForm = () => {
    setFormData({
      country_code: '',
      country_name: '',
      ca_type: '',
      cs_type: '',
      company_type: '',
      compliance_name: '',
      compliance_description: '',
      frequency: 'annual',
      verification_required: 'both'
    });
  };

  // Filter rules
  const filteredRules = rules.filter(rule => {
    if (filters.country && rule.country_code !== filters.country) return false;
    if (filters.companyType && rule.company_type !== filters.companyType) return false;
    if (filters.verification && rule.verification_required !== filters.verification) return false;
    return true;
  });

  // Get company types for selected country
  const getCompanyTypesForCountry = async (countryCode: string) => {
    if (countryCode) {
      try {
        const types = await complianceRulesComprehensiveService.getCompanyTypesByCountry(countryCode);
        setCompanyTypes(types);
      } catch (error) {
        console.error('Error loading company types:', error);
      }
    }
  };

  // Add new country with CA and CS types
  const handleAddCountry = async () => {
    if (!newCountry.code || !newCountry.name || newCountry.caTypes.length === 0 || newCountry.csTypes.length === 0) {
      alert('Please fill in country code, name, and at least one CA type and one CS type.');
      return;
    }
    
    try {
      await complianceRulesComprehensiveService.addCountryWithTypes({
        country_code: newCountry.code.toUpperCase(),
        country_name: newCountry.name,
        ca_types: newCountry.caTypes,
        cs_types: newCountry.csTypes
      });
      
      setNewCountry({ code: '', name: '', caTypes: [], csTypes: [] });
      setNewCAType('');
      setNewCSType('');
      setShowAddCountry(false);
      await loadData();
      alert('Country added successfully with CA and CS types!');
    } catch (error) {
      console.error('Error adding country:', error);
      alert('Error adding country. Please try again.');
    }
  };

  // Add CA type to new country
  const addCATypeToCountry = () => {
    if (newCAType && !newCountry.caTypes.includes(newCAType)) {
      setNewCountry(prev => ({
        ...prev,
        caTypes: [...prev.caTypes, newCAType]
      }));
      setNewCAType('');
    }
  };

  // Add CS type to new country
  const addCSTypeToCountry = () => {
    if (newCSType && !newCountry.csTypes.includes(newCSType)) {
      setNewCountry(prev => ({
        ...prev,
        csTypes: [...prev.csTypes, newCSType]
      }));
      setNewCSType('');
    }
  };

  // Remove CA type from new country
  const removeCATypeFromCountry = (caType: string) => {
    setNewCountry(prev => ({
      ...prev,
      caTypes: prev.caTypes.filter(type => type !== caType)
    }));
  };

  // Remove CS type from new country
  const removeCSTypeFromCountry = (csType: string) => {
    setNewCountry(prev => ({
      ...prev,
      csTypes: prev.csTypes.filter(type => type !== csType)
    }));
  };

  // Handle bulk upload
  const handleBulkUpload = async () => {
    if (!uploadFile) return;

    setUploadProgress({ isUploading: true, success: 0, errors: [] });

    try {
      // Read Excel file
      const data = await readExcelFile(uploadFile);
      
      // Convert to compliance rules format
      console.log('Raw data from file:', data);
      console.log('First row keys:', data.length > 0 ? Object.keys(data[0]) : 'No data');
      
      const rulesData = data.map((row: any, index: number) => {
        // Flexible column mapping to handle truncated headers
        let mappedRow = {
          country_code: (row['Country Code'] || row['Country Co'] || row['country_code'] || row['country_co'] || '').toString().trim(),
          country_name: (row['Country Name'] || row['country_name'] || '').toString().trim(),
          ca_type: (row['CA Type'] || row['ca_type'] || '').toString().trim(),
          cs_type: (row['CS Type'] || row['cs_type'] || '').toString().trim(),
          company_type: (row['Company Type'] || row['Company'] || row['company_type'] || row['company'] || '').toString().trim(),
          compliance_name: (row['Compliance Name'] || row['Complianc'] || row['compliance_name'] || row['compliance'] || '').toString().trim(),
          compliance_description: (row['Compliance Description'] || row['Complianc'] || row['compliance_description'] || row['description'] || '').toString().trim(),
          frequency: (row['Frequency'] || row['frequency'] || 'annual').toString().trim(),
          verification_required: (row['Verification Required'] || row['Verificatio'] || row['verification_required'] || row['verification'] || 'both').toString().trim()
        };
        
        // Transform values to match database constraints
        // Frequency validation
        const validFrequencies = ['first-year', 'monthly', 'quarterly', 'annual'];
        if (!validFrequencies.includes(mappedRow.frequency)) {
          console.warn(`Row ${index + 1}: Invalid frequency "${mappedRow.frequency}", defaulting to "annual"`);
          mappedRow.frequency = 'annual';
        }
        
        // Comprehensive verification required validation and transformation
        const verificationValue = mappedRow.verification_required.toLowerCase().trim();
        
        // CA equivalent types (Tax/Accounting related)
        if (verificationValue === 'ca' || 
            verificationValue.includes('chartered') || 
            verificationValue.includes('tax advisor') || 
            verificationValue.includes('auditor') ||
            verificationValue.includes('cpa') ||
            verificationValue.includes('certified public accountant') ||
            verificationValue.includes('tax consultant') ||
            verificationValue.includes('financial advisor') ||
            verificationValue.includes('accounting professional')) {
          mappedRow.verification_required = 'CA';
        } 
        // CS equivalent types (Legal/Management related)
        else if (verificationValue === 'cs' ||
                 verificationValue.includes('company secretary') ||
                 verificationValue.includes('corporate secretary') ||
                 verificationValue.includes('management') || 
                 verificationValue.includes('lawyer') ||
                 verificationValue.includes('legal advisor') ||
                 verificationValue.includes('legal counsel') ||
                 verificationValue.includes('corporate lawyer') ||
                 verificationValue.includes('business lawyer') ||
                 verificationValue.includes('corporate governance')) {
          mappedRow.verification_required = 'CS';
        } 
        // Both required
        else if (verificationValue === 'both' ||
                 verificationValue.includes('ca and cs') ||
                 verificationValue.includes('chartered accountant and company secretary') ||
                 verificationValue.includes('tax advisor and legal advisor') ||
                 verificationValue.includes('auditor and lawyer')) {
          mappedRow.verification_required = 'both';
        } 
        // Default to both if unclear
        else {
          console.warn(`Row ${index + 1}: Unrecognized verification_required "${mappedRow.verification_required}", defaulting to "both"`);
          mappedRow.verification_required = 'both';
        }
        
        // Validate required fields
        if (!mappedRow.country_code || !mappedRow.country_name || !mappedRow.compliance_name) {
          console.warn(`Row ${index + 1} missing required fields:`, mappedRow);
        }
        
        console.log(`Row ${index + 1} mapped:`, mappedRow);
        return mappedRow;
      }).filter(row => {
        // Filter out rows with missing required fields
        return row.country_code && row.country_name && row.compliance_name;
      });
      
      console.log('Mapped rules data:', rulesData);

      // Upload to database
      const result = await complianceRulesComprehensiveService.bulkUploadRules(rulesData);
      
      console.log('Result from bulkUploadRules received in handleBulkUpload:', { success: result.success, errors: result.errors });
      
      setUploadProgress({
        isUploading: false,
        success: result.success,
        errors: result.errors
      });

      // Reload data
      await loadData();
      
      // Show results
      if (result.errors.length === 0) {
        alert(`Successfully uploaded ${result.success} compliance rules!`);
        setShowBulkUpload(false);
        setUploadFile(null);
      } else {
        alert(`Uploaded ${result.success} rules successfully. ${result.errors.length} errors occurred. Check the error details.`);
      }
    } catch (error) {
      console.error('Error uploading file:', error);
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setUploadProgress({
        isUploading: false,
        success: 0,
        errors: [{ row: 0, error: errorMessage, data: null }]
      });
      alert(`Error uploading file: ${errorMessage}`);
    }
  };

  // Download sample CSV file
  const downloadSampleFile = () => {
    const sampleData = [
      {
        'Country Code': 'US',
        'Country Name': 'United States',
        'CA Type': 'CPA',
        'CS Type': 'CISA',
        'Company Type': 'C-Corporation',
        'Compliance Name': 'Annual Financial Audit',
        'Compliance Description': 'Annual audit of financial statements by certified public accountant',
        'Frequency': 'annual',
        'Verification Required': 'both'
      },
      {
        'Country Code': 'IN',
        'Country Name': 'India',
        'CA Type': 'CA',
        'CS Type': 'CISA',
        'Company Type': 'Private Limited',
        'Compliance Name': 'Tax Audit',
        'Compliance Description': 'Annual tax audit under Income Tax Act',
        'Frequency': 'annual',
        'Verification Required': 'CA'
      },
      {
        'Country Code': 'UK',
        'Country Name': 'United Kingdom',
        'CA Type': 'ACA',
        'CS Type': 'CISA',
        'Company Type': 'Limited Company',
        'Compliance Name': 'Annual Return',
        'Compliance Description': 'Annual return filing with Companies House',
        'Frequency': 'annual',
        'Verification Required': 'both'
      },
      {
        'Country Code': 'US',
        'Country Name': 'United States',
        'CA Type': 'CPA',
        'CS Type': 'CISA',
        'Company Type': 'LLC',
        'Compliance Name': 'Quarterly Tax Filing',
        'Compliance Description': 'Quarterly estimated tax payments',
        'Frequency': 'quarterly',
        'Verification Required': 'CA'
      },
      {
        'Country Code': 'IN',
        'Country Name': 'India',
        'CA Type': 'CA',
        'CS Type': 'CISA',
        'Company Type': 'Public Limited',
        'Compliance Name': 'Board Meeting Minutes',
        'Compliance Description': 'Monthly board meeting minutes and resolutions',
        'Frequency': 'monthly',
        'Verification Required': 'CS'
      }
    ];

    // Convert to CSV
    const headers = Object.keys(sampleData[0]);
    const csvContent = [
      headers.join(','),
      ...sampleData.map(row => 
        headers.map(header => {
          const value = row[header as keyof typeof row];
          // Escape commas and quotes in CSV
          return typeof value === 'string' && (value.includes(',') || value.includes('"')) 
            ? `"${value.replace(/"/g, '""')}"` 
            : value;
        }).join(',')
      )
    ].join('\n');

    // Create and download file
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', 'compliance_rules_sample.csv');
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Parse CSV content properly
  const parseCSV = (csvText: string): any[] => {
    const lines = csvText.split('\n').filter(line => line.trim());
    if (lines.length < 2) return [];
    
    // Parse headers
    const headers = parseCSVLine(lines[0]);
    
    // Parse data rows
    const data = lines.slice(1).map(line => {
      const values = parseCSVLine(line);
      const row: any = {};
      headers.forEach((header, index) => {
        row[header] = values[index] || '';
      });
      return row;
    });
    
    return data;
  };

  // Parse a single CSV line handling quoted fields
  const parseCSVLine = (line: string): string[] => {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;
    
    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      
      if (char === '"') {
        if (inQuotes && line[i + 1] === '"') {
          // Escaped quote
          current += '"';
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char === ',' && !inQuotes) {
        // End of field
        result.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    // Add the last field
    result.push(current.trim());
    
    return result;
  };

  // Read Excel/CSV file
  const readExcelFile = async (file: File): Promise<any[]> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        try {
          const text = e.target?.result as string;
          
          if (file.name.toLowerCase().endsWith('.csv')) {
            // Parse CSV file
            const data = parseCSV(text);
            console.log('Parsed CSV data:', data);
            resolve(data);
          } else {
            // For Excel files, we'd need a library like xlsx
            // For now, reject with a helpful message
            reject(new Error('Excel files (.xlsx, .xls) are not supported yet. Please use CSV format.'));
          }
        } catch (error) {
          console.error('Error parsing file:', error);
          reject(error);
        }
      };
      reader.onerror = () => reject(new Error('Failed to read file'));
      reader.readAsText(file, 'UTF-8');
    });
  };

  // Handle country change
  const handleCountryChange = async (countryCode: string) => {
    const country = countries.find(c => c.country_code === countryCode);
    
    // Load company types and CA/CS types for the selected country
    if (countryCode) {
      await Promise.all([
        getCompanyTypesForCountry(countryCode),
        loadCountrySpecificTypes(countryCode)
      ]);
      
      // Auto-populate CA and CS types
      setFormData(prev => ({
        ...prev,
        country_code: countryCode,
        country_name: country?.country_name || '',
        ca_type: selectedCountryCAType,
        cs_type: selectedCountryCSType
      }));
    } else {
      setCompanyTypes([]);
      setSelectedCountryCAType('');
      setSelectedCountryCSType('');
      setFormData(prev => ({
        ...prev,
        country_code: '',
        country_name: '',
        ca_type: '',
        cs_type: ''
      }));
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="text-slate-600">Loading compliance rules...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* User Submitted Compliances Table */}
      <UserSubmittedCompliancesManager currentUser={null} />
      
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-xl font-semibold text-slate-800">Compliance Rules Management</h3>
          <p className="text-sm text-slate-600">Manage all compliance rules in one comprehensive system</p>
        </div>
        <div className="flex gap-3">
          <Button
            onClick={() => setShowBulkUpload(true)}
            className="bg-green-600 hover:bg-green-700"
          >
            <Upload className="w-4 h-4 mr-2" />
            Bulk Upload
          </Button>
          <Button
            onClick={() => {
              setShowAddForm(true);
              setEditingRule(null);
              resetForm();
            }}
            className="bg-blue-600 hover:bg-blue-700"
          >
            <Plus className="w-4 h-4 mr-2" />
            Add Compliance Rule
          </Button>
        </div>
      </div>

      {/* Filters */}
      <Card className="p-4">
        <div className="flex items-center gap-4">
          <Filter className="w-5 h-5 text-slate-600" />
          <div className="flex gap-4">
            <select
              value={filters.country}
              onChange={(e) => setFilters(prev => ({ ...prev, country: e.target.value }))}
              className="border border-slate-300 rounded-md px-3 py-2 text-sm"
            >
              <option value="">All Countries</option>
              {countries.map(country => (
                <option key={country.country_code} value={country.country_code}>
                  {country.country_name}
                </option>
              ))}
            </select>
            
            <select
              value={filters.companyType}
              onChange={(e) => setFilters(prev => ({ ...prev, companyType: e.target.value }))}
              className="border border-slate-300 rounded-md px-3 py-2 text-sm"
            >
              <option value="">All Company Types</option>
              {companyTypes.map(type => (
                <option key={type} value={type}>{type}</option>
              ))}
            </select>
            
            <select
              value={filters.verification}
              onChange={(e) => setFilters(prev => ({ ...prev, verification: e.target.value }))}
              className="border border-slate-300 rounded-md px-3 py-2 text-sm"
            >
              <option value="">All Verification Types</option>
              <option value="CA">CA Required</option>
              <option value="CS">CS Required</option>
              <option value="both">Both Required</option>
            </select>
          </div>
        </div>
      </Card>

      {/* Add/Edit Form */}
      {showAddForm && (
        <Card className="p-6">
          <h4 className="text-lg font-semibold text-slate-700 mb-4">
            {editingRule ? 'Edit Compliance Rule' : 'Add New Compliance Rule'}
          </h4>
          
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {/* Country */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Country *</label>
                <div className="flex gap-2">
                  <select
                    value={formData.country_code}
                    onChange={(e) => handleCountryChange(e.target.value)}
                    required
                    className="flex-1 border border-slate-300 rounded-md px-3 py-2"
                  >
                    <option value="">Select Country</option>
                    {countries.map(country => (
                      <option key={country.country_code} value={country.country_code}>
                        {country.country_name}
                      </option>
                    ))}
                  </select>
                  <Button
                    type="button"
                    onClick={() => setShowAddCountry(true)}
                    className="bg-green-600 hover:bg-green-700 px-3 py-2"
                    size="sm"
                  >
                    <Plus className="w-4 h-4" />
                  </Button>
                </div>
              </div>

              {/* Company Type */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Company Type *</label>
                <input
                  type="text"
                  value={formData.company_type}
                  onChange={(e) => setFormData(prev => ({ ...prev, company_type: e.target.value }))}
                  required
                  className="w-full border border-slate-300 rounded-md px-3 py-2"
                  placeholder="e.g., Private Limited Company"
                />
              </div>

              {/* Compliance Name */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Compliance Name *</label>
                <input
                  type="text"
                  value={formData.compliance_name}
                  onChange={(e) => setFormData(prev => ({ ...prev, compliance_name: e.target.value }))}
                  required
                  className="w-full border border-slate-300 rounded-md px-3 py-2"
                  placeholder="e.g., Annual Return Filing"
                />
              </div>

              {/* CA Type - Auto-populated */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">CA Type</label>
                <input
                  type="text"
                  value={formData.ca_type}
                  readOnly
                  className="w-full border border-slate-300 rounded-md px-3 py-2 bg-slate-50 text-slate-600"
                  placeholder="Auto-populated based on country"
                />
              </div>

              {/* CS Type - Auto-populated */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">CS Type</label>
                <input
                  type="text"
                  value={formData.cs_type}
                  readOnly
                  className="w-full border border-slate-300 rounded-md px-3 py-2 bg-slate-50 text-slate-600"
                  placeholder="Auto-populated based on country"
                />
              </div>

              {/* Frequency */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Frequency *</label>
                <select
                  value={formData.frequency}
                  onChange={(e) => setFormData(prev => ({ ...prev, frequency: e.target.value as any }))}
                  required
                  className="w-full border border-slate-300 rounded-md px-3 py-2"
                >
                  <option value="first-year">First Year</option>
                  <option value="monthly">Monthly</option>
                  <option value="quarterly">Quarterly</option>
                  <option value="annual">Annual</option>
                </select>
              </div>

              {/* Verification Required */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Verification Required *</label>
                <select
                  value={formData.verification_required}
                  onChange={(e) => setFormData(prev => ({ ...prev, verification_required: e.target.value as any }))}
                  required
                  className="w-full border border-slate-300 rounded-md px-3 py-2"
                >
                  <option value="CA">CA Required</option>
                  <option value="CS">CS Required</option>
                  <option value="both">Both Required</option>
                </select>
              </div>
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Description</label>
              <textarea
                value={formData.compliance_description}
                onChange={(e) => setFormData(prev => ({ ...prev, compliance_description: e.target.value }))}
                rows={3}
                className="w-full border border-slate-300 rounded-md px-3 py-2"
                placeholder="Detailed description of the compliance requirement..."
              />
            </div>

            {/* Form Actions */}
            <div className="flex gap-3 pt-4">
              <Button type="submit" className="bg-blue-600 hover:bg-blue-700">
                {editingRule ? 'Update Rule' : 'Add Rule'}
              </Button>
              <Button
                type="button"
                onClick={() => {
                  setShowAddForm(false);
                  setEditingRule(null);
                  resetForm();
                }}
                className="bg-slate-500 hover:bg-slate-600"
              >
                Cancel
              </Button>
            </div>
          </form>
        </Card>
      )}

      {/* Rules Table */}
      <Card className="overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200">
          <h4 className="text-lg font-semibold text-slate-700">
            Compliance Rules ({filteredRules.length})
          </h4>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase">Country</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase">Company Type</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase">Compliance</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase">Frequency</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase">Verification</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase">CA Type</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase">CS Type</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-slate-600 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {filteredRules.map((rule) => (
                <tr key={rule.id} className="hover:bg-slate-50">
                  <td className="px-4 py-3 text-sm text-slate-900">{rule.country_name}</td>
                  <td className="px-4 py-3 text-sm text-slate-900">{rule.company_type}</td>
                  <td className="px-4 py-3 text-sm text-slate-900">
                    <div>
                      <div className="font-medium">{rule.compliance_name}</div>
                      {rule.compliance_description && (
                        <div className="text-xs text-slate-500 mt-1">{rule.compliance_description}</div>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-900">
                    <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs">
                      {rule.frequency}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-900">
                    <span className={`px-2 py-1 rounded-full text-xs ${
                      rule.verification_required === 'both' ? 'bg-purple-100 text-purple-800' :
                      rule.verification_required === 'CA' ? 'bg-green-100 text-green-800' :
                      'bg-orange-100 text-orange-800'
                    }`}>
                      {rule.verification_required}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm text-slate-900">{rule.ca_type || '-'}</td>
                  <td className="px-4 py-3 text-sm text-slate-900">{rule.cs_type || '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    <div className="flex gap-2">
                      <Button
                        size="sm"
                        onClick={() => handleEdit(rule)}
                        className="bg-blue-600 hover:bg-blue-700"
                      >
                        <Edit className="w-3 h-3" />
                      </Button>
                      <Button
                        size="sm"
                        onClick={() => handleDelete(rule.id)}
                        className="bg-red-600 hover:bg-red-700"
                      >
                        <Trash2 className="w-3 h-3" />
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {filteredRules.length === 0 && (
          <div className="text-center py-8 text-slate-500">
            No compliance rules found. Add your first rule to get started.
          </div>
        )}
      </Card>

      {/* Add Country Modal */}
      {showAddCountry && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-[600px] max-h-[80vh] overflow-y-auto">
            <h3 className="text-lg font-semibold text-slate-700 mb-4">Add New Country with CA & CS Types</h3>
            <div className="space-y-4">
              {/* Country Details */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Country Code *</label>
                  <input
                    type="text"
                    value={newCountry.code}
                    onChange={(e) => setNewCountry(prev => ({ ...prev, code: e.target.value.toUpperCase() }))}
                    className="w-full border border-slate-300 rounded-md px-3 py-2"
                    placeholder="e.g., IN, US, UK"
                    maxLength={3}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Country Name *</label>
                  <input
                    type="text"
                    value={newCountry.name}
                    onChange={(e) => setNewCountry(prev => ({ ...prev, name: e.target.value }))}
                    className="w-full border border-slate-300 rounded-md px-3 py-2"
                    placeholder="e.g., India, United States"
                  />
                </div>
              </div>

              {/* CA Types */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">CA Types *</label>
                <div className="space-y-2">
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newCAType}
                      onChange={(e) => setNewCAType(e.target.value)}
                      className="flex-1 border border-slate-300 rounded-md px-3 py-2"
                      placeholder="e.g., CA, CPA, Auditor"
                      onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addCATypeToCountry())}
                    />
                    <Button
                      type="button"
                      onClick={addCATypeToCountry}
                      className="bg-green-600 hover:bg-green-700 px-3 py-2"
                      size="sm"
                    >
                      <Plus className="w-4 h-4" />
                    </Button>
                  </div>
                  {newCountry.caTypes.length > 0 && (
                    <div className="flex flex-wrap gap-2">
                      {newCountry.caTypes.map((caType, index) => (
                        <span
                          key={index}
                          className="inline-flex items-center gap-1 bg-blue-100 text-blue-800 px-2 py-1 rounded-md text-sm"
                        >
                          {caType}
                          <button
                            type="button"
                            onClick={() => removeCATypeFromCountry(caType)}
                            className="text-blue-600 hover:text-blue-800"
                          >
                            ×
                          </button>
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* CS Types */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">CS Types *</label>
                <div className="space-y-2">
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newCSType}
                      onChange={(e) => setNewCSType(e.target.value)}
                      className="flex-1 border border-slate-300 rounded-md px-3 py-2"
                      placeholder="e.g., CS, Director, Legal"
                      onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addCSTypeToCountry())}
                    />
                    <Button
                      type="button"
                      onClick={addCSTypeToCountry}
                      className="bg-green-600 hover:bg-green-700 px-3 py-2"
                      size="sm"
                    >
                      <Plus className="w-4 h-4" />
                    </Button>
                  </div>
                  {newCountry.csTypes.length > 0 && (
                    <div className="flex flex-wrap gap-2">
                      {newCountry.csTypes.map((csType, index) => (
                        <span
                          key={index}
                          className="inline-flex items-center gap-1 bg-green-100 text-green-800 px-2 py-1 rounded-md text-sm"
                        >
                          {csType}
                          <button
                            type="button"
                            onClick={() => removeCSTypeFromCountry(csType)}
                            className="text-green-600 hover:text-green-800"
                          >
                            ×
                          </button>
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <Button onClick={handleAddCountry} className="bg-blue-600 hover:bg-blue-700">
                Add Country with Types
              </Button>
              <Button
                onClick={() => {
                  setShowAddCountry(false);
                  setNewCountry({ code: '', name: '', caTypes: [], csTypes: [] });
                  setNewCAType('');
                  setNewCSType('');
                }}
                className="bg-slate-500 hover:bg-slate-600"
              >
                Cancel
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Bulk Upload Modal */}
      {showBulkUpload && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-[600px] max-h-[80vh] overflow-y-auto">
            <h3 className="text-lg font-semibold text-slate-700 mb-4">Bulk Upload Compliance Rules</h3>
            
            <div className="space-y-4">
              {/* File Upload */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Upload Excel/CSV File *</label>
                <input
                  type="file"
                  accept=".xlsx,.xls,.csv"
                  onChange={(e) => setUploadFile(e.target.files?.[0] || null)}
                  className="w-full border border-slate-300 rounded-md px-3 py-2"
                />
                <p className="text-xs text-slate-500 mt-1">
                  Supported formats: .xlsx, .xls, .csv
                </p>
              </div>

              {/* Sample File Download */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Sample File:</label>
                <div className="flex items-center gap-3">
                  <Button
                    onClick={downloadSampleFile}
                    className="bg-blue-600 hover:bg-blue-700"
                    size="sm"
                  >
                    <Upload className="w-4 h-4 mr-2" />
                    Download Sample CSV
                  </Button>
                  <span className="text-xs text-slate-500">
                    Download a sample file with the correct format and example data
                  </span>
                </div>
              </div>

              {/* Expected Format */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Expected Column Headers:</label>
                <div className="bg-slate-50 p-3 rounded-md text-sm">
                  <div className="grid grid-cols-2 gap-2">
                    <div>• Country Code</div>
                    <div>• Country Name</div>
                    <div>• CA Type</div>
                    <div>• CS Type</div>
                    <div>• Company Type</div>
                    <div>• Compliance Name</div>
                    <div>• Compliance Description</div>
                    <div>• Frequency</div>
                    <div>• Verification Required</div>
                  </div>
                </div>
                <div className="mt-2 text-xs text-slate-600">
                  <strong>Valid values:</strong><br/>
                  Frequency: annual, quarterly, monthly, first-year<br/>
                  Verification Required: CA, CS, both
                </div>
              </div>

              {/* Upload Progress */}
              {uploadProgress.isUploading && (
                <div className="text-center py-4">
                  <div className="text-slate-600">Uploading and processing data...</div>
                </div>
              )}

              {/* Upload Results */}
              {!uploadProgress.isUploading && (uploadProgress.success > 0 || uploadProgress.errors.length > 0) && (
                <div className="space-y-3">
                  <div className="bg-green-50 border border-green-200 rounded-md p-3">
                    <div className="text-green-800 font-medium">
                      Successfully uploaded: {uploadProgress.success} rules
                    </div>
                  </div>
                  
                  {uploadProgress.errors.length > 0 && (
                    <div className="bg-red-50 border border-red-200 rounded-md p-3">
                      <div className="text-red-800 font-medium mb-2">
                        Errors ({uploadProgress.errors.length}):
                      </div>
                      <div className="max-h-32 overflow-y-auto text-sm">
                        {uploadProgress.errors.map((error, index) => (
                          <div key={index} className="text-red-700">
                            Row {error.row}: {error.error}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>

            <div className="flex gap-3 mt-6">
              <Button 
                onClick={handleBulkUpload} 
                disabled={!uploadFile || uploadProgress.isUploading}
                className="bg-green-600 hover:bg-green-700 disabled:bg-slate-400"
              >
                {uploadProgress.isUploading ? 'Uploading...' : 'Upload File'}
              </Button>
              <Button
                onClick={() => {
                  setShowBulkUpload(false);
                  setUploadFile(null);
                  setUploadProgress({ isUploading: false, success: 0, errors: [] });
                }}
                className="bg-slate-500 hover:bg-slate-600"
              >
                Cancel
              </Button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default ComplianceRulesComprehensiveManager;
