import React, { useState } from 'react';
import { Startup, Employee } from '../../types';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { Plus, Trash2, Edit3, Save, X, Download } from 'lucide-react';

interface EmployeesTabProps {
  startup: Startup;
  userRole?: string;
}

// Dynamic data generation based on startup
const generateMonthlyExpenseData = (startup: Startup) => {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  const baseSalary = Math.floor((startup.totalFunding || 1000000) * 0.0001); // Dynamic based on funding
  return months.map((month, index) => ({
    name: month,
    salary: baseSalary * (0.8 + Math.random() * 0.4),
    esop: baseSalary * 0.125
  }));
};

const generateDepartmentData = (startup: Startup) => {
  const totalFunding = startup.totalFunding || 1000000;
  const employeeCount = Math.floor(totalFunding / 100000); // Rough estimate
  
  if (employeeCount < 5) {
    return [
      { name: 'Engineering', value: 80 },
      { name: 'Sales', value: 20 }
    ];
  } else if (employeeCount < 15) {
    return [
      { name: 'Engineering', value: 60 },
      { name: 'Sales', value: 25 },
      { name: 'Ops', value: 15 }
    ];
  } else {
    return [
      { name: 'Engineering', value: 50 },
      { name: 'Sales', value: 30 },
      { name: 'Ops', value: 20 }
    ];
  }
};

// Dynamic mock employees based on startup
const generateMockEmployees = (startup: Startup): Employee[] => {
  const totalFunding = startup.totalFunding || 1000000;
  const employeeCount = Math.min(Math.floor(totalFunding / 100000), 10); // Cap at 10 for demo
  
  if (employeeCount < 3) {
    return [
      {
        id: 'emp1',
        name: 'John Doe',
        department: 'Engineering',
        salary: Math.floor(totalFunding * 0.00012),
        esopAllocated: Math.floor(totalFunding * 0.00005),
        esopAssigned: Math.floor(totalFunding * 0.000025),
        esopRealized: Math.floor(totalFunding * 0.00001),
        esopBoughtBack: 0,
        contractUrl: '#'
      }
    ];
  } else {
    return [
      {
        id: 'emp1',
        name: 'John Doe',
        department: 'Engineering',
        salary: Math.floor(totalFunding * 0.00012),
        esopAllocated: Math.floor(totalFunding * 0.00005),
        esopAssigned: Math.floor(totalFunding * 0.000025),
        esopRealized: Math.floor(totalFunding * 0.00001),
        esopBoughtBack: 0,
        contractUrl: '#'
      },
      {
        id: 'emp2',
        name: 'Jane Smith',
        department: 'Sales',
        salary: Math.floor(totalFunding * 0.00009),
        esopAllocated: Math.floor(totalFunding * 0.000035),
        esopAssigned: Math.floor(totalFunding * 0.000035),
        esopRealized: Math.floor(totalFunding * 0.0000125),
        esopBoughtBack: 0,
        contractUrl: '#'
      }
    ];
  }
};

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6'];

const EmployeesTab: React.FC<EmployeesTabProps> = ({ startup, userRole }) => {
    const [isEditing, setIsEditing] = useState(false);
    const canEdit = userRole === 'Startup';
    
    // Generate dynamic data based on startup
    const monthlyExpenseData = generateMonthlyExpenseData(startup);
    const departmentData = generateDepartmentData(startup);
    const mockEmployees = generateMockEmployees(startup);

  const RESERVED_ESOP_PERCENTAGE = 5;
  const reservedEsopValue = startup.currentValuation * (RESERVED_ESOP_PERCENTAGE / 100);
  const allocatedEsopValue = mockEmployees.reduce((acc, emp) => acc + emp.esopAllocated, 0);

  return (
    <div className="space-y-6">
        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Card><p className="text-sm font-medium text-slate-500">Number of Employees</p><p className="text-2xl font-bold">42</p></Card>
             <Card>
                <p className="text-sm font-medium text-slate-500">Total Equity Reserved for ESOPs</p>
                <p className="text-2xl font-bold">{formatCurrency(reservedEsopValue)} ({RESERVED_ESOP_PERCENTAGE}%)</p>
            </Card>
            <Card>
                <p className="text-sm font-medium text-slate-500">Total Equity Allocated as ESOPs</p>
                <p className="text-2xl font-bold">{formatCurrency(allocatedEsopValue)} ({reservedEsopValue > 0 ? ((allocatedEsopValue / reservedEsopValue) * 100).toFixed(1) : 0}%)</p>
            </Card>
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Salary Expense</h3>
                <div style={{ width: '100%', height: 250 }}>
                    <ResponsiveContainer><LineChart data={monthlyExpenseData}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="name" fontSize={12}/><YAxis fontSize={12}/><Tooltip /><Legend /><Line type="monotone" dataKey="salary" stroke="#16a34a" /></LineChart></ResponsiveContainer>
                </div>
            </Card>
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">ESOP Expenses</h3>
                <div style={{ width: '100%', height: 250 }}>
                    <ResponsiveContainer><LineChart data={monthlyExpenseData}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="name" fontSize={12}/><YAxis fontSize={12}/><Tooltip /><Legend /><Line type="monotone" dataKey="esop" stroke="#3b82f6" /></LineChart></ResponsiveContainer>
                </div>
            </Card>
             <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Salary by Department</h3>
                 <div style={{ width: '100%', height: 250 }}>
                <ResponsiveContainer><PieChart><Pie data={departmentData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>{departmentData.map((e,i) => <Cell key={`cell-${i}`} fill={COLORS[i % COLORS.length]} />)}</Pie><Tooltip /><Legend /></PieChart></ResponsiveContainer>
                </div>
            </Card>
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">ESOP by Department</h3>
                <div style={{ width: '100%', height: 250 }}>
                 <ResponsiveContainer><PieChart><Pie data={departmentData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>{departmentData.map((e,i) => <Cell key={`cell-${i}`} fill={COLORS[i % COLORS.length]} />)}</Pie><Tooltip /><Legend /></PieChart></ResponsiveContainer>
                </div>
            </Card>
        </div>
        
        {/* Add Employee Form */}
        <Card>
             <h3 className="text-lg font-semibold mb-4 text-slate-700">Add New Employee</h3>
             <fieldset disabled={!canEdit}>
                 <form className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    <Input label="Date of Joining" id="join-date" type="date" />
                    <Select label="Entity" id="emp-entity"><option>Parent Company</option></Select>
                    <Input label="Department" id="emp-dept" />
                    <Input label="Salary (Annual)" id="emp-salary" type="number" />
                    <Input label="ESOP Allocation (USD)" id="emp-esop" type="number" />
                    <Select label="Allocation Type" id="emp-alloc-type">
                        <option value="one-time">One-time</option>
                        <option value="annually">Annually</option>
                        <option value="quarterly">Quarterly</option>
                        <option value="monthly">Monthly</option>
                    </Select>
                    <Input label="ESOP per Allocation" id="emp-esop-per" type="number" />
                    <Input label="Employee Contract" id="emp-contract" type="file" />
                    <div className="flex items-end pt-5">
                        <Button>Add Employee</Button>
                    </div>
                 </form>
             </fieldset>
        </Card>

        {/* Employee List */}
        <Card>
            <h3 className="text-lg font-semibold mb-4 text-slate-700">Employee List</h3>
            <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-slate-200 text-sm">
                    <thead className="bg-slate-50">
                        <tr>
                            <th className="px-4 py-2 text-left font-medium text-slate-500">Name</th>
                            <th className="px-4 py-2 text-left font-medium text-slate-500">Department</th>
                            <th className="px-4 py-2 text-left font-medium text-slate-500">Salary</th>
                            <th className="px-4 py-2 text-left font-medium text-slate-500">ESOP Allocated</th>
                            <th className="px-4 py-2 text-left font-medium text-slate-500">Contract</th>
                            <th className="px-4 py-2 text-right font-medium text-slate-500">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-slate-200">
                        {mockEmployees.map(emp => (
                            <tr key={emp.id}>
                                <td className="px-4 py-2 font-medium text-slate-900">{emp.name}</td>
                                <td className="px-4 py-2 text-slate-500">{emp.department}</td>
                                <td className="px-4 py-2 text-slate-500">{formatCurrency(emp.salary)}</td>
                                <td className="px-4 py-2 text-slate-500">{formatCurrency(emp.esopAllocated)}</td>
                                <td className="px-4 py-2 text-slate-500">
                                    {emp.contractUrl ? <a href={emp.contractUrl} className="flex items-center text-brand-primary hover:underline"><Download className="h-4 w-4 mr-1"/> View</a> : 'N/A'}
                                </td>
                                <td className="px-4 py-2 text-right">
                                    <Button size="sm" variant="outline" disabled={!canEdit}><Edit className="h-4 w-4" /></Button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </Card>
    </div>
  );
};

export default EmployeesTab;