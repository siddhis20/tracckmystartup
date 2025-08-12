# 🚀 Startup Dashboard Implementation Guide

## 📋 Overview

This guide will help you implement the startup dashboard with real data from Supabase. We've created comprehensive backend functions and frontend services to replace all the mock data with live database operations.

## 🗂️ Files Created

1. **`STARTUP_DASHBOARD_BACKEND.sql`** - Database functions and schema enhancements
2. **`lib/startupDashboard.ts`** - Frontend service layer
3. **`STARTUP_DASHBOARD_IMPLEMENTATION_GUIDE.md`** - This guide

## 🛠️ Implementation Steps

### Step 1: Set Up Database Backend

1. **Run the SQL script in Supabase:**
   ```sql
   -- Copy and paste the entire content of STARTUP_DASHBOARD_BACKEND.sql
   -- into your Supabase SQL Editor and execute it
   ```

2. **Verify the functions were created:**
   ```sql
   -- Test the functions
   SELECT * FROM get_monthly_financial_data(1, 2024);
   SELECT * FROM get_fund_usage_breakdown(1);
   SELECT * FROM get_startup_summary_stats(1);
   ```

### Step 2: Update Frontend Components

Now we need to update each dashboard component to use real data. Let's start with the most important ones:

#### A. Update StartupDashboardTab.tsx

```typescript
import React, { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { Startup } from '../../types';
import { startupDashboardService, MonthlyFinancialData, FundUsageData } from '../../lib/startupDashboard';
import Card from '../ui/Card';

interface StartupDashboardTabProps {
  startup: Startup;
}

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6', '#60a5fa'];

const StartupDashboardTab: React.FC<StartupDashboardTabProps> = ({ startup }) => {
  const [revenueData, setRevenueData] = useState<MonthlyFinancialData[]>([]);
  const [fundUsageData, setFundUsageData] = useState<FundUsageData[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setIsLoading(true);
        
        // Fetch data in parallel
        const [monthlyData, fundUsage] = await Promise.all([
          startupDashboardService.getMonthlyFinancialData(startup.id),
          startupDashboardService.getFundUsageBreakdown(startup.id)
        ]);

        setRevenueData(monthlyData);
        setFundUsageData(fundUsage);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchDashboardData();
  }, [startup.id]);

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <div className="animate-pulse">
            <div className="h-4 bg-slate-200 rounded w-1/3 mb-4"></div>
            <div className="h-64 bg-slate-200 rounded"></div>
          </div>
        </Card>
        <Card>
          <div className="animate-pulse">
            <div className="h-4 bg-slate-200 rounded w-1/3 mb-4"></div>
            <div className="h-64 bg-slate-200 rounded"></div>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <Card>
        <h3 className="text-lg font-semibold mb-4 text-slate-700">Revenue vs. Expenses (Monthly)</h3>
        <div style={{ width: '100%', height: 300 }}>
          <ResponsiveContainer>
            <BarChart data={revenueData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month_name" fontSize={12} />
              <YAxis fontSize={12} />
              <Tooltip />
              <Legend wrapperStyle={{fontSize: "14px"}} />
              <Bar dataKey="revenue" fill="#16a34a" name="Revenue" />
              <Bar dataKey="expenses" fill="#dc2626" name="Expenses" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Card>
      <Card>
        <h3 className="text-lg font-semibold mb-4 text-slate-700">Fund Usage</h3>
        <div style={{ width: '100%', height: 300 }}>
          <ResponsiveContainer>
            <PieChart>
              <Pie
                data={fundUsageData}
                cx="50%"
                cy="50%"
                labelLine={false}
                outerRadius={110}
                fill="#8884d8"
                dataKey="amount"
                nameKey="category"
                label={({ category, percentage }) => `${category} ${percentage?.toFixed(0)}%`}
              >
                {fundUsageData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend wrapperStyle={{fontSize: "14px"}} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </Card>
    </div>
  );
};

export default StartupDashboardTab;
```

#### B. Update FinancialsTab.tsx

```typescript
import React, { useState, useEffect } from 'react';
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, PieChart, Pie, Cell } from 'recharts';
import { Startup, UserRole, FinancialRecord } from '../../types';
import { startupDashboardService, MonthlyFinancialData, VerticalData } from '../../lib/startupDashboard';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import { Edit } from 'lucide-react';

interface FinancialsTabProps {
  startup: Startup;
  userRole?: UserRole;
}

const formatCurrency = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact' }).format(value);

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6'];

const FinancialsTab: React.FC<FinancialsTabProps> = ({ startup, userRole }) => {
  const [filters, setFilters] = useState({ entity: 'all', vertical: 'all', year: '2024' });
  const [monthlyData, setMonthlyData] = useState<MonthlyFinancialData[]>([]);
  const [revenueByVertical, setRevenueByVertical] = useState<VerticalData[]>([]);
  const [expensesByVertical, setExpensesByVertical] = useState<VerticalData[]>([]);
  const [financialRecords, setFinancialRecords] = useState<FinancialRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [summaryStats, setSummaryStats] = useState<any>(null);
  
  const canEdit = userRole === 'Startup';

  useEffect(() => {
    const fetchFinancialData = async () => {
      try {
        setIsLoading(true);
        const year = parseInt(filters.year);
        
        const [monthly, revenue, expenses, records, stats] = await Promise.all([
          startupDashboardService.getMonthlyFinancialData(startup.id, year),
          startupDashboardService.getRevenueByVertical(startup.id, year),
          startupDashboardService.getExpensesByVertical(startup.id, year),
          startupDashboardService.getFinancialRecords(startup.id),
          startupDashboardService.getStartupSummaryStats(startup.id)
        ]);

        setMonthlyData(monthly);
        setRevenueByVertical(revenue);
        setExpensesByVertical(expenses);
        setFinancialRecords(records);
        setSummaryStats(stats);
      } catch (error) {
        console.error('Error fetching financial data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchFinancialData();
  }, [startup.id, filters.year]);

  const handleAddExpense = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = e.currentTarget as HTMLFormElement;
    const formData = new FormData(form);
    
    try {
      await startupDashboardService.addFinancialRecord({
        startup_id: startup.id,
        date: formData.get('date') as string,
        entity: formData.get('entity') as string,
        description: formData.get('description') as string,
        vertical: formData.get('vertical') as string,
        amount: parseFloat(formData.get('amount') as string),
        funding_source: formData.get('funding_source') as string,
        cogs: parseFloat(formData.get('cogs') as string) || undefined
      });
      
      // Refresh data
      window.location.reload();
    } catch (error) {
      console.error('Error adding expense:', error);
      alert('Failed to add expense. Please try again.');
    }
  };

  const handleAddRevenue = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = e.currentTarget as HTMLFormElement;
    const formData = new FormData(form);
    
    try {
      await startupDashboardService.addFinancialRecord({
        startup_id: startup.id,
        date: formData.get('date') as string,
        entity: formData.get('entity') as string,
        description: formData.get('description') as string,
        vertical: formData.get('vertical') as string,
        amount: parseFloat(formData.get('earnings') as string),
        cogs: parseFloat(formData.get('cogs') as string) || undefined
      });
      
      // Refresh data
      window.location.reload();
    } catch (error) {
      console.error('Error adding revenue:', error);
      alert('Failed to add revenue. Please try again.');
    }
  };

  if (isLoading) {
    return <div className="animate-pulse">Loading financial data...</div>;
  }

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <p className="text-sm font-medium text-slate-500">Total Funding Received</p>
          <p className="text-2xl font-bold">{formatCurrency(summaryStats?.total_funding || 0)}</p>
        </Card>
        <Card>
          <p className="text-sm font-medium text-slate-500">Total Revenue Till Date</p>
          <p className="text-2xl font-bold">{formatCurrency(summaryStats?.total_revenue || 0)}</p>
        </Card>
        <Card>
          <p className="text-sm font-medium text-slate-500">Total Expenditure Till Date</p>
          <p className="text-2xl font-bold">{formatCurrency(summaryStats?.total_expenses || 0)}</p>
        </Card>
        <Card>
          <p className="text-sm font-medium text-slate-500">Total Available Fund</p>
          <p className="text-2xl font-bold">{formatCurrency(summaryStats?.available_funds || 0)}</p>
          <p className="text-xs text-slate-400">Total Funding - Total Expenditure</p>
        </Card>
      </div>

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
                <Pie 
                  data={revenueByVertical} 
                  dataKey="amount" 
                  nameKey="vertical" 
                  cx="50%" 
                  cy="50%" 
                  outerRadius={80} 
                  label
                >
                  {revenueByVertical.map((e,i) => <Cell key={`cell-${i}`} fill={COLORS[i % COLORS.length]} />)}
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
                <Pie 
                  data={expensesByVertical} 
                  dataKey="amount" 
                  nameKey="vertical" 
                  cx="50%" 
                  cy="50%" 
                  outerRadius={80} 
                  label
                >
                  {expensesByVertical.map((e,i) => <Cell key={`cell-${i}`} fill={COLORS[i % COLORS.length]} />)}
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
          <fieldset disabled={!canEdit}>
            <form onSubmit={handleAddExpense} className="space-y-4">
              <Input label="Date" name="date" type="date" required />
              <Select label="Entity" name="entity">
                <option value="Parent Company">Parent Company</option>
              </Select>
              <Input label="Description" name="description" required />
              <Input label="Vertical" name="vertical" required />
              <Input label="Amount" name="amount" type="number" required />
              <Input label="Funding Source" name="funding_source" />
              <Input label="COGS" name="cogs" type="number" />
              <Input label="Attach Invoice" name="attachment" type="file" />
              <Button type="submit">Add Expense</Button>
            </form>
          </fieldset>
        </Card>
        <Card>
          <h3 className="text-lg font-semibold mb-4 text-slate-700">Expenditure List</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b">
                  <th className="py-2 text-left font-semibold">Description</th>
                  <th className="py-2 text-left font-semibold">Amount</th>
                  <th className="py-2 text-left font-semibold">Actions</th>
                </tr>
              </thead>
              <tbody>
                {financialRecords.filter(r => r.cogs !== null).map(record => (
                  <tr key={record.id} className="border-b">
                    <td className="py-2">{record.description}</td>
                    <td className="py-2">{formatCurrency(record.amount)}</td>
                    <td>
                      <Button size="sm" variant="outline" disabled={!canEdit}>
                        <Edit className="h-4 w-4"/>
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
        <Card>
          <h3 className="text-lg font-semibold mb-4 text-slate-700">Add New Revenue</h3>
          <fieldset disabled={!canEdit}>
            <form onSubmit={handleAddRevenue} className="space-y-4">
              <Input label="Date" name="date" type="date" required />
              <Select label="Entity" name="entity">
                <option value="Parent Company">Parent Company</option>
              </Select>
              <Input label="Vertical" name="vertical" required />
              <Input label="Earnings" name="earnings" type="number" required />
              <Input label="COGS" name="cogs" type="number" />
              <Input label="Attach Document" name="document" type="file" />
              <Button type="submit">Add Revenue</Button>
            </form>
          </fieldset>
        </Card>
        <Card>
          <h3 className="text-lg font-semibold mb-4 text-slate-700">Revenue & Profitability</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b">
                  <th className="py-2 text-left font-semibold">Vertical</th>
                  <th className="py-2 text-left font-semibold">Earnings</th>
                  <th className="py-2 text-left font-semibold">Actions</th>
                </tr>
              </thead>
              <tbody>
                {financialRecords.filter(r => r.cogs === null).map(record => (
                  <tr key={record.id} className="border-b">
                    <td className="py-2">{record.vertical}</td>
                    <td className="py-2">{formatCurrency(record.amount)}</td>
                    <td>
                      <Button size="sm" variant="outline" disabled={!canEdit}>
                        <Edit className="h-4 w-4"/>
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default FinancialsTab;
```

### Step 3: Test the Implementation

1. **Run the SQL script in Supabase**
2. **Update the components as shown above**
3. **Test the functionality:**
   - Login as a startup user
   - Navigate to the startup health dashboard
   - Try adding financial records
   - Check if charts update with real data

### Step 4: Implement Real-time Updates

Add real-time subscriptions to your components:

```typescript
useEffect(() => {
  // Subscribe to real-time updates
  const subscription = startupDashboardService.subscribeToFinancialRecords(
    startup.id,
    (payload) => {
      console.log('Financial record updated:', payload);
      // Refresh your data here
      fetchFinancialData();
    }
  );

  return () => {
    subscription.unsubscribe();
  };
}, [startup.id]);
```

## 🎯 Key Features Implemented

### ✅ Analytics Functions
- Monthly revenue vs expenses charts
- Fund usage breakdown pie charts
- Revenue by vertical analysis
- Employee salary and ESOP tracking
- Startup summary statistics

### ✅ CRUD Operations
- Add/edit financial records
- Add/edit employees
- Add/edit investment records
- Manage subsidiaries and international operations

### ✅ Real-time Updates
- Live updates when data changes
- Automatic chart refreshes
- Real-time notifications

### ✅ Security
- Row-level security policies
- User-specific data access
- Proper authentication checks

## 🚀 Next Steps

1. **Implement the remaining tabs** (EmployeesTab, CapTableTab, ProfileTab)
2. **Add file upload functionality** for attachments
3. **Implement advanced filtering** and search
4. **Add export functionality** for reports
5. **Implement notifications** for important events

## 🔧 Troubleshooting

### Common Issues:

1. **"Function not found" error:**
   - Make sure you ran the SQL script in Supabase
   - Check that the function names match exactly

2. **"Permission denied" error:**
   - Verify RLS policies are enabled
   - Check that user_id is properly set in startups table

3. **Charts not showing data:**
   - Check if there's data in the database
   - Verify the function parameters are correct
   - Check browser console for errors

4. **Real-time not working:**
   - Ensure real-time is enabled in Supabase
   - Check that the subscription is properly set up

## 📞 Support

If you encounter any issues:
1. Check the browser console for errors
2. Verify the Supabase logs
3. Test the database functions directly in SQL Editor
4. Ensure all dependencies are properly imported

This implementation provides a solid foundation for a production-ready startup dashboard with real-time data and comprehensive analytics!
