import React, { useState, useEffect } from 'react';
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, PieChart, Pie, Cell } from 'recharts';
import { Startup, UserRole, Expense, Revenue } from '../../types';
import { financialsService, MonthlyFinancialData, VerticalData, FinancialSummary, FinancialFilters } from '../../lib/financialsService';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import { Edit, Plus, Upload, Download } from 'lucide-react';

interface FinancialsTabProps {
  startup: Startup;
  userRole?: UserRole;
}

const formatCurrency = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact' }).format(value);

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6', '#16a34a', '#dc2626', '#ea580c', '#7c3aed', '#059669', '#d97706', '#be123c'];

const FinancialsTab: React.FC<FinancialsTabProps> = ({ startup, userRole }) => {
  const [filters, setFilters] = useState<FinancialFilters>({ 
    entity: 'all', 
    vertical: 'all', 
    year: new Date().getFullYear() 
  });
  
  const [monthlyData, setMonthlyData] = useState<MonthlyFinancialData[]>([]);
  const [revenueByVertical, setRevenueByVertical] = useState<VerticalData[]>([]);
  const [expensesByVertical, setExpensesByVertical] = useState<VerticalData[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [revenues, setRevenues] = useState<Revenue[]>([]);
  const [summary, setSummary] = useState<FinancialSummary | null>(null);
  const [entities, setEntities] = useState<string[]>([]);
  const [verticals, setVerticals] = useState<string[]>([]);
  const [availableYears, setAvailableYears] = useState<number[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form states
  const [expenseForm, setExpenseForm] = useState({
    date: '',
    entity: 'Parent Company',
    description: '',
    vertical: '',
    amount: '',
    fundingSource: '',
    attachment: null as File | null
  });

  const [revenueForm, setRevenueForm] = useState({
    date: '',
    entity: 'Parent Company',
    vertical: '',
    earnings: '',
    cogs: '',
    attachment: null as File | null
  });

  const canEdit = userRole === 'Startup' || userRole === 'Admin';

  // Load all data
  useEffect(() => {
    loadFinancialData();
  }, [startup.id, filters]);

  const loadFinancialData = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const year = filters.year || new Date().getFullYear();

      const [
        monthly,
        revenueVertical,
        expenseVertical,
        expensesData,
        revenuesData,
        summaryData,
        entitiesData,
        verticalsData,
        yearsData
      ] = await Promise.all([
        financialsService.getMonthlyFinancialData(startup.id, year),
        financialsService.getRevenueByVertical(startup.id, year),
        financialsService.getExpensesByVertical(startup.id, year),
        financialsService.getExpenses(startup.id, filters),
        financialsService.getRevenues(startup.id, filters),
        financialsService.getFinancialSummary(startup.id),
        financialsService.getEntities(startup.id),
        financialsService.getVerticals(startup.id),
        financialsService.getAvailableYears(startup.id)
      ]);

      setMonthlyData(monthly);
      setRevenueByVertical(revenueVertical);
      setExpensesByVertical(expenseVertical);
      setExpenses(expensesData);
      setRevenues(revenuesData);
      setSummary(summaryData);
      setEntities(entitiesData);
      setVerticals(verticalsData);
      setAvailableYears(yearsData);
    } catch (error) {
      console.error('Error loading financial data:', error);
      setError('Failed to load financial data. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleAddExpense = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!canEdit) return;

    try {
      setIsSubmitting(true);
      setError(null);
      let attachmentUrl = '';

      if (expenseForm.attachment) {
        attachmentUrl = await financialsService.uploadAttachment(expenseForm.attachment, startup.id);
      }

      await financialsService.addFinancialRecord({
        startup_id: startup.id,
        record_type: 'expense',
        date: expenseForm.date,
        entity: expenseForm.entity,
        description: expenseForm.description,
        vertical: expenseForm.vertical,
        amount: parseFloat(expenseForm.amount),
        funding_source: expenseForm.fundingSource,
        attachment_url: attachmentUrl
      });

      // Reset form
      setExpenseForm({
        date: '',
        entity: 'Parent Company',
        description: '',
        vertical: '',
        amount: '',
        fundingSource: '',
        attachment: null
      });

      // Reload data
      await loadFinancialData();
    } catch (error) {
      console.error('Error adding expense:', error);
      setError('Failed to add expense. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleAddRevenue = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!canEdit) return;

    try {
      setIsSubmitting(true);
      setError(null);
      let attachmentUrl = '';

      if (revenueForm.attachment) {
        attachmentUrl = await financialsService.uploadAttachment(revenueForm.attachment, startup.id);
      }

      await financialsService.addFinancialRecord({
        startup_id: startup.id,
        record_type: 'revenue',
        date: revenueForm.date,
        entity: revenueForm.entity,
        description: '',
        vertical: revenueForm.vertical,
        amount: parseFloat(revenueForm.earnings),
        cogs: parseFloat(revenueForm.cogs) || 0,
        attachment_url: attachmentUrl
      });

      // Reset form
      setRevenueForm({
        date: '',
        entity: 'Parent Company',
        vertical: '',
        earnings: '',
        cogs: '',
        attachment: null
      });

      // Reload data
      await loadFinancialData();
    } catch (error) {
      console.error('Error adding revenue:', error);
      setError('Failed to add revenue. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteRecord = async (id: string, recordType: 'expense' | 'revenue') => {
    if (!canEdit) return;
    
    if (confirm(`Are you sure you want to delete this ${recordType}?`)) {
      try {
        setError(null);
        await financialsService.deleteFinancialRecord(id);
        await loadFinancialData();
      } catch (error) {
        console.error(`Error deleting ${recordType}:`, error);
        setError(`Failed to delete ${recordType}. Please try again.`);
      }
    }
  };

  const handleDownloadAttachment = async (attachmentUrl: string) => {
    try {
      const downloadUrl = await financialsService.getAttachmentDownloadUrl(attachmentUrl);
      window.open(downloadUrl, '_blank');
    } catch (error) {
      console.error('Error downloading attachment:', error);
      setError('Failed to download attachment. Please try again.');
    }
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="text-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-2 text-slate-600">Loading financial data...</p>
        </div>
    </div>
);
  }

  return (
    <div className="space-y-6">
      {/* Error Display */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-800">{error}</p>
          <Button 
            size="sm" 
            variant="outline" 
            onClick={() => setError(null)}
            className="mt-2"
          >
            Dismiss
          </Button>
        </div>
      )}

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <p className="text-sm font-medium text-slate-500">Total Funding Received</p>
          <p className="text-2xl font-bold">{formatCurrency(startup.totalFunding)}</p>
        </Card>
        <Card>
          <p className="text-sm font-medium text-slate-500">Total Revenue Till Date</p>
          <p className="text-2xl font-bold">{formatCurrency(summary?.total_revenue || 0)}</p>
        </Card>
        <Card>
          <p className="text-sm font-medium text-slate-500">Total Expenditure Till Date</p>
          <p className="text-2xl font-bold">{formatCurrency(summary?.total_expenses || 0)}</p>
        </Card>
        <Card>
            <p className="text-sm font-medium text-slate-500">Total Available Fund</p>
          <p className="text-2xl font-bold">{formatCurrency(summary?.available_funds || 0)}</p>
            <p className="text-xs text-slate-400">Total Funding - Total Expenditure</p>
        </Card>
      </div>

      {/* Chart Filters */}
      <Card>
        <div className="flex flex-wrap gap-4 mb-4">
          <Select 
            label="Entity" 
            id="filter-entity" 
            value={filters.entity || 'all'}
            onChange={e => setFilters({ ...filters, entity: e.target.value })}
            containerClassName="flex-1 min-w-[120px]"
          >
            <option value="all">All Entities</option>
            {entities.map(entity => (
              <option key={entity} value={entity}>{entity}</option>
            ))}
          </Select>
          <Select 
            label="Vertical" 
            id="filter-vertical" 
            value={filters.vertical || 'all'}
            onChange={e => setFilters({ ...filters, vertical: e.target.value })}
            containerClassName="flex-1 min-w-[120px]"
          >
            <option value="all">All Verticals</option>
            {verticals.map(vertical => (
              <option key={vertical} value={vertical}>{vertical}</option>
            ))}
          </Select>
          <Select 
            label="Year" 
            id="filter-year" 
            value={filters.year || new Date().getFullYear()}
            onChange={e => setFilters({ ...filters, year: parseInt(e.target.value) })}
            containerClassName="flex-1 min-w-[100px]"
          >
            {availableYears.map(year => (
              <option key={year} value={year}>{year}</option>
            ))}
          </Select>
        </div>
      </Card>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
            <h3 className="text-lg font-semibold mb-2 text-slate-700">Monthly Revenue</h3>
             <div style={{ width: '100%', height: 250 }}>
            <ResponsiveContainer>
              <LineChart data={monthlyData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month_name" fontSize={12}/>
                <YAxis fontSize={12} tickFormatter={(val) => formatCurrency(val)}/>
                <Tooltip formatter={(val: number) => formatCurrency(val)} />
                <Legend wrapperStyle={{fontSize: "14px"}}/>
                <Line type="monotone" dataKey="revenue" stroke="#16a34a" />
              </LineChart>
            </ResponsiveContainer>
            </div>
        </Card>
        <Card>
            <h3 className="text-lg font-semibold mb-2 text-slate-700">Monthly Expenses</h3>
            <div style={{ width: '100%', height: 250 }}>
            <ResponsiveContainer>
              <LineChart data={monthlyData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month_name" fontSize={12}/>
                <YAxis fontSize={12} tickFormatter={(val) => formatCurrency(val)}/>
                <Tooltip formatter={(val: number) => formatCurrency(val)} />
                <Legend wrapperStyle={{fontSize: "14px"}}/>
                <Line type="monotone" dataKey="expenses" stroke="#dc2626" />
              </LineChart>
            </ResponsiveContainer>
            </div>
        </Card>
         <Card>
            <h3 className="text-lg font-semibold mb-2 text-slate-700">Revenue by Vertical</h3>
             <div style={{ width: '100%', height: 250 }}>
            <ResponsiveContainer>
              <PieChart>
                <Pie data={revenueByVertical} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>
                  {revenueByVertical.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip formatter={(val: number) => formatCurrency(val)} />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
            </div>
        </Card>
        <Card>
            <h3 className="text-lg font-semibold mb-2 text-slate-700">Expenses by Vertical</h3>
            <div style={{ width: '100%', height: 250 }}>
            <ResponsiveContainer>
              <PieChart>
                <Pie data={expensesByVertical} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>
                  {expensesByVertical.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip formatter={(val: number) => formatCurrency(val)} />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
            </div>
        </Card>
      </div>
      
      {/* Forms and Tables */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">Add New Expense</h3>
          <fieldset disabled={!canEdit || isSubmitting}>
            <form onSubmit={handleAddExpense} className="space-y-4">
              <Input 
                label="Date" 
                id="exp-date" 
                type="date" 
                value={expenseForm.date}
                onChange={e => setExpenseForm({ ...expenseForm, date: e.target.value })}
                required
              />
              <Select 
                label="Entity" 
                id="exp-entity"
                value={expenseForm.entity}
                onChange={e => setExpenseForm({ ...expenseForm, entity: e.target.value })}
                required
              >
                {entities.length > 0 ? entities.map(entity => (
                  <option key={entity} value={entity}>{entity}</option>
                )) : (
                  <option value="Parent Company">Parent Company</option>
                )}
              </Select>
              <Input 
                label="Description" 
                id="exp-desc" 
                value={expenseForm.description}
                onChange={e => setExpenseForm({ ...expenseForm, description: e.target.value })}
                required
              />
              <Input 
                label="Vertical" 
                id="exp-vertical" 
                value={expenseForm.vertical}
                onChange={e => setExpenseForm({ ...expenseForm, vertical: e.target.value })}
                required
              />
              <Input 
                label="Amount" 
                id="exp-amount" 
                type="number" 
                step="0.01"
                min="0"
                value={expenseForm.amount}
                onChange={e => setExpenseForm({ ...expenseForm, amount: e.target.value })}
                required
              />
              <Input 
                label="Funding Source" 
                id="exp-source" 
                value={expenseForm.fundingSource}
                onChange={e => setExpenseForm({ ...expenseForm, fundingSource: e.target.value })}
                required
              />
              <Input 
                label="Attach Invoice" 
                id="exp-attach" 
                type="file" 
                accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
                onChange={e => setExpenseForm({ ...expenseForm, attachment: e.target.files?.[0] || null })}
              />
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? 'Adding...' : 'Add Expense'}
              </Button>
                </form>
            </fieldset>
          </Card>
          <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">Expenditure List</h3>
             <div className="overflow-x-auto">
            {expenses.length === 0 ? (
              <p className="text-slate-500 text-center py-4">No expenses found for the selected filters.</p>
            ) : (
                <table className="w-full text-sm">
                <thead>
                  <tr className="border-b">
                    <th className="py-2 text-left font-semibold">Description</th>
                    <th className="py-2 text-left font-semibold">Amount</th>
                    <th className="py-2 text-left font-semibold">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {expenses.map(expense => (
                    <tr key={expense.id} className="border-b">
                      <td className="py-2">{expense.description}</td>
                      <td className="py-2">{formatCurrency(expense.amount)}</td>
                      <td className="py-2">
                        <div className="flex gap-2">
                          {expense.attachmentUrl && (
                            <Button size="sm" variant="outline" onClick={() => handleDownloadAttachment(expense.attachmentUrl)}>
                              <Download className="h-4 w-4"/>
                            </Button>
                          )}
                          {canEdit && (
                            <Button 
                              size="sm" 
                              variant="outline" 
                              onClick={() => handleDeleteRecord(expense.id, 'expense')}
                            >
                              <Edit className="h-4 w-4"/>
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
                </table>
            )}
            </div>
          </Card>
          <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">Add New Revenue</h3>
          <fieldset disabled={!canEdit || isSubmitting}>
            <form onSubmit={handleAddRevenue} className="space-y-4">
              <Input 
                label="Date" 
                id="rev-date" 
                type="date" 
                value={revenueForm.date}
                onChange={e => setRevenueForm({ ...revenueForm, date: e.target.value })}
                required
              />
              <Select 
                label="Entity" 
                id="rev-entity"
                value={revenueForm.entity}
                onChange={e => setRevenueForm({ ...revenueForm, entity: e.target.value })}
                required
              >
                {entities.length > 0 ? entities.map(entity => (
                  <option key={entity} value={entity}>{entity}</option>
                )) : (
                  <option value="Parent Company">Parent Company</option>
                )}
              </Select>
              <Input 
                label="Vertical" 
                id="rev-vertical" 
                value={revenueForm.vertical}
                onChange={e => setRevenueForm({ ...revenueForm, vertical: e.target.value })}
                required
              />
              <Input 
                label="Earnings" 
                id="rev-earnings" 
                type="number" 
                step="0.01"
                min="0"
                value={revenueForm.earnings}
                onChange={e => setRevenueForm({ ...revenueForm, earnings: e.target.value })}
                required
              />
              <Input 
                label="COGS" 
                id="rev-cogs" 
                type="number" 
                step="0.01"
                min="0"
                value={revenueForm.cogs}
                onChange={e => setRevenueForm({ ...revenueForm, cogs: e.target.value })}
              />
              <Input 
                label="Attach Document" 
                id="rev-doc" 
                type="file" 
                accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
                onChange={e => setRevenueForm({ ...revenueForm, attachment: e.target.files?.[0] || null })}
              />
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? 'Adding...' : 'Add Revenue'}
              </Button>
                </form>
            </fieldset>
          </Card>
           <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">Revenue & Profitability</h3>
             <div className="overflow-x-auto">
            {revenues.length === 0 ? (
              <p className="text-slate-500 text-center py-4">No revenue found for the selected filters.</p>
            ) : (
                <table className="w-full text-sm">
                <thead>
                  <tr className="border-b">
                    <th className="py-2 text-left font-semibold">Vertical</th>
                    <th className="py-2 text-left font-semibold">Earnings</th>
                    <th className="py-2 text-left font-semibold">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {revenues.map(revenue => (
                    <tr key={revenue.id} className="border-b">
                      <td className="py-2">{revenue.vertical}</td>
                      <td className="py-2">{formatCurrency(revenue.earnings)}</td>
                      <td className="py-2">
                        <div className="flex gap-2">
                          {revenue.attachmentUrl && (
                            <Button size="sm" variant="outline" onClick={() => handleDownloadAttachment(revenue.attachmentUrl)}>
                              <Download className="h-4 w-4"/>
                            </Button>
                          )}
                          {canEdit && (
                            <Button 
                              size="sm" 
                              variant="outline" 
                              onClick={() => handleDeleteRecord(revenue.id, 'revenue')}
                            >
                              <Edit className="h-4 w-4"/>
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
                </table>
            )}
            </div>
          </Card>
      </div>
    </div>
  );
};

export default FinancialsTab;