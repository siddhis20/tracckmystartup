import React, { useState, useEffect } from 'react';
import { Startup, Employee } from '../../types';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line } from 'recharts';
import { Plus, Trash2, Edit3, Save, X, Download } from 'lucide-react';
import { employeesService } from '../../lib/employeesService';

interface EmployeesTabProps {
  startup: Startup;
  userRole?: string;
}

const formatCurrency = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact' }).format(value);

// Dynamic data generation based on startup - now using real data
const generateMonthlyExpenseData = async (startup: Startup) => {
  try {
    console.log('🔍 Loading monthly data for startup:', startup.id);
    const monthlyData = await employeesService.getMonthlySalaryData(startup.id, new Date().getFullYear());
    console.log('✅ Monthly data loaded:', monthlyData);
    
    if (monthlyData.length === 0) {
      console.log('⚠️ No monthly data found, using fallback');
      return [
        { name: 'Jan', salary: 0, esop: 0 },
        { name: 'Feb', salary: 0, esop: 0 },
        { name: 'Mar', salary: 0, esop: 0 }
      ];
    }
    
    return monthlyData.map(item => ({
      name: item.month_name,
      salary: item.total_salary,
      esop: item.total_esop
    }));
  } catch (error) {
    console.error('❌ Error loading monthly data:', error);
    console.log('🔄 Using fallback monthly data');
    // Fallback to mock data if database fails
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    const baseSalary = Math.floor((startup.totalFunding || 1000000) * 0.0001);
    return months.map((month, index) => ({
      name: month,
      salary: baseSalary * (0.8 + Math.random() * 0.4),
      esop: baseSalary * 0.125
    }));
  }
};

const generateDepartmentData = async (startup: Startup) => {
  try {
    console.log('🔍 Loading department data for startup:', startup.id);
    const deptData = await employeesService.getEmployeesByDepartment(startup.id);
    console.log('✅ Department data loaded:', deptData);
    
    if (deptData.length === 0) {
      console.log('⚠️ No department data found, using fallback');
      return [
        { name: 'Engineering', value: 1 },
        { name: 'Sales', value: 1 }
      ];
    }
    
    return deptData.map(item => ({
      name: item.department_name,
      value: item.employee_count
    }));
  } catch (error) {
    console.error('❌ Error loading department data:', error);
    console.log('🔄 Using fallback department data');
    // Fallback to mock data if database fails
    const totalFunding = startup.totalFunding || 1000000;
    const employeeCount = Math.floor(totalFunding / 100000);
    
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
  }
};

// Dynamic mock employees based on startup - now using real data
const generateMockEmployees = async (startup: Startup): Promise<Employee[]> => {
  try {
    const employees = await employeesService.getEmployees(startup.id);
    return employees;
  } catch (error) {
    console.error('Error loading employees:', error);
    // Fallback to mock data if database fails
    const totalFunding = startup.totalFunding || 1000000;
    const employeeCount = Math.min(Math.floor(totalFunding / 100000), 10);
    
    if (employeeCount < 3) {
      return [
        {
          id: 'emp1',
          name: 'John Doe',
          department: 'Engineering',
          salary: Math.floor(totalFunding * 0.00012),
          esopAllocation: Math.floor(totalFunding * 0.00005),
          allocationType: 'one-time',
          esopPerAllocation: Math.floor(totalFunding * 0.000025),
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
          esopAllocation: Math.floor(totalFunding * 0.00005),
          allocationType: 'one-time',
          esopPerAllocation: Math.floor(totalFunding * 0.000025),
          contractUrl: '#'
        },
        {
          id: 'emp2',
          name: 'Jane Smith',
          department: 'Sales',
          salary: Math.floor(totalFunding * 0.00009),
          esopAllocation: Math.floor(totalFunding * 0.000035),
          allocationType: 'one-time',
          esopPerAllocation: Math.floor(totalFunding * 0.000035),
          contractUrl: '#'
        }
      ];
    }
  }
};

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6'];

const EmployeesTab: React.FC<EmployeesTabProps> = ({ startup, userRole }) => {
    const [isEditing, setIsEditing] = useState(false);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [monthlyExpenseData, setMonthlyExpenseData] = useState<any[]>([]);
    const [departmentData, setDepartmentData] = useState<any[]>([]);
    const [mockEmployees, setMockEmployees] = useState<Employee[]>([]);
    const [summary, setSummary] = useState<any>(null);
    
    const canEdit = userRole === 'Startup';

    // Load data on component mount
    useEffect(() => {
        loadData();
    }, [startup.id]);

    const loadData = async () => {
        try {
            setIsLoading(true);
            setError(null);
            
            // Load all data in parallel
            const [monthlyData, deptData, employeesData, summaryData] = await Promise.all([
                generateMonthlyExpenseData(startup),
                generateDepartmentData(startup),
                generateMockEmployees(startup),
                employeesService.getEmployeeSummary(startup.id)
            ]);
            
            setMonthlyExpenseData(monthlyData);
            setDepartmentData(deptData);
            setMockEmployees(employeesData);
            setSummary(summaryData);
            
        } catch (err) {
            console.error('Error loading data:', err);
            setError('Failed to load employee data');
        } finally {
            setIsLoading(false);
        }
    };

    const handleAddEmployee = async (e: React.FormEvent) => {
        e.preventDefault();
        const formData = new FormData(e.target as HTMLFormElement);
        
        try {
            const employeeData = {
                name: formData.get('name') as string,
                joiningDate: formData.get('joiningDate') as string,
                entity: formData.get('entity') as string,
                department: formData.get('department') as string,
                salary: parseFloat(formData.get('salary') as string),
                esopAllocation: parseFloat(formData.get('esopAllocation') as string) || 0,
                allocationType: formData.get('allocationType') as 'one-time' | 'annually' | 'quarterly' | 'monthly',
                esopPerAllocation: parseFloat(formData.get('esopPerAllocation') as string) || 0,
                contractUrl: ''
            };

            await employeesService.addEmployee(startup.id, employeeData);
            
            // Reload data
            await loadData();
            
            // Reset form
            (e.target as HTMLFormElement).reset();
            
        } catch (err) {
            console.error('Error adding employee:', err);
            setError('Failed to add employee');
        }
    };

    const handleDeleteEmployee = async (employeeId: string) => {
        if (!confirm('Are you sure you want to delete this employee?')) return;
        
        try {
            await employeesService.deleteEmployee(employeeId);
            await loadData(); // Reload data
        } catch (err) {
            console.error('Error deleting employee:', err);
            setError('Failed to delete employee');
        }
    };

    const RESERVED_ESOP_PERCENTAGE = 5;
    const reservedEsopValue = startup.currentValuation * (RESERVED_ESOP_PERCENTAGE / 100);
    const allocatedEsopValue = summary?.total_esop_allocated || mockEmployees.reduce((acc, emp) => acc + emp.esopAllocation, 0);

    if (isLoading) {
        return (
            <div className="space-y-6">
                <div className="flex items-center justify-center h-64">
                    <div className="text-center">
                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary mx-auto mb-4"></div>
                        <p className="text-slate-500">Loading employees data...</p>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
                    {error}
                </div>
            )}

            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <Card>
                    <p className="text-sm font-medium text-slate-500">Number of Employees</p>
                    <p className="text-2xl font-bold">{summary?.total_employees || mockEmployees.length}</p>
                </Card>
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
                        <ResponsiveContainer>
                            <LineChart data={monthlyExpenseData}>
                                <CartesianGrid strokeDasharray="3 3" />
                                <XAxis dataKey="name" fontSize={12}/>
                                <YAxis fontSize={12}/>
                                <Tooltip />
                                <Legend />
                                <Line type="monotone" dataKey="salary" stroke="#16a34a" />
                            </LineChart>
                        </ResponsiveContainer>
                    </div>
                </Card>
                <Card>
                    <h3 className="text-lg font-semibold mb-4 text-slate-700">ESOP Expenses</h3>
                    <div style={{ width: '100%', height: 250 }}>
                        <ResponsiveContainer>
                            <LineChart data={monthlyExpenseData}>
                                <CartesianGrid strokeDasharray="3 3" />
                                <XAxis dataKey="name" fontSize={12}/>
                                <YAxis fontSize={12}/>
                                <Tooltip />
                                <Legend />
                                <Line type="monotone" dataKey="esop" stroke="#3b82f6" />
                            </LineChart>
                        </ResponsiveContainer>
                    </div>
                </Card>
                <Card>
                    <h3 className="text-lg font-semibold mb-4 text-slate-700">Salary by Department</h3>
                    <div style={{ width: '100%', height: 250 }}>
                        <ResponsiveContainer>
                            <PieChart>
                                <Pie 
                                    data={departmentData} 
                                    dataKey="value" 
                                    nameKey="name" 
                                    cx="50%" 
                                    cy="50%" 
                                    outerRadius={80} 
                                    label
                                >
                                    {departmentData.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip />
                                <Legend />
                            </PieChart>
                        </ResponsiveContainer>
                    </div>
                </Card>
                <Card>
                    <h3 className="text-lg font-semibold mb-4 text-slate-700">ESOP by Department</h3>
                    <div style={{ width: '100%', height: 250 }}>
                        <ResponsiveContainer>
                            <PieChart>
                                <Pie 
                                    data={departmentData} 
                                    dataKey="value" 
                                    nameKey="name" 
                                    cx="50%" 
                                    cy="50%" 
                                    outerRadius={80} 
                                    label
                                >
                                    {departmentData.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip />
                                <Legend />
                            </PieChart>
                        </ResponsiveContainer>
                    </div>
                </Card>
            </div>
            
            {/* Add Employee Form */}
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Add New Employee</h3>
                <fieldset disabled={!canEdit}>
                    <form onSubmit={handleAddEmployee} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                        <Input label="Employee Name" name="name" required />
                        <Input label="Date of Joining" name="joiningDate" type="date" required />
                        <Select label="Entity" name="entity">
                            <option value="Parent Company">Parent Company</option>
                        </Select>
                        <Input label="Department" name="department" required />
                        <Input label="Salary (Annual)" name="salary" type="number" min="0" required />
                        <Input label="ESOP Allocation (USD)" name="esopAllocation" type="number" min="0" />
                        <Select label="Allocation Type" name="allocationType">
                            <option value="one-time">One-time</option>
                            <option value="annually">Annually</option>
                            <option value="quarterly">Quarterly</option>
                            <option value="monthly">Monthly</option>
                        </Select>
                        <Input label="ESOP per Allocation" name="esopPerAllocation" type="number" min="0" />
                        <Input label="Employee Contract" name="contract" type="file" accept=".pdf,.doc,.docx" />
                        <div className="flex items-end pt-5">
                            <Button type="submit">Add Employee</Button>
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
                                    <td className="px-4 py-2 text-slate-500">{formatCurrency(emp.esopAllocation)}</td>
                                    <td className="px-4 py-2 text-slate-500">
                                        {emp.contractUrl ? (
                                            <a href={emp.contractUrl} className="flex items-center text-brand-primary hover:underline">
                                                <Download className="h-4 w-4 mr-1"/> View
                                            </a>
                                        ) : 'N/A'}
                                    </td>
                                    <td className="px-4 py-2 text-right">
                                        <Button 
                                            size="sm" 
                                            variant="outline" 
                                            disabled={!canEdit}
                                            onClick={() => handleDeleteEmployee(emp.id)}
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
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