import React, { useState, useEffect } from 'react';
import { Startup } from '../../types';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import { CheckCircle, XCircle, Clock, AlertTriangle, Edit3, Save, X, Upload, MinusCircle, Plus } from 'lucide-react';

interface ComplianceTask {
  id: number;
  entity: string;
  year: string;
  taskDescription: string;
  caVerified: boolean;
  csVerified: boolean;
  documentUrl?: string;
}

interface ComplianceTabProps {
  startup: Startup;
  userRole?: string;
}

const ComplianceTab: React.FC<ComplianceTabProps> = ({ startup, userRole }) => {
    const [complianceTasks, setComplianceTasks] = useState<ComplianceTask[]>([
        {
            id: 1,
            entity: 'Parent Company',
            year: '2025',
            taskDescription: 'Board Meeting Minutes',
            caVerified: true,
            csVerified: false
        },
        {
            id: 2,
            entity: 'Subsidiary 1 (UK)',
            year: '2025',
            taskDescription: 'Board Meeting Minutes',
            caVerified: true,
            csVerified: false
        },
        {
            id: 3,
            entity: 'Parent Company',
            year: '2024',
            taskDescription: 'Board Meeting Minutes',
            caVerified: true,
            csVerified: false
        },
        {
            id: 4,
            entity: 'Subsidiary 1 (UK)',
            year: '2024',
            taskDescription: 'Board Meeting Minutes',
            caVerified: true,
            csVerified: false
        },
        {
            id: 5,
            entity: 'Parent Company',
            year: '2023',
            taskDescription: 'Board Meeting Minutes',
            caVerified: true,
            csVerified: false
        },
        {
            id: 6,
            entity: 'Subsidiary 1 (UK)',
            year: '2023',
            taskDescription: 'Company Incorporation Forms',
            caVerified: true,
            csVerified: false
        },
        {
            id: 7,
            entity: 'Subsidiary 1 (UK)',
            year: '2023',
            taskDescription: 'Initial Director Consent Forms',
            caVerified: true,
            csVerified: false
        }
    ]);

    const [newTask, setNewTask] = useState({
        entity: 'Parent Company',
        year: '2025',
        taskDescription: ''
    });

    const [entities] = useState([
        'Parent Company',
        'Subsidiary 1 (UK)',
        'Subsidiary 2 (Germany)',
        'Subsidiary 3 (India)'
    ]);

    const handleAddTask = () => {
        if (newTask.taskDescription.trim()) {
            const task: ComplianceTask = {
                id: Date.now(),
                entity: newTask.entity,
                year: newTask.year,
                taskDescription: newTask.taskDescription,
                caVerified: false,
                csVerified: false
            };
            setComplianceTasks([...complianceTasks, task]);
            setNewTask({
                entity: 'Parent Company',
                year: '2025',
                taskDescription: ''
            });
        }
    };

    const handleUpload = (taskId: number) => {
        // TODO: Implement file upload functionality
        console.log('Upload for task:', taskId);
    };

    const getVerificationIcon = (verified: boolean, type: 'ca' | 'cs') => {
        if (verified) {
            return <CheckCircle className="h-5 w-5 text-green-500" />;
        } else {
            return <MinusCircle className="h-5 w-5 text-gray-400" />;
        }
    };

    const canEdit = userRole === 'Startup' || userRole === 'Admin';

    return (
        <div className="space-y-6">
            {/* Add Additional Compliance Section */}
            {canEdit && (
                <Card>
                    <h3 className="text-lg font-semibold mb-4 text-slate-700">Add Additional Compliance</h3>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <Select 
                            label="Entity" 
                            id="entity" 
                            value={newTask.entity} 
                            onChange={e => setNewTask({ ...newTask, entity: e.target.value })}
                        >
                            {entities.map(entity => (
                                <option key={entity} value={entity}>{entity}</option>
                            ))}
                        </Select>
                        <Input 
                            label="Year" 
                            id="year" 
                            type="text" 
                            value={newTask.year} 
                            onChange={e => setNewTask({ ...newTask, year: e.target.value })}
                        />
                        <Input 
                            label="Task Description" 
                            id="taskDescription" 
                            type="text" 
                            value={newTask.taskDescription} 
                            onChange={e => setNewTask({ ...newTask, taskDescription: e.target.value })}
                            placeholder="Enter task description"
                        />
                    </div>
                    <div className="mt-4">
                        <Button onClick={handleAddTask} className="flex items-center">
                            <Plus className="h-4 w-4 mr-2" /> Add Task
                            </Button>
                        </div>
                </Card>
            )}

            {/* Company Compliance Table */}
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Company Compliance</h3>
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead>
                            <tr className="border-b border-slate-200">
                                <th className="text-left py-3 px-4 font-semibold text-slate-700">ENTITY</th>
                                <th className="text-left py-3 px-4 font-semibold text-slate-700">YEAR</th>
                                <th className="text-left py-3 px-4 font-semibold text-slate-700">TASK</th>
                                <th className="text-left py-3 px-4 font-semibold text-slate-700">ACTION</th>
                                <th className="text-left py-3 px-4 font-semibold text-slate-700">CA VERIFIED</th>
                                <th className="text-left py-3 px-4 font-semibold text-slate-700">CS VERIFIED</th>
                            </tr>
                        </thead>
                        <tbody>
                            {complianceTasks.map(task => (
                                <tr key={task.id} className="border-b border-slate-100 hover:bg-slate-50">
                                    <td className="py-3 px-4 text-slate-900">{task.entity}</td>
                                    <td className="py-3 px-4 text-slate-900">{task.year}</td>
                                    <td className="py-3 px-4 text-slate-900">{task.taskDescription}</td>
                                    <td className="py-3 px-4">
                                        <Button 
                                            variant="secondary" 
                                            size="sm" 
                                            onClick={() => handleUpload(task.id)}
                                            className="flex items-center"
                                        >
                                            <Upload className="h-4 w-4 mr-1" /> Upload
                                        </Button>
                                    </td>
                                    <td className="py-3 px-4">
                                        {getVerificationIcon(task.caVerified, 'ca')}
                                    </td>
                                    <td className="py-3 px-4">
                                        {getVerificationIcon(task.csVerified, 'cs')}
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

export default ComplianceTab;