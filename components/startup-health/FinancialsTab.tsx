import React, { useState } from 'react';
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, PieChart, Pie, Cell } from 'recharts';
import { Startup, UserRole, Expense, Revenue, Subsidiary, InternationalOp } from '../../types';
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

// Dynamic data generation based on startup
const generateMonthlyData = (startup: Startup) => {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  return months.map((month, index) => ({
    name: month,
    revenue: Math.floor(startup.totalRevenue * (0.7 + Math.random() * 0.6)),
    expenses: Math.floor(startup.totalRevenue * (0.5 + Math.random() * 0.8))
  }));
};

const generateVerticalData = (startup: Startup) => {
  const totalRevenue = startup.totalRevenue || 100000;
  return [
    { name: 'SaaS', value: Math.floor(totalRevenue * 0.4) },
    { name: 'Consulting', value: Math.floor(totalRevenue * 0.3) },
    { name: 'API', value: Math.floor(totalRevenue * 0.3) }
  ];
};

const generateExpenseVerticalData = (startup: Startup) => {
  const totalFunding = startup.totalFunding || 1000000;
  return [
    { name: 'Salary', value: Math.floor(totalFunding * 0.5) },
    { name: 'Marketing', value: Math.floor(totalFunding * 0.25) },
    { name: 'Infra', value: Math.floor(totalFunding * 0.25) }
  ];
};

// Dynamic mock data based on startup
const generateMockExpenses = (startup: Startup): Expense[] => [
  {
    id: 'e1',
    date: '2024-06-15',
    entity: 'Parent',
    description: 'AWS Services',
    vertical: 'Infrastructure',
    amount: Math.floor(startup.totalFunding * 0.0025),
    fundingSource: 'Series A'
  },
  {
    id: 'e2',
    date: '2024-06-10',
    entity: 'Parent',
    description: 'Salaries - Engineering',
    vertical: 'Salary',
    amount: Math.floor(startup.totalFunding * 0.05),
    fundingSource: 'Series A'
  }
];

const generateMockRevenues = (startup: Startup): Revenue[] => [
  {
    id: 'r1',
    date: '2024-06-20',
    entity: 'Parent',
    vertical: 'SaaS',
    earnings: Math.floor(startup.totalRevenue * 0.15),
    cogs: Math.floor(startup.totalRevenue * 0.08)
  },
  {
    id: 'r2',
    date: '2024-06-18',
    entity: 'Parent',
    vertical: 'Consulting',
    earnings: Math.floor(startup.totalRevenue * 0.08),
    cogs: Math.floor(startup.totalRevenue * 0.05)
  }
];

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6'];

const ChartFilters = () => (
    <div className="flex flex-wrap gap-2 mb-4">
        <Select label="Entity" id="filter-entity" containerClassName="flex-1 min-w-[120px]">
            <option>All Entities</option>
            <option>Parent Company</option>
            <option>Subsidiary 1 (UK)</option>
        </Select>
        <Select label="Vertical" id="filter-vertical" containerClassName="flex-1 min-w-[120px]">
            <option>All Verticals</option>
            <option>SaaS</option>
            <option>Consulting</option>
            <option>Salary</option>
        </Select>
        <Select label="Year" id="filter-year" containerClassName="flex-1 min-w-[100px]">
            <option>2024</option>
            <option>2023</option>
            <option>2022</option>
        </Select>
    </div>
);

const FinancialsTab: React.FC<FinancialsTabProps> = ({ startup, userRole }) => {
  const [filters, setFilters] = useState({ entity: 'all', vertical: 'all', year: '2024' });
  const canEdit = userRole === 'Startup';

  // Generate dynamic data based on startup
  const monthlyData = generateMonthlyData(startup);
  const verticalData = generateVerticalData(startup);
  const expenseVerticalData = generateExpenseVerticalData(startup);
  const mockExpenses = generateMockExpenses(startup);
  const mockRevenues = generateMockRevenues(startup);

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card><p className="text-sm font-medium text-slate-500">Total Funding Received</p><p className="text-2xl font-bold">{formatCurrency(startup.totalFunding)}</p></Card>
        <Card><p className="text-sm font-medium text-slate-500">Total Revenue Till Date</p><p className="text-2xl font-bold">{formatCurrency(startup.totalRevenue)}</p></Card>
        <Card><p className="text-sm font-medium text-slate-500">Total Expenditure Till Date</p><p className="text-2xl font-bold">{formatCurrency(startup.totalFunding - 150000)}</p></Card>
        <Card>
            <p className="text-sm font-medium text-slate-500">Total Available Fund</p>
            <p className="text-2xl font-bold">{formatCurrency(150000)}</p>
            <p className="text-xs text-slate-400">Total Funding - Total Expenditure</p>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
            <h3 className="text-lg font-semibold mb-2 text-slate-700">Monthly Revenue</h3>
            <ChartFilters />
             <div style={{ width: '100%', height: 250 }}>
                <ResponsiveContainer><LineChart data={monthlyData}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="name" fontSize={12}/><YAxis fontSize={12} tickFormatter={(val) => formatCurrency(val)}/><Tooltip formatter={(val: number) => formatCurrency(val)} /><Legend wrapperStyle={{fontSize: "14px"}}/><Line type="monotone" dataKey="revenue" stroke="#16a34a" /></LineChart></ResponsiveContainer>
            </div>
        </Card>
        <Card>
            <h3 className="text-lg font-semibold mb-2 text-slate-700">Monthly Expenses</h3>
             <ChartFilters />
            <div style={{ width: '100%', height: 250 }}>
                <ResponsiveContainer><LineChart data={monthlyData}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="name" fontSize={12}/><YAxis fontSize={12} tickFormatter={(val) => formatCurrency(val)}/><Tooltip formatter={(val: number) => formatCurrency(val)} /><Legend wrapperStyle={{fontSize: "14px"}}/><Line type="monotone" dataKey="expenses" stroke="#dc2626" /></LineChart></ResponsiveContainer>
            </div>
        </Card>
         <Card>
            <h3 className="text-lg font-semibold mb-2 text-slate-700">Revenue by Vertical</h3>
             <ChartFilters />
             <div style={{ width: '100%', height: 250 }}>
            <ResponsiveContainer><PieChart><Pie data={verticalData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>{verticalData.map((e,i) => <Cell key={`cell-${i}`} fill={COLORS[i % COLORS.length]} />)}</Pie><Tooltip formatter={(val: number) => formatCurrency(val)} /><Legend /></PieChart></ResponsiveContainer>
            </div>
        </Card>
        <Card>
            <h3 className="text-lg font-semibold mb-2 text-slate-700">Expenses by Vertical</h3>
             <ChartFilters />
            <div style={{ width: '100%', height: 250 }}>
             <ResponsiveContainer><PieChart><Pie data={expenseVerticalData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>{expenseVerticalData.map((e,i) => <Cell key={`cell-${i}`} fill={COLORS[i % COLORS.length]} />)}</Pie><Tooltip formatter={(val: number) => formatCurrency(val)} /><Legend /></PieChart></ResponsiveContainer>
            </div>
        </Card>
      </div>
      
      {/* Forms and Tables */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">Add New Expense</h3>
            <fieldset disabled={!canEdit}>
                <form className="space-y-4">
                    <Input label="Date" id="exp-date" type="date" />
                    <Select label="Entity" id="exp-entity"><option>Parent Company</option></Select>
                    <Input label="Description" id="exp-desc" />
                    <Input label="Vertical" id="exp-vertical" />
                    <Input label="Amount" id="exp-amount" type="number" />
                    <Input label="Funding Source" id="exp-source" />
                    <Input label="Attach Invoice" id="exp-attach" type="file" />
                    <Button>Add Expense</Button>
                </form>
            </fieldset>
          </Card>
          <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">Expenditure List</h3>
             <div className="overflow-x-auto">
                <table className="w-full text-sm">
                    <thead><tr className="border-b"><th className="py-2 text-left font-semibold">Description</th><th className="py-2 text-left font-semibold">Amount</th><th className="py-2 text-left font-semibold">Actions</th></tr></thead>
                    <tbody>{mockExpenses.map(e => <tr key={e.id} className="border-b"><td className="py-2">{e.description}</td><td className="py-2">{formatCurrency(e.amount)}</td><td><Button size="sm" variant="outline" disabled={!canEdit}><Edit className="h-4 w-4"/></Button></td></tr>)}</tbody>
                </table>
            </div>
          </Card>
          <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">Add New Revenue</h3>
            <fieldset disabled={!canEdit}>
                <form className="space-y-4">
                    <Input label="Date" id="rev-date" type="date" />
                    <Select label="Entity" id="rev-entity"><option>Parent Company</option></Select>
                    <Input label="Vertical" id="rev-vertical" />
                    <Input label="Earnings" id="rev-earnings" type="number" />
                    <Input label="COGS" id="rev-cogs" type="number" />
                    <Input label="Attach Document" id="rev-doc" type="file" />
                    <Button>Add Revenue</Button>
                </form>
            </fieldset>
          </Card>
           <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">Revenue & Profitability</h3>
             <div className="overflow-x-auto">
                <table className="w-full text-sm">
                    <thead><tr className="border-b"><th className="py-2 text-left font-semibold">Vertical</th><th className="py-2 text-left font-semibold">Earnings</th><th className="py-2 text-left font-semibold">Actions</th></tr></thead>
                    <tbody>{mockRevenues.map(r => <tr key={r.id} className="border-b"><td className="py-2">{r.vertical}</td><td className="py-2">{formatCurrency(r.earnings)}</td><td><Button size="sm" variant="outline" disabled={!canEdit}><Edit className="h-4 w-4"/></Button></td></tr>)}</tbody>
                </table>
            </div>
          </Card>
      </div>

    </div>
  );
};

export default FinancialsTab;