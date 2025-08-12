import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { Startup } from '../../types';
import Card from '../ui/Card';

interface StartupDashboardTabProps {
  startup: Startup;
}

// Dynamic data based on startup
const generateRevenueData = (startup: Startup) => {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  return months.map((month, index) => ({
    name: month,
    revenue: Math.floor(startup.totalRevenue * (0.8 + Math.random() * 0.4)), // Dynamic based on startup revenue
    expenses: Math.floor(startup.totalRevenue * (0.6 + Math.random() * 0.8)) // Dynamic based on startup revenue
  }));
};

const generateFundUsageData = (startup: Startup) => {
  const totalFunding = startup.totalFunding || 1000000; // Fallback if no funding
  return [
    { name: 'R&D', value: Math.floor(totalFunding * 0.33) },
    { name: 'Marketing', value: Math.floor(totalFunding * 0.25) },
    { name: 'Operations', value: Math.floor(totalFunding * 0.25) },
    { name: 'Hiring', value: Math.floor(totalFunding * 0.17) },
  ];
};

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6', '#60a5fa'];

const StartupDashboardTab: React.FC<StartupDashboardTabProps> = ({ startup }) => {
  // Generate dynamic data based on startup
  const revenueData = generateRevenueData(startup);
  const fundUsageData = generateFundUsageData(startup);

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <Card>
        <h3 className="text-lg font-semibold mb-4 text-slate-700">Revenue vs. Expenses (Monthly)</h3>
        <div style={{ width: '100%', height: 300 }}>
          <ResponsiveContainer>
            <BarChart data={revenueData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" fontSize={12} />
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
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {fundUsageData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </Card>
    </div>
  );
};

export default StartupDashboardTab;
