import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { User } from '../../types';

interface UserGrowthChartProps {
  users: User[];
}

const UserGrowthChart: React.FC<UserGrowthChartProps> = ({ users }) => {
  const processData = () => {
    const signupsByMonth: { [key: string]: number } = {};
    
    users.forEach(user => {
      try {
        const date = new Date(user.registrationDate);
        if (isNaN(date.getTime())) return; // Skip invalid dates
        
        // Format as "YYYY-MM" to make sorting easy and accurate
        const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        signupsByMonth[monthKey] = (signupsByMonth[monthKey] || 0) + 1;
      } catch (e) {
        console.error("Could not parse date:", user.registrationDate);
      }
    });
    
    // Sort keys chronologically
    const sortedMonthKeys = Object.keys(signupsByMonth).sort();

    return sortedMonthKeys.map(key => {
        const [year, month] = key.split('-');
        const date = new Date(Number(year), Number(month) - 1);
        const monthName = date.toLocaleString('default', { month: 'short', year: 'numeric' });
        return {
            name: monthName,
            'New Users': signupsByMonth[key],
        }
    });
  };

  const chartData = processData();

  return (
    <div>
        <h4 className="text-md font-semibold mb-4 text-slate-600">User Signups Over Time</h4>
        <div style={{ width: '100%', height: 300 }}>
            <ResponsiveContainer>
                <BarChart data={chartData} margin={{ top: 5, right: 20, left: -10, bottom: 5 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
                    <XAxis dataKey="name" stroke="#64748b" fontSize={12} />
                    <YAxis allowDecimals={false} stroke="#64748b" fontSize={12} />
                    <Tooltip 
                        cursor={{fill: 'rgba(239, 246, 255, 0.5)'}}
                        contentStyle={{
                            backgroundColor: '#fff',
                            borderRadius: '0.5rem',
                            borderColor: '#e2e8f0',
                        }}
                    />
                    <Legend wrapperStyle={{fontSize: "14px"}}/>
                    <Bar dataKey="New Users" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                </BarChart>
            </ResponsiveContainer>
        </div>
    </div>
  );
};

export default UserGrowthChart;
