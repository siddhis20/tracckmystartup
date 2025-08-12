import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import { User } from '../../types';

interface UserRoleDistributionChartProps {
  users: User[];
}

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6', '#60a5fa', '#93c5fd', '#dbeafe'];

const UserRoleDistributionChart: React.FC<UserRoleDistributionChartProps> = ({ users }) => {
    
    const processData = () => {
        const rolesCount: { [key: string]: number } = {};
        users.forEach(user => {
            rolesCount[user.role] = (rolesCount[user.role] || 0) + 1;
        });
        return Object.keys(rolesCount).map(role => ({
            name: role,
            value: rolesCount[role],
        })).sort((a,b) => b.value - a.value); // Sort for consistent color assignment
    };
    
    const chartData = processData();

    return (
        <div>
            <h4 className="text-md font-semibold mb-4 text-slate-600">User Distribution by Role</h4>
            <div style={{ width: '100%', height: 300 }}>
                <ResponsiveContainer>
                    <PieChart>
                        <Pie
                            data={chartData}
                            cx="50%"
                            cy="50%"
                            labelLine={false}
                            outerRadius={100}
                            fill="#8884d8"
                            dataKey="value"
                            nameKey="name"
                            label={({ name, percent }) => `${(percent * 100).toFixed(0)}%`}
                        >
                            {chartData.map((entry, index) => (
                                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                            ))}
                        </Pie>
                        <Tooltip formatter={(value, name) => [`${value} users`, name]} />
                        <Legend wrapperStyle={{fontSize: "14px"}} />
                    </PieChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
};

export default UserRoleDistributionChart;