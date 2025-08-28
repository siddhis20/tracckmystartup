import React, { useMemo, useState, useEffect, useRef } from 'react';
import { Startup, ComplianceStatus, UserRole } from '../../types';
import { COMPLIANCE_RULES, COUNTRIES } from '../../constants';
import { complianceRulesService } from '../../lib/complianceRulesService';
import { complianceService, ComplianceTask, ComplianceUpload } from '../../lib/complianceService';
import { UploadCloud, Download, Trash2, Eye, X, CheckCircle, AlertCircle, Clock } from 'lucide-react';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Modal from '../ui/Modal';

type CurrentUserLike = { role: UserRole; email?: string; serviceCode?: string };

interface ComplianceTabProps {
  startup: Startup;
  currentUser?: CurrentUserLike;
  onUpdateCompliance?: (startupId: number, taskId: string, checker: 'ca' | 'cs', newStatus: ComplianceStatus) => void;
  isViewOnly?: boolean;
  allowCAEdit?: boolean; // This now allows both CA and CS editing
}

interface GeneratedTask {
    entityIdentifier: string;
    entityDisplayName: string;
    year: number;
    task: string;
    taskId: string;
    action: 'Upload';
    caRequired: boolean;
    csRequired: boolean;
}

const VerificationStatusDisplay: React.FC<{ status: ComplianceStatus }> = ({ status }) => {
    let colorClass = "";
    let icon = null;
    
    switch (status) {
        case ComplianceStatus.Verified: 
            colorClass = "text-green-600"; 
            icon = <CheckCircle className="w-4 h-4" />;
            break;
        case ComplianceStatus.Rejected: 
            colorClass = "text-red-600"; 
            icon = <AlertCircle className="w-4 h-4" />;
            break;
        case ComplianceStatus.Pending: 
            colorClass = "text-yellow-600"; 
            icon = <Clock className="w-4 h-4" />;
            break;
        case ComplianceStatus.NotRequired: 
            colorClass = "text-gray-500"; 
            break;
        default: 
            colorClass = "text-gray-600";
    }
    
    return (
        <span className={`font-semibold ${colorClass} flex items-center justify-center gap-1 w-full`}>
            {icon}
            {status}
        </span>
    );
};

const ComplianceTab: React.FC<ComplianceTabProps> = ({ startup, currentUser, onUpdateCompliance, isViewOnly = false, allowCAEdit = false }) => {
    console.log('🔍 ComplianceTab props:', { 
        userRole: currentUser?.role, 
        isViewOnly, 
        allowCAEdit,
        startupId: startup.id 
    });
    
    const [complianceTasks, setComplianceTasks] = useState<ComplianceTask[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [uploadModalOpen, setUploadModalOpen] = useState(false);
    const [selectedTask, setSelectedTask] = useState<GeneratedTask | null>(null);
    const [uploading, setUploading] = useState(false);
    const [selectedFile, setSelectedFile] = useState<File | null>(null);
    const [uploadSuccess, setUploadSuccess] = useState(false);
    const [deleteModalOpen, setDeleteModalOpen] = useState(false);
    const [deleteTargetId, setDeleteTargetId] = useState<string | null>(null);
    const [filters, setFilters] = useState({
        entity: 'all',
        year: 'all'
    });
    const fileInputRef = useRef<HTMLInputElement>(null);

    // Generate compliance tasks based on profile (falls back to DB tasks if profile incomplete)
    const generatedTasks = useMemo((): { [entityName: string]: GeneratedTask[] } => {
        const groups: { [entityName: string]: GeneratedTask[] } = {};
        const currentYear = new Date().getFullYear();
        
        // Prefer explicit profile; gracefully handle missing data
        const profileData = startup.profile && startup.profile.country && startup.profile.companyType
            ? startup.profile
            : {
                country: '',
                companyType: '',
                registrationDate: '',
                subsidiaries: [],
                internationalOps: []
            };

        console.log('ComplianceTab - Current profile data:', profileData);
        console.log('ComplianceTab - Subsidiaries count:', profileData.subsidiaries?.length || 0);

        // If essential fields are missing, stop generation here; the UI will still render DB-backed tasks
        if (!profileData.country || !profileData.companyType || !profileData.registrationDate) {
            console.log('ComplianceTab - Incomplete profile; relying on DB tasks if present');
            return groups;
        }

        const processEntity = (entity: { identifier: string; displayName: string, regDate: string, country: string, companyType: string }) => {
            if (!entity.regDate) return;
            const registrationYear = new Date(entity.regDate).getFullYear();
            
            // Prefer DB rules; fallback to constants
            let dbCountry: any = null;
            try {
                // Note: use synchronous cache pattern by reading from window to avoid async in memo
                dbCountry = (window as any).__dbComplianceRules?.[entity.country] || null;
            } catch {}
            const sourceCountryRules = dbCountry || COMPLIANCE_RULES[entity.country] || COMPLIANCE_RULES['default'];
            const rules = sourceCountryRules[entity.companyType] || sourceCountryRules.default;
            
            if (!rules || Array.isArray(rules)) {
                console.log(`ComplianceTab - No rules found for ${entity.country}/${entity.companyType}`);
                return;
            }
            
            if (!groups[entity.displayName]) groups[entity.displayName] = [];

            console.log(`ComplianceTab - Processing entity: ${entity.displayName}, Registration: ${registrationYear}, Current: ${currentYear}`);

            // Generate tasks from registration year to current year
            for (let year = registrationYear; year <= currentYear; year++) {
                const yearTasks: GeneratedTask[] = [];
                
                // First year tasks (only for registration year)
                if (year === registrationYear && rules.firstYear) {
                    console.log(`ComplianceTab - Adding first year tasks for ${year}:`, rules.firstYear.length);
                    rules.firstYear.forEach(rule => {
                        yearTasks.push({
                            entityIdentifier: entity.identifier,
                            entityDisplayName: entity.displayName,
                            year: year,
                            task: rule.name,
                            taskId: `${entity.identifier}-${year}-fy-${rule.id}`,
                            action: 'Upload',
                            caRequired: rule.caRequired,
                            csRequired: rule.csRequired,
                        });
                    });
                }
                
                // Annual tasks (for all years)
                if(rules.annual) {
                    console.log(`ComplianceTab - Adding annual tasks for ${year}:`, rules.annual.length);
                    rules.annual.forEach(rule => {
                         yearTasks.push({
                            entityIdentifier: entity.identifier,
                            entityDisplayName: entity.displayName,
                            year: year,
                            task: rule.name,
                            taskId: `${entity.identifier}-${year}-an-${rule.id}`,
                            action: 'Upload',
                            caRequired: rule.caRequired,
                            csRequired: rule.csRequired,
                        });
                    });
                }
                groups[entity.displayName].push(...yearTasks);
            }
        };

        // Process parent company
        processEntity({ 
            identifier: 'parent', 
            displayName: `Parent Company (${profileData.country})`, 
            regDate: profileData.registrationDate, 
            country: profileData.country, 
            companyType: profileData.companyType 
        });
        
        // Process subsidiaries - only if they exist and have registration dates
        if (profileData.subsidiaries && profileData.subsidiaries.length > 0) {
            profileData.subsidiaries.forEach((sub, i) => {
                if (sub.registrationDate) {
                    processEntity({ 
                        identifier: `sub-${i}`, 
                        displayName: `Subsidiary ${i + 1} (${sub.country})`, 
                        regDate: sub.registrationDate, 
                        country: sub.country, 
                        companyType: sub.companyType 
                    });
                }
            });
        }

        // Process international operations - use parent companyType, per-country ops
        if (profileData.internationalOps && profileData.internationalOps.length > 0) {
            profileData.internationalOps.forEach((op, i) => {
                if (op.startDate) {
                    processEntity({
                        identifier: `intl-${i}`,
                        displayName: `International Operation ${i + 1} (${op.country})`,
                        regDate: op.startDate,
                        country: op.country,
                        companyType: profileData.companyType
                    });
                }
            });
        }

        // Sort tasks by year (descending) and task name
        Object.values(groups).forEach(taskList => {
            taskList.sort((a, b) => b.year - a.year || a.task.localeCompare(b.task));
        });

        console.log('ComplianceTab - Generated tasks:', Object.keys(groups));
        return groups;
    }, [startup.profile]);

    // Load compliance data from backend
    useEffect(() => {
        // Warm local cache of DB rules for memo usage
        (async () => {
            try {
                const all = await complianceRulesService.listAll();
                const map: any = {};
                all.forEach(row => { map[row.country_code] = row.rules; });
                (window as any).__dbComplianceRules = map;
            } catch (e) {
                // ignore
            }
        })();
        loadComplianceData();
    }, [startup.id, startup.profile?.country, startup.profile?.companyType, startup.profile?.registrationDate]); // Reload when profile essentials change

    // Sync compliance tasks when profile changes (for new tasks)
    useEffect(() => {
        if (startup.profile) {
            console.log('🔍 Profile changed, syncing compliance tasks...');
            complianceService.syncComplianceTasksWithDatabase(startup.id).then(() => {
                loadComplianceData();
            });
        }
    }, [startup.profile, startup.id]);

    // Subscribe to real-time updates
    useEffect(() => {
        const subscription = complianceService.subscribeToComplianceTaskChanges(startup.id, (payload) => {
            console.log('Compliance change detected:', payload);
            loadComplianceData();
        });

        return () => {
            subscription.unsubscribe();
        };
    }, [startup.id]);

    const loadComplianceData = async () => {
        try {
            setIsLoading(true);

            // Use the new real-time method that generates tasks from profile if needed
            const [tasks, allUploads] = await Promise.all([
                complianceService.getComplianceTasksWithRealtime(startup.id),
                complianceService.getAllComplianceUploads(startup.id)
            ]);
            
            // Combine tasks with their uploads
            const tasksWithUploads = tasks.map(task => ({
                ...task,
                uploads: allUploads[task.taskId] || []
            }));
            
            console.log('🔍 Loaded compliance data:', tasksWithUploads);
            setComplianceTasks(tasksWithUploads);

            // After loading tasks, ensure overall startup status reflects per-task verification
            await syncOverallComplianceStatus(tasksWithUploads);

            // Auto-resync guard against stale tasks from old countries when profile changed
            if (startup.profile) {
                const expectedEntities = new Set<string>();
                expectedEntities.add(`Parent Company (${startup.profile.country})`);
                (startup.profile.subsidiaries || []).forEach((sub, i) => {
                    expectedEntities.add(`Subsidiary ${i + 1} (${sub.country})`);
                });

                const actualEntities = new Set(tasksWithUploads.map(t => t.entityDisplayName));
                const hasMismatch = Array.from(actualEntities).some(name => !expectedEntities.has(name));

                if (hasMismatch) {
                    console.warn('⚠️ Detected stale compliance tasks (entity mismatch). Forcing resync.');
                    await complianceService.syncComplianceTasksWithDatabase(startup.id);
                    await loadComplianceData();
                }
            }
        } catch (error) {
            console.error('Error loading compliance data:', error);
            setComplianceTasks([]);
        } finally {
            setIsLoading(false);
        }
    };

    // Compute and update overall startup compliance based on task statuses
    const syncOverallComplianceStatus = async (tasks: ComplianceTask[]) => {
        try {
            if (!tasks || tasks.length === 0) return;

            // CS rule requested:
            // - If user is CS: Compliant only when ALL CS-required tasks are Verified; otherwise Pending.
            // - For other roles: original behavior (rejections -> Non-Compliant; all required verified -> Compliant; else Pending).
            let hasRejected = false;
            let csHasRejected = false;
            let caHasRejected = false;
            let allRequiredVerifiedForCurrentRole = true;

            for (const t of tasks) {
                const caRequired = !!t.caRequired;
                const csRequired = !!t.csRequired;
                const caStatus = t.caStatus;
                const csStatus = t.csStatus;

                if (caRequired && caStatus === ComplianceStatus.Rejected) {
                    hasRejected = true;
                    caHasRejected = true;
                }
                if (csRequired && csStatus === ComplianceStatus.Rejected) {
                    hasRejected = true;
                    csHasRejected = true;
                }

                // Role-scoped completeness
                if (currentUser?.role === 'CA') {
                    if (caRequired && caStatus !== ComplianceStatus.Verified) {
                        allRequiredVerifiedForCurrentRole = false;
                    }
                } else if (currentUser?.role === 'CS') {
                    if (csRequired && csStatus !== ComplianceStatus.Verified) {
                        allRequiredVerifiedForCurrentRole = false;
                    }
                } else {
                    // Fallback: require both if role not CA/CS
                    if ((caRequired && caStatus !== ComplianceStatus.Verified) || (csRequired && csStatus !== ComplianceStatus.Verified)) {
                        allRequiredVerifiedForCurrentRole = false;
                    }
                }
            }

            let targetStatus: ComplianceStatus;
            if (currentUser?.role === 'CS') {
                // CS: Non-Compliant if any CS-required is Rejected; otherwise Compliant only if all CS-required are Verified
                targetStatus = csHasRejected
                    ? ComplianceStatus.NonCompliant
                    : allRequiredVerifiedForCurrentRole
                    ? ComplianceStatus.Compliant
                    : ComplianceStatus.Pending;
            } else if (currentUser?.role === 'CA') {
                // CA: Non-Compliant if any CA-required is Rejected; otherwise Compliant only if all CA-required are Verified
                targetStatus = caHasRejected
                    ? ComplianceStatus.NonCompliant
                    : allRequiredVerifiedForCurrentRole
                    ? ComplianceStatus.Compliant
                    : ComplianceStatus.Pending;
            } else {
                // Fallback legacy behavior
                targetStatus = hasRejected
                    ? ComplianceStatus.NonCompliant
                    : allRequiredVerifiedForCurrentRole
                        ? ComplianceStatus.Compliant
                        : ComplianceStatus.Pending;
            }

            // If already matches current, skip update
            const currentOverall = (startup as any).complianceStatus || ComplianceStatus.Pending;
            if (currentOverall === targetStatus) return;

            try {
                await complianceService.updateStartupOverallCompliance(startup.id, targetStatus);
            } catch (e) {
                console.warn('Failed to update overall startup compliance (non-blocking):', e);
            }
        } catch (e) {
            console.warn('syncOverallComplianceStatus error:', e);
        }
    };

    const getVerificationCell = (item: GeneratedTask, type: 'ca' | 'cs') => {
        // Work even if startup.profile is missing (common for CA view minimal startup object)
        const profile: any = startup.profile || {};

        // Determine entity assignment for CA/CS
        const getAssignedCodes = (identifier: string): { caCode?: string; csCode?: string } => {
            if (identifier === 'parent') {
                return {
                    caCode: profile.ca?.code || profile.caServiceCode,
                    csCode: profile.cs?.code || profile.csServiceCode,
                };
            }
            if (identifier.startsWith('sub-')) {
                const idx = parseInt(identifier.split('-')[1] || '0', 10);
                const sub = profile.subsidiaries?.[idx];
                return {
                    caCode: sub?.ca?.code || sub?.caCode,
                    csCode: sub?.cs?.code || sub?.csCode,
                };
            }
            if (identifier.startsWith('intl-')) {
                // International ops: common access (inherit parent CA/CS codes)
                return {
                    caCode: profile.ca?.code || profile.caServiceCode,
                    csCode: profile.cs?.code || profile.csServiceCode,
                };
            }
            return {};
        };

        const { caCode, csCode } = getAssignedCodes(item.entityIdentifier);
        const userCode = (
            (currentUser as any)?.serviceCode ||
            (currentUser as any)?.ca_code ||
            (currentUser as any)?.cs_code ||
            ''
        ).toString().toLowerCase();
        
        // Simplified logic: Allow CA to edit CA column, CS to edit CS column
        const canEditCA = currentUser?.role === 'CA' && type === 'ca';
        const canEditCS = currentUser?.role === 'CS' && type === 'cs';
        
        console.log('🔍 Verification cell check', { 
            type, 
            userRole: currentUser?.role, 
            canEditCA, 
            canEditCS, 
            allowCAEdit,
            willShowDropdown: (canEditCA && allowCAEdit) || (canEditCS && allowCAEdit)
        });

        const check = complianceTasks.find(c => c.taskId === item.taskId);
        const status = check ? (type === 'ca' ? check.caStatus : check.csStatus) : ComplianceStatus.Pending;
        const isRequired = type === 'ca' ? item.caRequired : item.csRequired;

        console.log('🔍 Task requirement check:', { 
            taskId: item.taskId, 
            type, 
            isRequired, 
            caRequired: item.caRequired, 
            csRequired: item.csRequired 
        });

        // NOTE: We will still show the dropdown for CA/CS editors even if the task is not required,
        // so they can explicitly set a status. If the user is not allowed to edit, we fall back to display.

        // Show dropdown for CA/CS users in their respective columns when allowCAEdit is true
        const shouldShowDropdown = ((canEditCA && allowCAEdit) || (canEditCS && allowCAEdit));
        console.log('🔍 Dropdown decision:', { 
            shouldShowDropdown, 
            canEditCA, 
            canEditCS, 
            allowCAEdit,
            type,
            userRole: currentUser?.role
        });
        
        if (shouldShowDropdown) {
            console.log('🔍 Showing dropdown for', type, 'column');
            return (
                <select
                    value={status}
                    onChange={async (e) => {
                        const newStatus = e.target.value as ComplianceStatus;
                        console.log('Updating compliance status:', {
                            startupId: startup.id,
                            taskId: item.taskId,
                            type,
                            newStatus,
                            user: currentUser?.email
                        });
                        
                        // Update local state immediately for instant UI feedback
                        setComplianceTasks(prevTasks => 
                            prevTasks.map(task => 
                                task.taskId === item.taskId 
                                    ? { 
                                        ...task, 
                                        [type === 'ca' ? 'caStatus' : 'csStatus']: newStatus 
                                    }
                                    : task
                            )
                        );
                        
                        if (onUpdateCompliance) {
                            onUpdateCompliance(startup.id, item.taskId, type, newStatus);
                        }
                        
                        // Update database in background
                        try {
                            await complianceService.updateComplianceStatus(
                                startup.id,
                                item.taskId,
                                type,
                                newStatus,
                                currentUser?.email || 'unknown'
                            );

                            // Recompute and update overall status after a change
                            const updated = complianceTasks.map(task =>
                                task.taskId === item.taskId
                                    ? {
                                        ...task,
                                        [type === 'ca' ? 'caStatus' : 'csStatus']: newStatus,
                                      }
                                    : task
                            );
                            await syncOverallComplianceStatus(updated as any);
                        } catch (error) {
                            console.error('Error updating compliance status:', error);
                            // Revert local state if database update fails
                            setComplianceTasks(prevTasks => 
                                prevTasks.map(task => 
                                    task.taskId === item.taskId 
                                        ? { 
                                            ...task, 
                                            [type === 'ca' ? 'caStatus' : 'csStatus']: status 
                                        }
                                        : task
                                )
                            );
                        }
                    }}
                    className="bg-white border border-gray-300 rounded-md px-2 py-1 text-xs focus:ring-blue-500 focus:border-blue-500"
                >
                    <option value={ComplianceStatus.Pending}>Pending</option>
                    <option value={ComplianceStatus.Verified}>Verified</option>
                    <option value={ComplianceStatus.Rejected}>Rejected</option>
                </select>
            );
        }

        // If user cannot edit: show display; if task is not required show NotRequired explicitly
        console.log('🔍 Showing static display for', type, 'column with status:', status, 'isRequired:', isRequired);
        if (!isRequired) {
            return <VerificationStatusDisplay status={ComplianceStatus.NotRequired} />;
        }
        return <VerificationStatusDisplay status={status} />;
    };

    const handleUpload = (task: GeneratedTask) => {
        setSelectedTask(task);
        setSelectedFile(null);
        setUploadSuccess(false);
        setUploadModalOpen(true);
    };

    const handleFileSelect = (file: File | null) => {
        setSelectedFile(file);
        setUploadSuccess(false);
    };

    const handleFileUpload = async () => {
        if (!selectedTask || !currentUser || !selectedFile) return;

        try {
            setUploading(true);
            const result = await complianceService.uploadComplianceDocument(
                startup.id,
                selectedTask.taskId,
                selectedFile,
                currentUser.email || 'unknown'
            );
            
            if (result) {
                console.log('Upload successful:', result);
                setUploadSuccess(true);
                setSelectedFile(null);
                loadComplianceData(); // Refresh data
                
                // Close modal after 2 seconds
                setTimeout(() => {
                    setUploadModalOpen(false);
                    setSelectedTask(null);
                    setUploadSuccess(false);
                }, 2000);
            } else {
                alert('Upload failed. Please check if the database tables are set up correctly.');
            }
        } catch (error) {
            console.error('Error uploading file:', error);
            alert('Error uploading file. Please try again.');
        } finally {
            setUploading(false);
        }
    };

    const handleDeleteUpload = async (uploadId: string) => {
        if (!currentUser) return;

        // Set the target ID and open confirmation modal
        setDeleteTargetId(uploadId);
        setDeleteModalOpen(true);
    };

    const confirmDelete = async () => {
        if (!deleteTargetId) return;

        try {
            const success = await complianceService.deleteComplianceUpload(deleteTargetId);
            if (success) {
                console.log('Delete successful');
                loadComplianceData(); // Refresh data
            } else {
                alert('Delete failed. Please try again.');
            }
        } catch (error) {
            console.error('Delete error:', error);
            alert('Delete failed. Please try again.');
        } finally {
            setDeleteModalOpen(false);
            setDeleteTargetId(null);
        }
    };

    const getUploadsForTask = useMemo(() => (taskId: string): ComplianceUpload[] => {
        const task = complianceTasks.find(t => t.taskId === taskId);
        return task?.uploads || [];
    }, [complianceTasks]);

    // Only Startup/Admin can upload/delete. Everyone can view existing uploads.
    const canUpload = currentUser?.role === 'Startup' || currentUser?.role === 'Admin';

    // Group DB tasks by entity for display (filter out stale entities not in profile)
    const dbTasksGrouped = useMemo((): { [entityName: string]: GeneratedTask[] } => {
        if (!complianceTasks || complianceTasks.length === 0) return {};
        
        const groups: { [entityName: string]: GeneratedTask[] } = {};
        const expectedEntities = new Set<string>();
        
        // Build expected entity names
        if (startup.profile?.country) {
            expectedEntities.add(`Parent Company (${startup.profile.country})`);
        }
        (startup.profile?.subsidiaries || []).forEach((sub, i) => {
            expectedEntities.add(`Subsidiary ${i + 1} (${sub.country})`);
        });
        (startup.profile?.internationalOps || []).forEach((op, i) => {
            expectedEntities.add(`International Operation ${i + 1} (${op.country})`);
        });
        
        // Group tasks by entity
        for (const t of complianceTasks) {
            if (expectedEntities.size > 0 && !expectedEntities.has(t.entityDisplayName)) {
                continue; // Skip stale entities
            }
            if (!groups[t.entityDisplayName]) groups[t.entityDisplayName] = [];
            groups[t.entityDisplayName].push({
                entityIdentifier: t.entityIdentifier,
                entityDisplayName: t.entityDisplayName,
                year: t.year,
                task: t.task,
                taskId: t.taskId,
                action: 'Upload',
                caRequired: t.caRequired,
                csRequired: t.csRequired,
            });
        }
        
        // Sort within groups for consistency
        Object.values(groups).forEach(taskList => {
            taskList.sort((a, b) => b.year - a.year || a.task.localeCompare(b.task));
        });
        
        return groups;
    }, [complianceTasks, startup.profile?.country, startup.profile?.subsidiaries]);

    // Prefer DB-backed tasks; fall back to generated client-side tasks
    const displayTasks = useMemo(() => {
        const hasDbTasks = Object.keys(dbTasksGrouped).length > 0;
        return hasDbTasks ? dbTasksGrouped : generatedTasks;
    }, [dbTasksGrouped, generatedTasks]);

    // Filter tasks based on current filters
    const filteredTasks = useMemo(() => {
        if (filters.entity === 'all' && filters.year === 'all') {
            return displayTasks;
        }
        
        return Object.fromEntries(
            Object.entries(displayTasks).map(([entityName, tasks]) => [
                entityName,
                tasks.filter(task => 
                    (filters.entity === 'all' || entityName.includes(filters.entity)) &&
                    (filters.year === 'all' || task.year === parseInt(filters.year))
                )
            ]).filter(([_, tasks]) => tasks.length > 0)
        );
    }, [displayTasks, filters]);

    if (isLoading) {
        return (
            <div className="space-y-6">
                <div className="animate-pulse">
                    <div className="h-8 bg-gray-200 rounded w-1/3 mb-4"></div>
                    <div className="space-y-4">
                        {[1, 2, 3].map(i => (
                            <div key={i} className="h-32 bg-gray-200 rounded"></div>
                        ))}
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div className="flex justify-between items-center">
                <h2 className="text-2xl font-semibold text-slate-700">Compliance Checklist</h2>
                
                {/* Filters */}
                <div className="flex gap-4">
                    <select 
                        value={filters.entity} 
                        onChange={(e) => setFilters(prev => ({ ...prev, entity: e.target.value }))}
                        className="bg-white border border-gray-300 rounded-md px-3 py-1 text-sm"
                    >
                        <option value="all">All Entities</option>
                        {Object.keys(displayTasks).map(entity => (
                            <option key={entity} value={entity}>{entity}</option>
                        ))}
                    </select>
                    
                    <select 
                        value={filters.year} 
                        onChange={(e) => setFilters(prev => ({ ...prev, year: e.target.value }))}
                        className="bg-white border border-gray-300 rounded-md px-3 py-1 text-sm"
                    >
                        <option value="all">All Years</option>
                        {Array.from(new Set(Object.values(displayTasks).flat().map(task => task.year)))
                            .sort((a, b) => b - a)
                            .map(year => (
                                <option key={year} value={year}>{year}</option>
                            ))
                        }
                    </select>
                </div>
            </div>

            {Object.keys(filteredTasks).length > 0 ? (
                Object.entries(filteredTasks).map(([entityName, tasks]) => (
                    <Card key={entityName}>
                        <h3 className="text-xl font-semibold text-slate-700 mb-4">{entityName}</h3>
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead className="bg-slate-50">
                                    <tr>
                                        <th className="p-4 text-sm font-semibold text-slate-600 uppercase tracking-wider text-center w-20">Year</th>
                                        <th className="p-4 text-sm font-semibold text-slate-600 uppercase tracking-wider text-left w-48">Task</th>
                                        <th className="p-4 text-sm font-semibold text-slate-600 uppercase tracking-wider text-center w-32">CA Verified</th>
                                        <th className="p-4 text-sm font-semibold text-slate-600 uppercase tracking-wider text-center w-32">CS Verified</th>
                                        <th className="p-4 text-sm font-semibold text-slate-600 uppercase tracking-wider text-center w-32">Action</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-200 align-middle">
                                    {tasks.map((item) => {
                                        console.log('🔍 Rendering task:', { 
                                            taskId: item.taskId, 
                                            task: item.task, 
                                            caRequired: item.caRequired, 
                                            csRequired: item.csRequired 
                                        });
                                        const uploads = getUploadsForTask(item.taskId);
                                        return (
                                            <tr key={item.taskId} className="hover:bg-slate-50 transition-colors h-16">
                                                <td className="p-4 whitespace-nowrap text-slate-600 text-center align-middle w-20">{item.year}</td>
                                                <td className="p-4 whitespace-normal text-slate-900 font-medium text-left align-middle w-48">{item.task}</td>
                                                <td className="p-4 whitespace-nowrap text-slate-600 text-center align-middle w-32">{getVerificationCell(item, 'ca')}</td>
                                                <td className="p-4 whitespace-nowrap text-slate-600 text-center align-middle w-32">{getVerificationCell(item, 'cs')}</td>
                                                <td className="p-4 whitespace-nowrap text-center align-middle w-32">
                                                    <div className="flex items-center gap-2 justify-center">
                                                        {/* Anyone can view if a document exists */}
                                                        {uploads.length > 0 && (
                                                            <button 
                                                                onClick={() => window.open(uploads[0].fileUrl, '_blank')}
                                                                className="px-3 py-2 rounded-md font-semibold transition-colors flex items-center gap-2 text-xs bg-green-100 text-green-700 hover:bg-green-200"
                                                                title="View document"
                                                            >
                                                                <Eye size={14} />
                                                                View
                                                            </button>
                                                        )}

                                                        {/* Only Startup/Admin can upload/delete */}
                                                        {canUpload && uploads.length === 0 && (
                                                            <button 
                                                                onClick={() => handleUpload(item)}
                                                                className="px-3 py-2 rounded-md font-semibold transition-colors flex items-center gap-2 text-xs bg-blue-100 text-blue-700 hover:bg-blue-200"
                                                                title="Upload document"
                                                            >
                                                                <UploadCloud size={14} />
                                                                Upload
                                                            </button>
                                                        )}
                                                        {canUpload && uploads.length > 0 && (
                                                            <button 
                                                                onClick={() => handleDeleteUpload(uploads[0].id)}
                                                                className="px-3 py-2 rounded-md font-semibold transition-colors flex items-center gap-2 text-xs bg-red-100 text-red-700 hover:bg-red-200"
                                                                title="Delete document"
                                                            >
                                                                <Trash2 size={14} />
                                                                Delete
                                                            </button>
                                                        )}
                                                    </div>
                                                </td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>
                    </Card>
                ))
            ) : (
                <Card>
                    <div className="p-8 text-center text-slate-500">
                        {!startup.profile?.country || !startup.profile?.companyType || !startup.profile?.registrationDate ? (
                            <div>
                                <p className="text-lg font-semibold mb-2">No Profile Data</p>
                                <p>Please complete your startup profile first to generate compliance tasks.</p>
                                <p className="text-sm mt-2">Go to the Profile tab and set your country, company type, and registration date.</p>
                                <p className="text-sm mt-2 text-blue-600">
                                    Debug Info: Country: {startup.profile?.country || 'Not set'} | 
                                    Type: {startup.profile?.companyType || 'Not set'} | 
                                    Date: {startup.profile?.registrationDate || 'Not set'}
                                </p>
                            </div>
                        ) : Object.keys(generatedTasks).length === 0 && complianceTasks.length === 0 ? (
                            <div>
                                <p className="text-lg font-semibold mb-2">No Compliance Tasks Generated</p>
                                <p>Compliance tasks should be generated based on your profile settings.</p>
                                <p className="text-sm mt-2">
                                    Country: <span className="font-medium">{startup.profile?.country}</span> | 
                                    Company Type: <span className="font-medium">{startup.profile?.companyType}</span> | 
                                    Registration: <span className="font-medium">{startup.profile?.registrationDate}</span>
                                </p>
                                <p className="text-sm mt-2">
                                    No compliance rules found for this country/company type combination.
                                </p>
                                <p className="text-sm mt-2 text-blue-600">
                                    Available countries: {Object.keys(COMPLIANCE_RULES).join(', ')}
                                </p>
                                <p className="text-sm mt-2 text-gray-500">
                                    Please check if your country and company type are supported in the compliance rules.
                                </p>
                            </div>
                        ) : (
                            <div>
                                <p className="text-lg font-semibold mb-2">Tasks Generated But Not Displaying</p>
                                <p>Compliance tasks are generated but there might be a display issue.</p>
                                <p className="text-sm mt-2 text-blue-600">
                                    Generated tasks: {Object.keys(generatedTasks).length} entities | DB tasks: {complianceTasks.length}
                                </p>
                                <p className="text-sm mt-2 text-gray-500">
                                    Try refreshing the page or check the console for errors.
                                </p>
                            </div>
                        )}
                        </div>
                </Card>
            )}

            {/* Upload Modal */}
            <Modal isOpen={uploadModalOpen} onClose={() => setUploadModalOpen(false)}>
                <div className="p-6">
                    <h3 className="text-lg font-semibold mb-4">Upload Compliance Document</h3>
                    <p className="text-sm text-gray-600 mb-4">
                        Task: {selectedTask?.task} ({selectedTask?.year})
                    </p>
                    
                    {uploadSuccess ? (
                        <div className="text-center py-8">
                            <div className="text-green-600 mb-4">
                                <CheckCircle className="w-16 h-16 mx-auto" />
                            </div>
                            <h4 className="text-lg font-semibold text-green-600 mb-2">Upload Successful!</h4>
                            <p className="text-sm text-gray-600">Your document has been uploaded successfully.</p>
                            <p className="text-xs text-gray-500 mt-2">This window will close automatically...</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center">
                                <input
                                    ref={fileInputRef}
                                    type="file"
                                    accept=".pdf"
                                    onChange={(e) => {
                                        const file = e.target.files?.[0];
                                        if (file) {
                                            // Check if file is PDF
                                            if (file.type !== 'application/pdf') {
                                                alert('Please select a PDF file only.');
                                                return;
                                            }
                                            handleFileSelect(file);
                                        }
                                    }}
                                    className="hidden"
                                />
                                
                                {selectedFile ? (
                                    <div className="space-y-2">
                                        <div className="flex items-center justify-center gap-2 text-sm">
                                            <UploadCloud className="w-5 h-5 text-blue-600" />
                                            <span className="font-medium">{selectedFile.name}</span>
                                        </div>
                                        <p className="text-xs text-gray-500">
                                            Size: {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                                        </p>
                                        <button
                                            onClick={() => handleFileSelect(null)}
                                            className="text-red-600 text-xs hover:text-red-800"
                                        >
                                            Remove file
                                        </button>
                                    </div>
                                ) : (
                                    <div className="space-y-2">
                                        <UploadCloud className="w-8 h-8 text-gray-400 mx-auto" />
                                        <p className="text-sm text-gray-600">Click to select a PDF file</p>
                                        <p className="text-xs text-gray-500">Only PDF files are accepted</p>
                                        <button
                                            onClick={() => fileInputRef.current?.click()}
                                            className="bg-blue-100 text-blue-700 px-4 py-2 rounded-md text-sm hover:bg-blue-200 transition-colors"
                                        >
                                            Choose File
                                        </button>
                                    </div>
                                )}
                            </div>
                            
                            <div className="flex justify-end gap-3">
                                <Button 
                                    variant="secondary" 
                                    onClick={() => {
                                        setUploadModalOpen(false);
                                        setSelectedFile(null);
                                        setUploadSuccess(false);
                                    }}
                                    disabled={uploading}
                                >
                                    Cancel
                                </Button>
                                <Button 
                                    onClick={handleFileUpload}
                                    disabled={uploading || !selectedFile}
                                    className={!selectedFile ? 'opacity-50 cursor-not-allowed' : ''}
                                >
                                    {uploading ? 'Uploading...' : 'Upload Document'}
                                </Button>
                            </div>
                        </div>
                    )}
                </div>
            </Modal>

            {/* Delete Confirmation Modal */}
            <Modal isOpen={deleteModalOpen} onClose={() => setDeleteModalOpen(false)}>
                <div className="p-6">
                    <div className="text-center">
                        <div className="text-red-600 mb-4">
                            <AlertCircle className="w-16 h-16 mx-auto" />
                        </div>
                        <h3 className="text-lg font-semibold text-red-600 mb-2">Confirm Deletion</h3>
                        <p className="text-sm text-gray-600 mb-6">
                            Are you sure you want to delete this document? This action cannot be undone.
                        </p>
                        <div className="flex justify-center gap-3">
                            <Button 
                                variant="secondary" 
                                onClick={() => setDeleteModalOpen(false)}
                            >
                                Cancel
                            </Button>
                            <Button 
                                onClick={confirmDelete}
                                className="bg-red-600 hover:bg-red-700 text-white"
                            >
                                Delete Document
                            </Button>
                        </div>
                    </div>
                </div>
            </Modal>
        </div>
    );
};

export default ComplianceTab;