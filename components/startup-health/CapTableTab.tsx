import React, { useState, useEffect } from 'react';
import { Startup, InvestmentRecord, InvestorType, InvestmentRoundType, Founder, FundraisingDetails, UserRole, InvestmentType, IncubationProgram, AddIncubationProgramData, RecognitionRecord, IncubationType, FeeType } from '../../types';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import SimpleModal from '../ui/SimpleModal';
import Select from '../ui/Select';
import Modal from '../ui/Modal';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { Plus, Trash2, Edit3, Save, X, TrendingUp, Users, DollarSign, PieChart as PieChartIcon, UserPlus, Download, Upload, Check, Eye, RefreshCw } from 'lucide-react';
import { capTableService } from '../../lib/capTableService';
import { startupAdditionService } from '../../lib/database';
import { incubationProgramsService } from '../../lib/incubationProgramsService';
import { financialsService } from '../../lib/financialsService';
import { validationService } from '../../lib/validationService';
import { recognitionService } from '../../lib/recognitionService';
import { storageService } from '../../lib/storage';
import { AuthUser } from '../../lib/auth';
import { supabase } from '../../lib/supabase';
import { Loader2 } from 'lucide-react';

interface CapTableTabProps {
  startup: Startup;
  userRole?: UserRole;
  user?: AuthUser;
  onActivateFundraising: (details: FundraisingDetails, startup: Startup) => void;
  onInvestorAdded: (investment: InvestmentRecord, startup: Startup) => void;
  onUpdateFounders: (startupId: number, founders: Founder[]) => void;
  isViewOnly?: boolean;
}

interface FounderStateItem extends Founder {
  id: number;
}

interface InvestmentSummary {
  totalEquityFunding: number;
  totalDebtFunding: number;
  totalGrantFunding: number;
  totalInvestments: number;
  avgEquityAllocated: number;
}

interface ValuationHistoryData {
  roundName: string;
  valuation: number;
  investmentAmount: number;
  date: string;
}

interface EquityDistributionData {
  holderType: string;
  equityPercentage: number;
  totalAmount: number;
}

// Types for offers received
interface OfferReceived {
  id: string;
  from: string;
  type: 'Incubation' | 'Due Diligence';
  offerDetails: string;
  status: 'pending' | 'accepted' | 'rejected';
  code: string;
  agreementUrl?: string;
  applicationId: string;
  createdAt: string;
}

const formatCurrency = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
const formatCurrencyCompact = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact' }).format(value);

const COLORS = ['#1e40af', '#1d4ed8', '#3b82f6', '#60a5fa'];

const CapTableTab: React.FC<CapTableTabProps> = ({ startup, userRole, user, onActivateFundraising, onInvestorAdded, onUpdateFounders, isViewOnly }) => {
    const [isEditing, setIsEditing] = useState(false);
    const [isFundraisingModalOpen, setIsFundraisingModalOpen] = useState(false);
    const [isAddInvestorModalOpen, setIsAddInvestorModalOpen] = useState(false);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    
    // Real data states
    const [investmentRecords, setInvestmentRecords] = useState<InvestmentRecord[]>([]);
    const [recognitionRecords, setRecognitionRecords] = useState<RecognitionRecord[]>([]);
    const [founders, setFounders] = useState<Founder[]>([]);
    const [fundraisingDetails, setFundraisingDetails] = useState<FundraisingDetails[]>([]);
    const [valuationHistory, setValuationHistory] = useState<ValuationHistoryData[]>([]);
    const [equityDistribution, setEquityDistribution] = useState<EquityDistributionData[]>([]);
    const [investmentSummary, setInvestmentSummary] = useState<InvestmentSummary>({
        totalEquityFunding: 0,
        totalDebtFunding: 0,
        totalGrantFunding: 0,
        totalInvestments: 0,
        avgEquityAllocated: 0
    });

    // Toggle system state
    const [entryType, setEntryType] = useState<'investment' | 'recognition'>('investment');
    const [feeType, setFeeType] = useState<FeeType>(FeeType.Free);

    const canEdit = (userRole === 'Startup' || userRole === 'Admin') && !isViewOnly;
    console.log('CapTableTab - userRole:', userRole, 'isViewOnly:', isViewOnly, 'canEdit:', canEdit);
    
    // Form states
    const [isEditingFundraising, setIsEditingFundraising] = useState(false);
    const [fundraising, setFundraising] = useState<FundraisingDetails>({
        active: false,
        type: InvestmentType.SeriesA,
        value: 5000000,
        equity: 15,
        validationRequested: false,
        pitchDeckUrl: '',
        pitchVideoUrl: '',
    });
    
    const [isFounderModalOpen, setIsFounderModalOpen] = useState(false);
    const [editingFounders, setEditingFounders] = useState<FounderStateItem[]>([]);
    const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
    const [investmentToDelete, setInvestmentToDelete] = useState<InvestmentRecord | null>(null);
    
    // Incubation Programs states
    const [incubationPrograms, setIncubationPrograms] = useState<IncubationProgram[]>([]);
    const [isAddProgramModalOpen, setIsAddProgramModalOpen] = useState(false);
    const [isDeleteProgramModalOpen, setIsDeleteProgramModalOpen] = useState(false);
    const [programToDelete, setProgramToDelete] = useState<IncubationProgram | null>(null);
    const [newProgram, setNewProgram] = useState<AddIncubationProgramData>({
        programName: '',
        programType: 'Acceleration',
        startDate: '',
        endDate: '',
        description: '',
        mentorName: '',
        mentorEmail: '',
        programUrl: ''
    });
    const [popularPrograms, setPopularPrograms] = useState<string[]>([]);
    const [financialRecords, setFinancialRecords] = useState<any[]>([]);
    const [totalShares, setTotalShares] = useState<number>(0);
    const [totalSharesDraft, setTotalSharesDraft] = useState<string>('0');
    const [pricePerShare, setPricePerShare] = useState<number>(0);
    // Draft states for investment auto-calculations
    const [invAmountDraft, setInvAmountDraft] = useState<string>('');
    const [invEquityDraft, setInvEquityDraft] = useState<string>('');
    const [invPostMoneyDraft, setInvPostMoneyDraft] = useState<string>('');
    const [isSavingShares, setIsSavingShares] = useState<boolean>(false);
    const [isSharesModalOpen, setIsSharesModalOpen] = useState(false);

    // Offers Received states
    const [offersReceived, setOffersReceived] = useState<OfferReceived[]>([]);
    const [isAcceptingOffer, setIsAcceptingOffer] = useState(false);

    // Load data on component mount
    useEffect(() => {
        console.log('🔄 useEffect triggered - loading data for startup:', startup?.id);
        loadCapTableData();
        loadOffersReceived();
        setupRealTimeSubscriptions();
    }, [startup.id]);

    // Auto-calc post-money when amount or equity changes
    useEffect(() => {
        const amount = Number(invAmountDraft);
        const equity = Number(invEquityDraft);
        if (Number.isFinite(amount) && amount > 0 && Number.isFinite(equity) && equity > 0) {
            const post = (amount * 100) / equity;
            setInvPostMoneyDraft(String(post));
        } else {
            setInvPostMoneyDraft('');
        }
    }, [invAmountDraft, invEquityDraft]);

    // Recompute price per share whenever shares or valuation data changes
    useEffect(() => {
        const sharesNum = Number(totalShares) || 0;
        if (sharesNum <= 0) {
            setPricePerShare(0);
            return;
        }
        // Use latest post-money valuation if available; fallback to startup.currentValuation
        let latestValuation = startup.currentValuation || 0;
        if (investmentRecords && investmentRecords.length > 0) {
            const latest = [...investmentRecords]
                .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())[0] as any;
            if (latest?.postMoneyValuation && latest.postMoneyValuation > 0) {
                latestValuation = latest.postMoneyValuation;
            }
        }
        const computed = latestValuation > 0 ? (latestValuation / sharesNum) : 0;
        setPricePerShare(computed);
    }, [totalShares, investmentRecords, startup.currentValuation]);

    // Real-time subscription for offers received
    useEffect(() => {
        if (!startup?.id) return;

        console.log('🔔 Setting up real-time subscription for startup:', startup.id);

        const channel = supabase
            .channel('offers_received_changes')
            .on('postgres_changes', { 
                event: '*', 
                schema: 'public', 
                table: 'opportunity_applications',
                filter: `startup_id=eq.${startup.id}`
            }, async (payload) => {
                console.log('🔄 Offers received change detected:', payload);
                console.log('📝 Change details:', {
                    event: payload.eventType,
                    table: payload.table,
                    record: payload.new,
                    old: payload.old
                });
                await loadOffersReceived();
            })
            .subscribe((status) => {
                console.log('📡 Real-time subscription status:', status);
            });

        return () => { 
            console.log('🔌 Unsubscribing from offers received changes');
            channel.unsubscribe(); 
        };
    }, [startup.id]);

                // Real-time subscription for recognition records changes
            useEffect(() => {
                if (!startup?.id) return;

                console.log('🔔 Setting up real-time subscription for recognition records:', startup.id);

                const channel = supabase
                    .channel('recognition_records_changes')
                    .on('postgres_changes', { 
                        event: '*', 
                        schema: 'public', 
                        table: 'recognition_records',
                        filter: `startup_id=eq.${startup.id}`
                    }, async (payload) => {
                        console.log('🔄 Recognition records change detected:', payload);
                        console.log('📝 Change details:', {
                            event: payload.eventType,
                            table: payload.table,
                            record: payload.new,
                            old: payload.old
                        });
                        // Refresh recognition records when they change
                        const recognitionData = await recognitionService.getRecognitionRecordsByStartupId(startup.id);
                        setRecognitionRecords(recognitionData);
                    })
                    .subscribe((status) => {
                        console.log('📡 Recognition records real-time subscription status:', status);
                    });

                return () => { 
                    console.log('🔌 Unsubscribing from recognition records changes');
                    channel.unsubscribe(); 
                };
            }, [startup.id]);

    const loadCapTableData = async () => {
        if (!startup?.id) return;
        
        setIsLoading(true);
        setError(null);
        
        try {
            const [
                records,
                foundersData,
                fundraisingData,
                valuationData,
                equityData,
                summaryData,
                totalSharesData,
                incubationProgramsData,
                popularProgramsData,
                financialRecordsData,
                recognitionData
            ] = await Promise.allSettled([
                            capTableService.getInvestmentRecords(startup.id),
            capTableService.getFounders(startup.id),
            capTableService.getFundraisingDetails(startup.id),
            capTableService.getValuationHistoryData(startup.id),
            capTableService.getEquityDistributionData(startup.id),
            capTableService.getInvestmentSummary(startup.id),
            capTableService.getTotalShares(startup.id),
                            incubationProgramsService.getIncubationPrograms(startup.id),
                incubationProgramsService.getPopularPrograms(),
                financialsService.getFinancialRecords(startup.id),
                recognitionService.getRecognitionRecordsByStartupId(startup.id)
            ]);

            // Handle each result individually
            setInvestmentRecords(records.status === 'fulfilled' ? records.value : []);
            setFounders(foundersData.status === 'fulfilled' ? foundersData.value : []);
            setFundraisingDetails(fundraisingData.status === 'fulfilled' ? fundraisingData.value : []);
            setValuationHistory(valuationData.status === 'fulfilled' ? valuationData.value.map(item => ({
                roundName: item.round_name,
                valuation: item.valuation,
                investmentAmount: item.investment_amount,
                date: item.date
            })) : []);
            setEquityDistribution(equityData.status === 'fulfilled' ? equityData.value.map(item => ({
                holderType: item.holder_type,
                equityPercentage: item.equity_percentage,
                totalAmount: item.total_amount
            })) : []);
            setInvestmentSummary(summaryData.status === 'fulfilled' ? {
                totalEquityFunding: summaryData.value.total_equity_funding || 0,
                totalDebtFunding: summaryData.value.total_debt_funding || 0,
                totalGrantFunding: summaryData.value.total_grant_funding || 0,
                totalInvestments: summaryData.value.total_investments || 0,
                avgEquityAllocated: summaryData.value.avg_equity_allocated || 0
            } : {
                totalEquityFunding: 0,
                totalDebtFunding: 0,
                totalGrantFunding: 0,
                totalInvestments: 0,
                avgEquityAllocated: 0
            });

            // Handle total shares
            if (totalSharesData.status === 'fulfilled') {
                const shares = Number(totalSharesData.value) || 0;
                setTotalShares(shares);
                setTotalSharesDraft(String(shares));
            } else {
                setTotalShares(0);
                setTotalSharesDraft('0');
            }

            // Set current fundraising details if available
            if (fundraisingData.status === 'fulfilled' && fundraisingData.value.length > 0) {
                setFundraising(fundraisingData.value[0]);
            }

            // Handle recognition records
            if (recognitionData.status === 'fulfilled') {
                setRecognitionRecords(recognitionData.value);
                console.log('✅ Recognition records loaded:', recognitionData.value.length);
            } else {
                console.error('Failed to load recognition records:', recognitionData.reason);
            }

            // Log any errors for debugging
            [records, foundersData, fundraisingData, valuationData, equityData, summaryData, incubationProgramsData, popularProgramsData, financialRecordsData, recognitionData].forEach((result, index) => {
                if (result.status === 'rejected') {
                    console.warn(`Failed to load data ${index}:`, result.reason);
                }
            });

            // Debug loaded data
            console.log('📊 Cap Table Data Loaded:', {
                investmentRecords: records.status === 'fulfilled' ? records.value.length : 'failed',
                founders: foundersData.status === 'fulfilled' ? foundersData.value.length : 'failed',
                fundraisingDetails: fundraisingData.status === 'fulfilled' ? fundraisingData.value.length : 'failed',
                valuationHistory: valuationData.status === 'fulfilled' ? valuationData.value.length : 'failed',
                equityDistribution: equityData.status === 'fulfilled' ? equityData.value.length : 'failed',
                investmentSummary: summaryData.status === 'fulfilled' ? summaryData.value : 'failed',
                totalShares: totalSharesData.status === 'fulfilled' ? totalSharesData.value : 'failed',
                incubationPrograms: incubationProgramsData.status === 'fulfilled' ? incubationProgramsData.value.length : 'failed',
                popularPrograms: popularProgramsData.status === 'fulfilled' ? popularProgramsData.value.length : 'failed',
                financialRecords: financialRecordsData.status === 'fulfilled' ? financialRecordsData.value.length : 'failed',
                recognitionRecords: recognitionData.status === 'fulfilled' ? recognitionData.value.length : 'failed'
            });
            
            // Debug summary data specifically
            if (summaryData.status === 'fulfilled') {
                console.log('💰 Investment Summary Raw Data:', summaryData.value);
                console.log('💰 Investment Summary Mapped Data:', {
                    totalEquityFunding: summaryData.value.total_equity_funding || 0,
                    totalDebtFunding: summaryData.value.total_debt_funding || 0,
                    totalGrantFunding: summaryData.value.total_grant_funding || 0,
                    totalInvestments: summaryData.value.total_investments || 0,
                    avgEquityAllocated: summaryData.value.avg_equity_allocated || 0
                });
            }
            
            // Debug valuation history data specifically
            if (valuationData.status === 'fulfilled') {
                console.log('📈 Valuation History Raw Data:', valuationData.value);
                console.log('📈 Valuation History Mapped Data:', valuationData.value.map(item => ({
                    roundName: item.round_name,
                    valuation: item.valuation,
                    investmentAmount: item.investment_amount,
                    date: item.date
                })));
            } else if (valuationData.status === 'rejected') {
                console.error('❌ Valuation History Failed:', valuationData.reason);
            }
            
            // Debug equity distribution data specifically
            if (equityData.status === 'fulfilled') {
                console.log('🥧 Equity Distribution Raw Data:', equityData.value);
                console.log('🥧 Equity Distribution Mapped Data:', equityData.value.map(item => ({
                    holderType: item.holder_type,
                    equityPercentage: item.equity_percentage,
                    totalAmount: item.total_amount
                })));
            } else if (equityData.status === 'rejected') {
                console.error('❌ Equity Distribution Failed:', equityData.reason);
            }

            // Process incubation programs data
            if (incubationProgramsData.status === 'fulfilled') {
                setIncubationPrograms(incubationProgramsData.value);
                console.log('🎓 Incubation Programs Data:', incubationProgramsData.value);
                console.log('🎓 Incubation Programs Count:', incubationProgramsData.value?.length || 0);
            } else if (incubationProgramsData.status === 'rejected') {
                console.error('❌ Incubation Programs Failed:', incubationProgramsData.reason);
                setIncubationPrograms([]);
            } else {
                console.log('⚠️ Incubation Programs Status: unavailable');
                setIncubationPrograms([]);
            }

            if (popularProgramsData.status === 'fulfilled') {
                setPopularPrograms(popularProgramsData.value);
                console.log('📚 Popular Programs:', popularProgramsData.value);
            }

            if (financialRecordsData.status === 'fulfilled') {
                setFinancialRecords(financialRecordsData.value);
                console.log('💰 Financial Records:', financialRecordsData.value.length, 'records loaded');
                
                // Debug: Check for pooja-related records
                const poojaRecords = financialRecordsData.value.filter(record => 
                    record.funding_source && record.funding_source.toLowerCase().includes('pooja')
                );
                if (poojaRecords.length > 0) {
                    console.log('🔍 Found Pooja Financial Records:', poojaRecords);
                } else {
                    console.log('⚠️ No Pooja financial records found');
                }
                
                // Debug: Show all funding sources
                const allFundingSources = financialRecordsData.value
                    .filter(record => record.funding_source)
                    .map(record => record.funding_source);
                console.log('📋 All Funding Sources:', allFundingSources);
            } else if (financialRecordsData.status === 'rejected') {
                console.error('❌ Financial Records Failed:', financialRecordsData.reason);
            }
        } catch (err) {
            console.error('Error loading cap table data:', err);
            setError('Failed to load cap table data');
        } finally {
            setIsLoading(false);
        }
    };

    const setupRealTimeSubscriptions = () => {
        if (!startup?.id) return;

        // Subscribe to real-time changes
        const investmentSubscription = capTableService.subscribeToInvestmentRecords(startup.id, (records) => {
            setInvestmentRecords(records);
        });

        const foundersSubscription = capTableService.subscribeToFounders(startup.id, (founders) => {
            setFounders(founders);
        });

        const fundraisingSubscription = capTableService.subscribeToFundraisingDetails(startup.id, (details) => {
            setFundraisingDetails(details);
            if (details.length > 0) {
                setFundraising(details[0]);
            }
        });

        const incubationProgramsSubscription = incubationProgramsService.subscribeToIncubationPrograms(startup.id, (programs) => {
            setIncubationPrograms(programs);
        });

        // Cleanup subscriptions on unmount
        return () => {
            investmentSubscription?.unsubscribe();
            foundersSubscription?.unsubscribe();
            fundraisingSubscription?.unsubscribe();
            incubationProgramsSubscription?.unsubscribe();
        };
    };

    const handleEditFoundersClick = () => {
        console.log('🔧 Opening founder edit modal with founders:', founders);
        setEditingFounders(founders.map(f => ({ ...f, id: Math.random() * 10000 })));
        setIsFounderModalOpen(true);
    };

    const handleFounderChange = (id: number, field: keyof Omit<FounderStateItem, 'id'>, value: string) => {
        console.log('✏️ Editing founder:', { id, field, value });
        setEditingFounders(editingFounders.map(f => f.id === id ? { ...f, [field]: value } : f));
    };

    const handleAddFounder = () => {
        setEditingFounders([...editingFounders, { id: Date.now(), name: '', email: '' }]);
    };
    
    const handleRemoveFounder = (id: number) => {
        if (editingFounders.length > 1) {
            setEditingFounders(editingFounders.filter(f => f.id !== id));
        }
    };

    const handleFounderSave = async () => {
        if (!startup?.id) return;
        
        try {
            const finalFounders = editingFounders.map(({ id, ...rest }) => rest);
            console.log('💾 Saving founders:', finalFounders);
            
            // Clear existing founders and add new ones
            await capTableService.deleteAllFounders(startup.id);
            console.log('🗑️ Deleted existing founders');
            
            for (const founder of finalFounders) {
                await capTableService.addFounder(startup.id, founder);
                console.log('➕ Added founder:', founder.name);
            }
            
            onUpdateFounders(startup.id, finalFounders);
            setIsFounderModalOpen(false);
            console.log('✅ Founders saved successfully');
        } catch (err) {
            console.error('Error saving founders:', err);
            setError('Failed to save founder information');
        }
    };

    const handleFundraisingSave = async () => {
        if (!startup?.id) return;
        
        try {
            // Validate required fields
            if (!fundraising.type) {
                setError('Fundraising type is required');
                return;
            }
            if (!fundraising.value || fundraising.value <= 0) {
                setError('Valid fundraising value is required');
                return;
            }
            if (!fundraising.equity || fundraising.equity <= 0 || fundraising.equity > 100) {
                setError('Valid equity percentage (1-100%) is required');
                return;
            }

            // Show loading state
            setIsLoading(true);
            setError(null);

            // Handle pitch deck upload if user selected a file
            const deckInput = document.getElementById('fr-deck') as HTMLInputElement | null;
            const deckFile = deckInput?.files?.[0];
            let deckUrl = fundraising.pitchDeckUrl;
            
            if (deckFile) {
                console.log('📁 Uploading pitch deck:', deckFile.name);
                deckUrl = await capTableService.uploadPitchDeck(deckFile, startup.id);
                console.log('✅ Pitch deck uploaded:', deckUrl);
            }

            const toSave = { ...fundraising, pitchDeckUrl: deckUrl };
            console.log('💾 Saving fundraising details:', toSave);

            // Upsert via update-or-insert
            const savedFundraising = await capTableService.updateFundraisingDetails(startup.id, toSave);
            console.log('✅ Fundraising details saved:', savedFundraising);

            // Update local state with saved data
            setFundraising(savedFundraising);
            setFundraisingDetails([savedFundraising]);
            
            // Handle validation request logic
            if (savedFundraising.validationRequested) {
                try {
                    console.log('🔄 Creating/updating validation request for startup:', startup.name);
                    const validationRequest = await validationService.createValidationRequest(startup.id, startup.name);
                    console.log('✅ Validation request processed:', validationRequest);
                    
                    // Show success message with validation info
                    alert(`${startup.name} fundraising is now active! A Startup Nation validation request has been submitted and is pending admin approval.`);
                } catch (validationError) {
                    console.error('❌ Error processing validation request:', validationError);
                    alert(`${startup.name} fundraising is now active! However, there was an issue submitting the validation request. Please contact support.`);
                }
            } else {
                // If validation was unchecked, remove any existing validation request
                try {
                    console.log('🔄 Removing validation request for startup:', startup.name);
                    await validationService.removeValidationRequest(startup.id);
                    console.log('✅ Validation request removed');
                } catch (validationError) {
                    console.error('❌ Error removing validation request:', validationError);
                    // Don't show error to user as this is not critical
                }
                
                // Call parent callback for non-validation fundraising
                onActivateFundraising(savedFundraising, startup);
                alert(`${startup.name} fundraising is now active!`);
            }
            
            // Exit edit mode
            setIsEditingFundraising(false);
            
            // Show success message (you can replace this with a toast notification)
            console.log('🎉 Fundraising details updated successfully!');
            
            // Reload data to ensure everything is in sync
            await loadCapTableData();
            
        } catch (err) {
            console.error('❌ Error saving fundraising details:', err);
            
            // Provide more specific error messages
            let errorMessage = 'Failed to save fundraising details. Please try again.';
            
            if (err instanceof Error) {
                if (err.message.includes('RLS')) {
                    errorMessage = 'Permission denied. Please check your authentication.';
                } else if (err.message.includes('foreign key')) {
                    errorMessage = 'Invalid startup reference. Please refresh the page.';
                } else if (err.message.includes('unique constraint')) {
                    errorMessage = 'Fundraising details already exist for this startup.';
                } else if (err.message.includes('not null')) {
                    errorMessage = 'Please fill in all required fields.';
                } else {
                    errorMessage = `Database error: ${err.message}`;
                }
            }
            
            setError(errorMessage);
        } finally {
            setIsLoading(false);
        }
    };

    const handleAddInvestment = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        if (!startup?.id) return;
        
        try {
            const formData = new FormData(e.currentTarget);
            const proofFile = (e.currentTarget.querySelector('input[name="inv-proof"]') as HTMLInputElement)?.files?.[0];
            
            // Debug form data
            console.log('Form data entries:');
            for (const [key, value] of formData.entries()) {
                console.log(`${key}: ${value}`);
            }
            
            const date = formData.get('inv-date') as string;
            const investorType = formData.get('inv-investor-type') as InvestorType;
            const investmentType = formData.get('inv-type') as InvestmentRoundType;
            const investorName = formData.get('inv-name') as string;
            const investorCode = formData.get('inv-code') as string;
            const amount = Number(invAmountDraft);
            const equityAllocated = Number(invEquityDraft);
            const postMoneyValuation = Number(invPostMoneyDraft) || ((equityAllocated && equityAllocated > 0) ? (amount * 100) / equityAllocated : 0);
            
            // Validate required fields
            if (!date) {
                setError('Date is required');
                return;
            }
            if (!investorType) {
                setError('Investor type is required');
                return;
            }
            if (!investmentType) {
                setError('Investment type is required');
                return;
            }
            if (!investorName) {
                setError('Investor name is required');
                return;
            }
            if (!amount || amount <= 0) {
                setError('Valid investment amount is required');
                return;
            }
            if (!equityAllocated || equityAllocated < 0) {
                setError('Valid equity allocation is required');
                return;
            }
            if (!postMoneyValuation || postMoneyValuation <= 0) {
                setError('Post-money valuation could not be calculated');
                return;
            }
            
            let proofUrl = '';
            if (proofFile) {
                proofUrl = await capTableService.uploadProofDocument(startup.id, proofFile);
            }
            
            const newInvestment = {
                id: Date.now().toString(), // Temporary ID for UI state
                startupId: startup.id,
                date,
                investorType,
                investmentType,
                investorName,
                investorCode,
                amount,
                equityAllocated,
                postMoneyValuation: postMoneyValuation,
                proofUrl
            };
            
            console.log('Adding investment:', newInvestment);
            console.log('Startup ID:', startup.id);
            console.log('Investment data type:', typeof newInvestment);
            console.log('Investment data keys:', Object.keys(newInvestment));
            
            // Remove startupId from the data passed to service since it's passed separately
            const { startupId, ...investmentDataForService } = newInvestment;
            console.log('Investment data for service:', investmentDataForService);

            // 1) Save the investment record
            const savedInvestment = await capTableService.addInvestmentRecord(startup.id, investmentDataForService as any);
            console.log('✅ Investment record saved successfully:', savedInvestment);

            // Reset form drafts
            setInvAmountDraft('');
            setInvEquityDraft('');
            setInvPostMoneyDraft('');

            // Note: Investor code validation can be added here in the future
            if (investorCode && investorCode.trim().length > 0) {
                console.log('Investor code provided:', investorCode);
                
                // 2) Call onInvestorAdded callback with the saved investment data
                console.log('🔄 Calling onInvestorAdded callback...');
                try {
                    onInvestorAdded(savedInvestment, startup);
                    console.log('✅ onInvestorAdded callback executed successfully');
                } catch (callbackError) {
                    console.error('❌ Error in onInvestorAdded callback:', callbackError);
                }
            } else {
                console.log('⚠️ No investor code provided, skipping onInvestorAdded callback');
            }
             
             // Safely reset the form
             if (e.currentTarget) {
                 e.currentTarget.reset();
             }
             setError(null); // Clear any previous errors
             
             // Force reload ALL data including charts
             console.log('🔄 Reloading data after adding investment...');
             await loadCapTableData();
             
             // Additional reload for chart data specifically
             try {
                 const [valuationData, equityData] = await Promise.allSettled([
                     capTableService.getValuationHistoryData(startup.id),
                     capTableService.getEquityDistributionData(startup.id)
                 ]);
                 
                 if (valuationData.status === 'fulfilled') {
                     setValuationHistory(valuationData.value.map(item => ({
                         roundName: item.round_name,
                         valuation: item.valuation,
                         investmentAmount: item.investment_amount,
                         date: item.date
                     })));
                     console.log('✅ Valuation history updated after investment');
                 }
                 
                 if (equityData.status === 'fulfilled') {
                     setEquityDistribution(equityData.value.map(item => ({
                         holderType: item.holder_type,
                         equityPercentage: item.equity_percentage,
                         totalAmount: item.total_amount
                     })));
                     console.log('✅ Equity distribution updated after investment');
                 }
             } catch (err) {
                 console.error('Error updating chart data:', err);
             }
        } catch (err) {
            console.error('Error adding investment:', err);
            setError('Failed to add investment');
        }
    };

    const handleDeleteInvestment = async (investment: InvestmentRecord) => {
        if (!startup?.id || !canEdit) return;
        
        try {
            setError(null);
            setIsLoading(true);
            
            console.log('🗑️ Deleting investment:', investment);
            console.log('💰 Amount to remove from total funding:', investment.amount);
            console.log('🏷️ Investor code to clean up:', investment.investorCode);
            
            // Delete from database (this will clean up the investment record)
            await capTableService.deleteInvestmentRecord(investment.id);
            
            // Update startup funding (reduce by the deleted investment amount)
            try {
                console.log('💰 Updating startup funding after investment deletion');
                await capTableService.updateStartupFundingAfterDeletion(startup.id, investment.amount);
            } catch (fundingError) {
                console.warn('⚠️ Warning: Could not update startup funding:', fundingError);
                // Don't fail the deletion if funding update fails
            }
            
            // Clean up startup addition requests for this investor code
            if (investment.investorCode) {
                try {
                    console.log('🧹 Cleaning up startup addition requests for investor code:', investment.investorCode);
                    await startupAdditionService.cleanupOrphanedRequests();
                } catch (cleanupError) {
                    console.warn('⚠️ Warning: Could not clean up startup addition requests:', cleanupError);
                    // Don't fail the deletion if cleanup fails
                }
            }
            
            // Remove from local state
            setInvestmentRecords(prev => prev.filter(inv => inv.id !== investment.id));
            
            // Close modal and clear selection
            setIsDeleteModalOpen(false);
            setInvestmentToDelete(null);
            
            // Reload ALL data to ensure charts and summaries are updated
            console.log('🔄 Reloading all data after investment deletion...');
            await loadCapTableData();
            
            console.log('✅ Investment and all related data deleted successfully from Supabase');
        } catch (err) {
            console.error('❌ Error deleting investment:', err);
            setError('Failed to delete investment. Please try again.');
            
            // Keep modal open on error so user can try again
            setIsLoading(false);
        } finally {
            setIsLoading(false);
        }
    };

    const handleAddRecognition = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        if (!startup?.id) return;
        
        const formData = new FormData(e.currentTarget);
        const programName = formData.get('rec-program-name') as string;
        const facilitatorName = formData.get('rec-facilitator-name') as string;
        const facilitatorCode = formData.get('rec-facilitator-code') as string;
        const incubationType = formData.get('rec-incubation-type') as IncubationType;
        const feeType = formData.get('rec-fee-type') as FeeType;
        const feeAmount = formData.get('rec-fee-amount') ? parseFloat(formData.get('rec-fee-amount') as string) : undefined;
        const equityAllocated = formData.get('rec-equity') ? parseFloat(formData.get('rec-equity') as string) : undefined;
        const preMoneyValuation = formData.get('rec-premoney') ? parseFloat(formData.get('rec-premoney') as string) : undefined;
        const agreementFile = formData.get('rec-agreement') as File;
        
        if (!programName || !facilitatorName || !facilitatorCode || !incubationType || !feeType || !agreementFile) {
            setError('Please fill in all required fields');
            return;
        }
        
        try {
            setError(null);
            setIsLoading(true);
            
            // Handle file upload for signed agreement
            let signedAgreementUrl = '';
            if (agreementFile && agreementFile.size > 0) {
                try {
                    const uploadResult = await storageService.uploadFile(agreementFile, 'startup-documents', `agreements/${startup.id}/signed_agreement_${Date.now()}_${agreementFile.name}`);
                    if (uploadResult.success && uploadResult.url) {
                        signedAgreementUrl = uploadResult.url;
                    } else {
                        throw new Error(uploadResult.error || 'Upload failed');
                    }
                } catch (uploadErr) {
                    console.error('Failed to upload agreement file:', uploadErr);
                    setError('Failed to upload agreement file');
                    return;
                }
            }
            
            // Debug: Log the data being sent
            console.log('🔍 Debug - Data being sent to createRecognitionRecord:', {
                startupId: startup.id,
                programName,
                facilitatorName,
                facilitatorCode,
                incubationType,
                feeType,
                feeAmount,
                equityAllocated,
                preMoneyValuation,
                signedAgreementUrl
            });
            
            // Create recognition record using the service
            const newRecognitionRecord = await recognitionService.createRecognitionRecord({
                startupId: startup.id,
                programName,
                facilitatorName,
                facilitatorCode,
                incubationType,
                feeType,
                feeAmount,
                equityAllocated,
                preMoneyValuation,
                signedAgreementUrl
            });
            
            // Add to local state
            setRecognitionRecords(prev => [newRecognitionRecord, ...prev]);
            
            // Reset form
            if (e.currentTarget) {
                e.currentTarget.reset();
            }
            setError(null);
            setFeeType(FeeType.Free);
            
            console.log('✅ Recognition record added successfully to backend');
            console.log('📋 New record:', newRecognitionRecord);
        } catch (err) {
            console.error('❌ Error adding recognition record:', err);
            if (err instanceof Error) {
                setError(err.message);
            } else {
                setError('Failed to add recognition record');
            }
        } finally {
            setIsLoading(false);
        }
    };

    const handleEntrySubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        if (entryType === 'investment') {
            await handleAddInvestment(e);
        } else {
            await handleAddRecognition(e);
        }
    };

    const openDeleteModal = (investment: InvestmentRecord) => {
        console.log('🗑️ Opening delete modal for investment:', investment);
        setInvestmentToDelete(investment);
        setIsDeleteModalOpen(true);
    };

    const handleEditInvestment = (investment: InvestmentRecord) => {
        console.log('🔧 Editing investment:', investment);
        // TODO: Implement edit modal functionality
        alert('Edit functionality will be implemented in the next update');
    };

    const handleDownloadProof = async (proofUrl: string, investorName: string) => {
        try {
            const downloadUrl = await capTableService.getAttachmentDownloadUrl(proofUrl);
            const link = document.createElement('a');
            link.href = downloadUrl;
            link.download = `investment-proof-${investorName}.pdf`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        } catch (err) {
            console.error('Error downloading proof:', err);
            setError('Failed to download proof document');
        }
    };

    // =====================================================
    // INCUBATION PROGRAMS HANDLERS
    // =====================================================

    const handleAddProgram = async () => {
        if (!startup?.id) return;
        
        try {
            await incubationProgramsService.addIncubationProgram(startup.id, newProgram);
            setIsAddProgramModalOpen(false);
            setNewProgram({
                programName: '',
                programType: 'Acceleration',
                startDate: '',
                endDate: '',
                description: '',
                mentorName: '',
                mentorEmail: '',
                programUrl: ''
            });
            await loadCapTableData();
        } catch (err) {
            console.error('Error adding program:', err);
            setError('Failed to add program');
        }
    };

    const handleDeleteProgram = async (programId: string) => {
        if (!startup?.id) return;
        
        try {
            await incubationProgramsService.deleteIncubationProgram(programId);
            setIsDeleteProgramModalOpen(false);
            setProgramToDelete(null);
            await loadCapTableData();
        } catch (err) {
            console.error('Error deleting program:', err);
            setError('Failed to delete program');
        }
    };

    const openDeleteProgramModal = (program: IncubationProgram) => {
        setProgramToDelete(program);
        setIsDeleteProgramModalOpen(true);
    };

    const handleProgramNameChange = (programName: string) => {
        setNewProgram({ ...newProgram, programName });
    };

    const handleProgramTypeChange = (programType: 'Incubation' | 'Acceleration' | 'Mentorship' | 'Bootcamp') => {
        setNewProgram({ ...newProgram, programType });
    };

    // =====================================================
    // UTILIZATION CALCULATION
    // =====================================================

    const calculateInvestorUtilization = (investorName: string, investmentAmount: number): { utilized: number; percentage: number } => {
        // Get all expenses that use this investor's funding source
        const investorFundingSource = `${investorName} (Equity)`;
        
        // Debug logging for pooja specifically
        if (investorName.toLowerCase().includes('pooja')) {
            console.log('🔍 Debugging Pooja Utilization:', {
                investorName,
                investmentAmount,
                expectedFundingSource: investorFundingSource,
                totalFinancialRecords: financialRecords.length,
                matchingRecords: financialRecords.filter(record => 
                    record.record_type === 'expense' && 
                    record.funding_source && 
                    record.funding_source.toLowerCase() === investorFundingSource.toLowerCase()
                ),
                allFundingSources: financialRecords
                    .filter(record => record.funding_source)
                    .map(record => record.funding_source)
            });
        }
        
        // Calculate total utilized amount from financial records
        // Use case-insensitive matching to handle potential case issues
        const utilizedAmount = financialRecords
            .filter(record => 
                record.record_type === 'expense' && 
                record.funding_source && 
                record.funding_source.toLowerCase() === investorFundingSource.toLowerCase()
            )
            .reduce((total, record) => total + (record.amount || 0), 0);
        
        const percentage = investmentAmount > 0 ? (utilizedAmount / investmentAmount) * 100 : 0;
        
        return {
            utilized: utilizedAmount,
            percentage: Math.min(percentage, 100)
        };
    };

    // Progress bar component for utilization display
    const UtilizationProgressBar = ({ utilized, total, percentage }: { utilized: number; total: number; percentage: number }) => {
        // Show minimum 1% progress if there's any utilization, even if percentage is very small
        const displayPercentage = utilized > 0 ? Math.max(percentage, 1) : 0;
        
        return (
            <div className="space-y-1">
                <div className="w-full bg-slate-200 rounded-full h-2">
                    <div 
                        className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                        style={{ width: `${displayPercentage}%` }}
                    />
                </div>
                <div className="text-xs text-slate-600">
                    {formatCurrency(utilized)} Utilized ({percentage.toFixed(4)}%)
                </div>
            </div>
        );
    };

         // Prepare chart data directly from investment records (not fundraising data)
     const valuationData = investmentRecords.length > 0 ? 
         investmentRecords.map(inv => ({
             name: inv.investmentType || 'Investment Round',
             valuation: Number(inv.preMoneyValuation) || 0,
             investment: Number(inv.amount) || 0
         })).filter(item => item.valuation > 0 || item.investment > 0) : [];

     // Calculate equity distribution from investment records and founders
     const equityData = (() => {
         const distribution: { name: string; value: number }[] = [];
         
         // Add founders equity
         if (founders.length > 0) {
             const totalInvestorEquity = investmentRecords.reduce((sum, inv) => sum + (inv.equityAllocated || 0), 0);
             const founderEquity = Math.max(0, 100 - totalInvestorEquity);
             const equityPerFounder = founderEquity / founders.length;
             
             founders.forEach(founder => {
                 distribution.push({
                     name: `Founder (${founder.name})`,
                     value: equityPerFounder
                 });
             });
         }
         
         // Add investor equity
         investmentRecords.forEach(inv => {
             if (inv.equityAllocated && inv.equityAllocated > 0) {
                 distribution.push({
                     name: `Investor (${inv.investorName})`,
                     value: inv.equityAllocated
                 });
             }
         });
         
         return distribution.filter(item => item.value > 0);
     })();

    // Debug chart data
    console.log('📈 Chart Data:', {
        valuationData: valuationData.length > 0 ? valuationData : 'No valuation data',
        equityData: equityData.length > 0 ? equityData : 'No equity data'
    });
    
    // Debug valuation history specifically
    console.log('📊 Valuation History State:', {
        rawValuationHistory: valuationHistory,
        processedValuationData: valuationData,
        hasData: valuationData.length > 0,
        valuationHistoryLength: valuationHistory.length,
        valuationDataLength: valuationData.length
    });
    
    // Debug equity distribution specifically
    console.log('📊 Equity Distribution State:', {
        rawEquityDistribution: equityDistribution,
        processedEquityData: equityData,
        hasData: equityData.length > 0,
        equityDistributionLength: equityDistribution.length,
        equityDataLength: equityData.length
    });
    
    // Additional debugging for chart rendering
    console.log('🎯 Chart Rendering Debug:', {
        willShowValuationChart: valuationData.length > 0,
        willShowEquityChart: equityData.length > 0,
        valuationDataSample: valuationData.slice(0, 2),
        equityDataSample: equityData.slice(0, 2),
        valuationDataFull: valuationData,
        equityDataFull: equityData
    });
    
    // Debug the actual chart rendering conditions
    console.log('📊 Chart Display Conditions:', {
        valuationDataLength: valuationData.length,
        equityDataLength: equityData.length,
        valuationHistoryLength: valuationHistory.length,
        equityDistributionLength: equityDistribution.length,
        shouldShowValuationChart: valuationData.length > 0,
        shouldShowEquityChart: equityData.length > 0
    });
    
    // Debug exact data values
    console.log('🔍 Exact Chart Data Values:', {
        valuationDataValues: valuationData.map(item => ({
            name: item.name,
            valuation: item.valuation,
            investment: item.investment,
            valuationType: typeof item.valuation,
            investmentType: typeof item.investment
        })),
        equityDataValues: equityData.map(item => ({
            name: item.name,
            value: item.value,
            valueType: typeof item.value
        }))
    });
    
         // Debug the actual raw data that's being processed
     console.log('🔍 Raw Data Being Processed:', {
         valuationHistoryRaw: valuationHistory,
         equityDistributionRaw: equityDistribution,
         valuationHistoryFirstItem: valuationHistory[0],
         equityDistributionFirstItem: equityDistribution[0]
     });
     
     // Debug chart rendering conditions
     console.log('🎨 Chart Rendering Status:', {
         valuationDataLength: valuationData.length,
         equityDataLength: equityData.length,
         valuationDataFirstItem: valuationData[0],
         equityDataFirstItem: equityData[0],
         willRenderValuationChart: valuationData.length > 0,
         willRenderEquityChart: equityData.length > 0
     });

    // =====================================================
    // OFFERS RECEIVED HANDLERS
    // =====================================================

    const loadOffersReceived = async () => {
        console.log('🚀 loadOffersReceived function called!');
        if (!startup?.id) return;
        
        try {
            console.log('🔍 Loading offers for startup ID:', startup.id);
            console.log('🔍 Startup object:', startup);
            console.log('🔍 User role:', userRole);
            console.log('🔍 Is view only:', isViewOnly);
            
            // Fetch applications for this startup with all necessary data
            const { data: applications, error } = await supabase
                .from('opportunity_applications')
                .select(`
                    id,
                    startup_id,
                    opportunity_id,
                    status,
                    diligence_status,
                    agreement_url,
                    created_at,
                    incubation_opportunities(
                        id,
                        program_name,
                        facilitator_id,
                        facilitator_code
                    )
                `)
                .eq('startup_id', startup.id)
                .order('created_at', { ascending: false });

            if (error) {
                console.error('Error fetching applications:', error);
                throw error;
            }

            console.log('📋 Raw applications data:', applications);
            console.log('📋 Applications count:', applications?.length || 0);
            console.log('📋 Startup ID being queried:', startup.id);
            
            // Debug: Check the relationship data
            if (applications && applications.length > 0) {
                applications.forEach((app, index) => {
                    console.log(`🔍 App ${index}:`, {
                        id: app.id,
                        startup_id: app.startup_id,
                        opportunity_id: app.opportunity_id,
                        status: app.status,
                        diligence_status: app.diligence_status,
                        incubation_opportunities: app.incubation_opportunities
                    });
                });
            }

            // Get facilitator names for the opportunities
            const facilitatorIds = [...new Set(applications?.map(app => {
                const opportunities = app.incubation_opportunities as any;
                if (Array.isArray(opportunities) && opportunities.length > 0) {
                    return opportunities[0]?.facilitator_id;
                }
                // Handle case where opportunities might be a single object
                return opportunities?.facilitator_id;
            }).filter(Boolean) || [])];
            
            let facilitatorNames: { [key: string]: string } = {};
            if (facilitatorIds.length > 0) {
                const { data: facilitators, error: facilitatorError } = await supabase
                    .from('users')
                    .select('id, name')
                    .in('id', facilitatorIds);
                
                if (facilitatorError) {
                    console.error('Error fetching facilitators:', facilitatorError);
                } else {
                    facilitatorNames = (facilitators || []).reduce((acc, fac) => {
                        acc[fac.id] = fac.name;
                        return acc;
                    }, {} as { [key: string]: string });
                }
            }

            console.log('👥 Facilitator names:', facilitatorNames);

            // Debug: Check the filtering logic
            console.log('🔍 Applications before filtering:', applications);
            console.log('🔍 Applications with status "accepted":', applications?.filter(app => app.status === 'accepted'));
            console.log('🔍 Applications with diligence_status "requested":', applications?.filter(app => app.diligence_status === 'requested'));
            console.log('🔍 Applications that will pass filter:', applications?.filter(app => app.status === 'accepted' || app.diligence_status === 'requested'));

            // Transform applications into offers - Show both accepted applications and pending diligence requests
            const offers: OfferReceived[] = (applications || [])
                .filter((app: any) => {
                    const passesFilter = app.status === 'accepted' || app.diligence_status === 'requested';
                    console.log(`🔍 App ${app.id}: status=${app.status}, diligence_status=${app.diligence_status}, passesFilter=${passesFilter}`);
                    return passesFilter;
                })
                .map((app: any) => {
                    console.log(`📝 Processing app ${app.id}:`, app);
                    const isAccepted = app.status === 'accepted';
                    const hasDiligenceRequest = app.diligence_status === 'requested';
                    const hasDiligenceApproved = app.diligence_status === 'approved';
                    const facilitatorName = (() => {
                        const opportunities = app.incubation_opportunities as any;
                        if (Array.isArray(opportunities) && opportunities.length > 0) {
                            return facilitatorNames[opportunities[0]?.facilitator_id] || 'Program Facilitator';
                        }
                        return facilitatorNames[opportunities?.facilitator_id] || 'Program Facilitator';
                    })();
                    
                    let type: 'Incubation' | 'Due Diligence';
                    let offerDetails: string;
                    let status: 'pending' | 'accepted' | 'rejected';
                    
                    if (hasDiligenceRequest && !hasDiligenceApproved) {
                        // Pending diligence request - startup can accept
                        type = 'Due Diligence';
                        offerDetails = `Request for Compliance access until ${new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]}`;
                        status = 'pending';
                    } else if (hasDiligenceApproved) {
                        // Diligence approved - show as accepted with download option
                        type = 'Due Diligence';
                        offerDetails = 'Compliance access granted';
                        status = 'accepted';
                    } else if (isAccepted && !hasDiligenceRequest) {
                        // Regular incubation acceptance (no diligence requested)
                        type = 'Incubation';
                        offerDetails = 'Accepted into Program';
                        status = 'accepted';
                    } else if (isAccepted && hasDiligenceRequest) {
                        // Incubation accepted but diligence not yet requested
                        type = 'Incubation';
                        offerDetails = 'Accepted into Program - Diligence may be requested later';
                        status = 'accepted';
                    } else {
                        // Fallback
                        type = 'Incubation';
                        offerDetails = 'Application Submitted';
                        status = 'pending';
                    }

                    const offer: OfferReceived = {
                        id: app.id,
                        from: facilitatorName,
                        type,
                        offerDetails,
                        status,
                        code: (() => {
                            const opportunities = app.incubation_opportunities as any;
                            if (Array.isArray(opportunities) && opportunities.length > 0) {
                                return opportunities[0]?.facilitator_code || 'FAC-XXXXXX';
                            }
                            return opportunities?.facilitator_code || 'FAC-XXXXXX';
                        })(),
                        agreementUrl: app.agreement_url,
                        applicationId: app.id,
                        createdAt: app.created_at
                    };

                    console.log('📝 Created offer:', offer);
                    return offer;
                });

            console.log('🎯 Final offers array:', offers);
            console.log('🎯 Final offers count:', offers.length);
            console.log('🎯 Setting offersReceived state to:', offers);
            setOffersReceived(offers);
            console.log('🎯 State set complete');
        } catch (err) {
            console.error('Error loading offers received:', err);
            setOffersReceived([]);
        }
    };

    const handleAcceptDiligenceRequest = async (offer: OfferReceived) => {
        if (!startup?.id) return;
        
        // Prevent multiple acceptances - check both local state and database
        if (offer.status === 'accepted' || isAcceptingOffer) {
            console.log('⚠️ Offer already accepted or processing, preventing duplicate acceptance');
            return;
        }
        
        setIsAcceptingOffer(true);
        try {
            console.log('🔄 Accepting diligence request for offer:', offer.id);
            console.log('📋 Offer details:', {
                id: offer.id,
                applicationId: offer.applicationId,
                type: offer.type,
                status: offer.status,
                from: offer.from
            });
            
            // First, check the current status in the database to prevent race conditions
            const { data: currentApp, error: checkError } = await supabase
                .from('opportunity_applications')
                .select('diligence_status')
                .eq('id', offer.applicationId)
                .single();
            
            if (checkError) {
                console.error('Error checking current status:', checkError);
                throw checkError;
            }
            
            // If already approved, don't proceed
            if (currentApp.diligence_status === 'approved') {
                console.log('⚠️ Diligence already approved in database');
                await loadOffersReceived(); // Refresh to get latest state
                return;
            }
            
            // Show confirmation dialog
            const confirmed = window.confirm(
                'By accepting this due diligence request, you are granting the facilitator view-only access to your compliance tab. Do you want to continue?'
            );
            
            if (!confirmed) {
                setIsAcceptingOffer(false);
                return;
            }

            // Use RPC to approve diligence as per previous working logic
            let updateResult = null;
            try {
                const { data, error: rpcError } = await supabase.rpc('safe_update_diligence_status', {
                    p_application_id: offer.applicationId,
                    p_new_status: 'approved',
                    p_old_status: 'requested'
                });
                if (rpcError) {
                    console.error('RPC function error:', rpcError);
                    throw rpcError;
                }
                updateResult = data;
            } catch (rpcError) {
                console.error('RPC function failed:', rpcError);
                throw rpcError;
            }

            if (!updateResult) {
                console.log('⚠️ Diligence was already approved or status changed');
                await loadOffersReceived();
                return;
            }

            // Fetch latest agreement url from application
            const { data: appAfter, error: appFetchError } = await supabase
                .from('opportunity_applications')
                .select('agreement_url')
                .eq('id', offer.applicationId)
                .single();
            if (appFetchError) {
                console.warn('Could not fetch updated agreement URL:', appFetchError);
            }

            console.log('✅ Diligence request approved in database');
            console.log('🔄 Updating local state for offer:', offer.id);

            // Update local state immediately to prevent multiple clicks
            setOffersReceived(prev => {
                const updated = prev.map(o => 
                    o.id === offer.id 
                        ? { 
                            ...o, 
                            status: 'accepted' as const,
                            type: 'Due Diligence' as const,
                            offerDetails: 'Compliance access granted',
                            agreementUrl: appAfter?.agreement_url || o.agreementUrl
                          }
                        : o
                );
                console.log('🔄 Local state updated:', updated);
                return updated;
            });

            // Reload offers to ensure persistence and get updated data
            await loadOffersReceived();

            // Show success message
            const successMessage = document.createElement('div');
            successMessage.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
            successMessage.innerHTML = `
                <div class="bg-white rounded-lg p-6 max-w-sm mx-4 text-center">
                    <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                        </svg>
                    </div>
                    <h3 class="text-lg font-semibold text-gray-900 mb-2">Due Diligence Accepted!</h3>
                    <p class="text-gray-600 mb-4">The facilitator now has view-only access to your compliance tab.</p>
                    <button onclick="this.parentElement.parentElement.remove()" class="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 transition-colors">
                        Continue
                    </button>
                </div>
            `;
            document.body.appendChild(successMessage);
        } catch (err) {
            console.error('Error accepting diligence request:', err);
            
            // More detailed error message
            let errorMessage = 'Failed to accept diligence request. Please try again.';
            if (err && typeof err === 'object' && 'message' in err) {
                errorMessage = `Error: ${err.message}`;
            }
            
            alert(errorMessage);
        } finally {
            setIsAcceptingOffer(false);
        }
    };

    const handleDownloadAgreement = async (agreementUrl: string) => {
        try {
            console.log('📥 Downloading agreement from:', agreementUrl);
            
            // Create a temporary link element
            const link = document.createElement('a');
            link.href = agreementUrl;
            link.download = `facilitation-agreement-${Date.now()}.pdf`;
            link.target = '_blank';
            link.rel = 'noopener noreferrer';
            
            // Add to DOM, click, and remove
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            console.log('✅ Agreement download initiated');
        } catch (err) {
            console.error('Error downloading agreement:', err);
            alert('Failed to download agreement. Please try again.');
        }
    };

    if (isLoading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
                    <p className="text-slate-600">Loading cap table data...</p>
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="text-center py-8">
                <p className="text-red-600 mb-4">{error}</p>
                <Button onClick={loadCapTableData}>Retry</Button>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                                 <Card>
                     <p className="text-sm font-medium text-slate-500">Current Valuation</p>
                     <p className="text-2xl font-bold">
                        {(() => {
                            if (investmentRecords.length > 0) {
                                const latest = [...investmentRecords]
                                    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())[0];
                                const latestPost = (latest as any)?.postMoneyValuation;
                                if (latestPost && latestPost > 0) return formatCurrency(latestPost);
                            }
                            return formatCurrency(startup.currentValuation);
                        })()}
                    </p>
                </Card>
                                <Card>
                    <p className="text-sm font-medium text-slate-500">Total Shares</p>
                    <div className="flex items-center gap-3">
                        <Input 
                            name="total-shares"
                            id="total-shares"
                            type="number"
                            value={totalSharesDraft}
                            onChange={(e) => setTotalSharesDraft(e.target.value)}
                            onBlur={async () => {
                                const parsed = Number(totalSharesDraft);
                                if (!Number.isFinite(parsed) || parsed < 0) {
                                    setTotalSharesDraft(String(totalShares));
                                    return;
                                }
                                if (parsed === totalShares) return;
                                try {
                                    setIsSavingShares(true);
                                    // compute price per share from current valuation if available
                                    // Price per share uses latest post-money valuation if present
                                    let latestValuation = startup.currentValuation || 0;
                                    if (investmentRecords && investmentRecords.length > 0) {
                                        const latest = [...investmentRecords]
                                            .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())[0] as any;
                                        if (latest?.postMoneyValuation && latest.postMoneyValuation > 0) {
                                            latestValuation = latest.postMoneyValuation;
                                        }
                                    }
                                    const computedPricePerShare = parsed > 0 ? latestValuation / parsed : 0;
                                    const saved = await capTableService.upsertTotalShares(startup.id, parsed, computedPricePerShare);
                                    setTotalShares(saved);
                                    setPricePerShare(computedPricePerShare);
                                } catch (err) {
                                    console.error('Failed to save total shares', err);
                                    setTotalSharesDraft(String(totalShares));
                                } finally {
                                    setIsSavingShares(false);
                                }
                            }}
                        />
                        {isSavingShares && <Loader2 className="h-5 w-5 animate-spin text-slate-400" />}
                        <Button size="sm" variant="outline" onClick={() => setIsSharesModalOpen(true)}>Edit</Button>
                    </div>
                    <p className="text-sm text-slate-500 mt-1">
                        {pricePerShare > 0 ? `(Price/Share: ${formatCurrency(pricePerShare)})` : '(Price/Share: —)'}
                     </p>
                 </Card>
                                 <Card>
                     <p className="text-sm font-medium text-slate-500">Total Funding</p>
                     <p className="text-2xl font-bold">
                        {(() => {
                            const totalEquity = investmentRecords.filter(inv => inv.investmentType === InvestmentRoundType.Equity).reduce((sum, inv) => sum + (inv.amount || 0), 0);
                            const totalDebt = investmentRecords.filter(inv => inv.investmentType === InvestmentRoundType. Debt).reduce((sum, inv) => sum + (inv.amount || 0), 0);
                            const totalGrant = investmentRecords.filter(inv => inv.investmentType === InvestmentRoundType.Grant).reduce((sum, inv) => sum + (inv.amount || 0), 0);
                            return formatCurrency(totalEquity + totalDebt + totalGrant);
                        })()}
                     </p>
                 </Card>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                                 <Card>
                     <p className="text-sm font-medium text-slate-500">Total Investments</p>
                     <p className="text-xl font-bold">{investmentRecords.length}</p>
                 </Card>
                 <Card>
                     <p className="text-sm font-medium text-slate-500">Total Equity Funding</p>
                    <p className="text-xl font-bold">{formatCurrencyCompact(investmentRecords.filter(inv => inv.investmentType === InvestmentRoundType.Equity).reduce((sum, inv) => sum + (inv.amount || 0), 0))}</p>
                 </Card>
                 <Card>
                    <p className="text-sm font-medium text-slate-500">Total Debt Funding</p>
                    <p className="text-xl font-bold">{formatCurrencyCompact(investmentRecords.filter(inv => inv.investmentType === InvestmentRoundType.Debt).reduce((sum, inv) => sum + (inv.amount || 0), 0))}</p>
                 </Card>
                 <Card>
                    <p className="text-sm font-medium text-slate-500">Total Grant Funding</p>
                    <p className="text-xl font-bold">{formatCurrencyCompact(investmentRecords.filter(inv => inv.investmentType === InvestmentRoundType.Grant).reduce((sum, inv) => sum + (inv.amount || 0), 0))}</p>
                 </Card>
            </div>

            

            {/* Charts & Founder Info */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-2 space-y-6">
                                         <Card>
                         <div className="flex justify-between items-center mb-4">
                             <h3 className="text-lg font-semibold text-slate-700">Valuation History</h3>
                             <Button 
                                 variant="outline" 
                                 size="sm" 
                                 onClick={async () => {
                                     console.log('🔄 Manual refresh of investment data...');
                                     try {
                                         const records = await capTableService.getInvestmentRecords(startup.id);
                                         setInvestmentRecords(records);
                                         console.log('✅ Investment records manually refreshed');
                                     } catch (err) {
                                         console.error('Error refreshing investment records:', err);
                                     }
                                 }}
                                 title="Refresh chart data"
                             >
                                 <TrendingUp className="h-4 w-4" />
                             </Button>
                         </div>
                         {valuationData.length > 0 ? (
                             <div style={{ width: '100%', height: 300 }}>
                                 <ResponsiveContainer width="100%" height="100%">
                                     <BarChart data={valuationData}>
                                         <CartesianGrid strokeDasharray="3 3" />
                                         <XAxis dataKey="name" fontSize={12} />
                                         <YAxis yAxisId="left" orientation="left" stroke="#16a34a" fontSize={12} tickFormatter={(val) => formatCurrencyCompact(val)}/>
                                         <YAxis yAxisId="right" orientation="right" stroke="#3b82f6" fontSize={12} tickFormatter={(val) => formatCurrencyCompact(val)}/>
                                         <Tooltip formatter={(value: number) => formatCurrency(value)} />
                                         <Legend />
                                         <Bar yAxisId="left" dataKey="valuation" fill="#16a34a" name="Valuation" />
                                         <Bar yAxisId="right" dataKey="investment" fill="#3b82f6" name="Investment" />
                                     </BarChart>
                                 </ResponsiveContainer>
                             </div>
                         ) : (
                            <div className="flex items-center justify-center h-64 text-center">
                                <div>
                                    <TrendingUp className="h-12 w-12 text-slate-300 mx-auto mb-4" />
                                    <p className="text-slate-500 mb-2">No valuation history available</p>
                                    <p className="text-sm text-slate-400">Add investment records to see valuation trends</p>
                                </div>
                            </div>
                        )}
                    </Card>
                                         <Card>
                         <div className="flex justify-between items-center mb-4">
                             <h3 className="text-lg font-semibold text-slate-700">Equity Holdings</h3>
                             <Button 
                                 variant="outline" 
                                 size="sm" 
                                 onClick={async () => {
                                     console.log('🔄 Manual refresh of investment and founder data...');
                                     try {
                                         const [records, foundersData] = await Promise.all([
                                             capTableService.getInvestmentRecords(startup.id),
                                             capTableService.getFounders(startup.id)
                                         ]);
                                         setInvestmentRecords(records);
                                         setFounders(foundersData);
                                         console.log('✅ Investment and founder data manually refreshed');
                                     } catch (err) {
                                         console.error('Error refreshing investment and founder data:', err);
                                     }
                                 }}
                                 title="Refresh chart data"
                             >
                                 <PieChartIcon className="h-4 w-4" />
                             </Button>
                         </div>
                         {equityData.length > 0 ? (
                             <div style={{ width: '100%', height: 300 }}>
                                 <ResponsiveContainer width="100%" height="100%">
                                     <PieChart>
                                         <Pie data={equityData} cx="50%" cy="50%" labelLine={false} outerRadius={110} fill="#8884d8" dataKey="value" nameKey="name" label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}>
                                             {equityData.map((entry, index) => <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />)}
                                         </Pie>
                                         <Tooltip formatter={(value: number) => `${value}%`} />
                                         <Legend />
                                     </PieChart>
                                 </ResponsiveContainer>
                             </div>
                         ) : (
                            <div className="flex items-center justify-center h-64 text-center">
                                <div>
                                    <PieChartIcon className="h-12 w-12 text-slate-300 mx-auto mb-4" />
                                    <p className="text-slate-500 mb-2">No equity distribution available</p>
                                    <p className="text-sm text-slate-400">Add founders and investments to see equity breakdown</p>
                                </div>
                            </div>
                        )}
                    </Card>
                </div>
                <div className="space-y-6">
                    <Card>
                        <div className="flex justify-between items-center mb-4">
                            <h3 className="text-lg font-semibold text-slate-700">Founder Information</h3>
                            <Button variant="outline" size="sm" onClick={handleEditFoundersClick} disabled={!canEdit}>
                                <Edit3 className="h-4 w-4 mr-2" />Edit
                            </Button>
                        </div>
                        <div className="space-y-4">
                            {founders && founders.length > 0 ? (
                                founders.map((founder, index) => (
                                    <div key={index}>
                                        <p className="font-semibold">{founder.name}</p>
                                        <p className="text-sm text-slate-500">{founder.email}</p>
                                    </div>
                                ))
                            ) : (
                                <p className="text-sm text-slate-500">No founder information available.</p>
                            )}
                        </div>
                    </Card>
                                         <Card>
                         <div className="flex justify-between items-center mb-4">
                             <div className="flex items-center gap-2">
                                 <h3 className="text-lg font-semibold text-slate-700">Fundraising</h3>
                                 {fundraising.active && (
                                     <span className="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full">
                                         Active
                                     </span>
                                 )}
                             </div>
                             {!isEditingFundraising ? (
                                 <Button variant="outline" size="sm" onClick={() => setIsEditingFundraising(true)} disabled={!canEdit}>
                                     <Edit3 className="h-4 w-4 mr-2" />Edit
                                 </Button>
                             ) : (
                                 <div className="flex gap-2">
                                     <Button variant="secondary" size="sm" onClick={() => setIsEditingFundraising(false)}>
                                         <X className="h-4 w-4"/>
                                     </Button>
                                     <Button size="sm" onClick={handleFundraisingSave} disabled={isLoading}>
                                         {isLoading ? (
                                             <>
                                                 <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                                                 Saving...
                                             </>
                                         ) : (
                                             <>
                                                 <Save className="h-4 w-4 mr-2"/>Save
                                             </>
                                         )}
                                     </Button>
                                 </div>
                             )}
                         </div>
                                                 {!isEditingFundraising ? (
                             // Display mode - show current fundraising details
                             <div className="space-y-4">
                                 {fundraisingDetails.length > 0 ? (
                                     <>
                                         <div className="grid grid-cols-2 gap-4 text-sm">
                                             <div>
                                                 <p className="font-medium text-slate-700">Round Type</p>
                                                 <p className="text-slate-600">{fundraising.type}</p>
                                             </div>
                                             <div>
                                                 <p className="font-medium text-slate-700">Target Value</p>
                                                 <p className="text-slate-600">{formatCurrency(fundraising.value)}</p>
                                             </div>
                                             <div>
                                                 <p className="font-medium text-slate-700">Equity Offered</p>
                                                 <p className="text-slate-600">{fundraising.equity}%</p>
                                             </div>
                                             <div>
                                                 <p className="font-medium text-slate-700">Status</p>
                                                 <p className="text-slate-600">
                                                     {fundraising.active ? 'Active' : 'Inactive'}
                                                 </p>
                                             </div>
                                         </div>
                                         
                                         {fundraising.pitchDeckUrl && (
                                             <div>
                                                 <p className="font-medium text-slate-700 mb-2">Pitch Deck</p>
                                                 <Button 
                                                     size="sm" 
                                                     variant="outline" 
                                                     onClick={() => window.open(fundraising.pitchDeckUrl, '_blank')}
                                                 >
                                                     <Download className="h-4 w-4 mr-2" />
                                                     View Pitch Deck
                                                 </Button>
                                             </div>
                                         )}
                                         
                                         {fundraising.pitchVideoUrl && (
                                             <div>
                                                 <p className="font-medium text-slate-700 mb-2">Pitch Video</p>
                                                 <Button 
                                                     size="sm" 
                                                     variant="outline" 
                                                     onClick={() => window.open(fundraising.pitchVideoUrl, '_blank')}
                                                 >
                                                     <Download className="h-4 w-4 mr-2" />
                                                     Watch Video
                                                 </Button>
                                             </div>
                                         )}
                                         
                                         {fundraising.validationRequested && (
                                             <div className="p-3 bg-blue-50 border-l-4 border-brand-accent text-sm text-slate-600">
                                                 <p className="font-medium">Startup Nation Validation Requested</p>
                                                 <p>3% of fund raised or 4% of total equity raised as fees for validation, documentation and connection.</p>
                                             </div>
                                         )}
                                     </>
                                 ) : (
                                     <div className="text-center py-6">
                                         <p className="text-slate-500 mb-2">No fundraising details configured</p>
                                         <p className="text-sm text-slate-400">Click Edit to set up your fundraising round</p>
                                     </div>
                                 )}
                             </div>
                         ) : (
                             // Edit mode - show form
                             <fieldset disabled={!isEditingFundraising}>
                                 <div className="space-y-4">
                                     <div className="flex items-center">
                                         <input 
                                             type="checkbox" 
                                             id="fundraising-active" 
                                             className="h-4 w-4 rounded border-gray-300 text-brand-primary focus:ring-brand-primary" 
                                             checked={fundraising.active} 
                                             onChange={(e) => setFundraising({...fundraising, active: e.target.checked})} 
                                         />
                                         <label htmlFor="fundraising-active" className="ml-2 block text-sm text-gray-900">Activate Fundraising Round</label>
                                     </div>
                                                         <Select label="Type" id="fr-type" value={fundraising.type} onChange={e => setFundraising({...fundraising, type: e.target.value as InvestmentType})}>
                        {Object.values(InvestmentType).map(t => <option key={t} value={t}>{t}</option>)}
                    </Select>
                                     <Input label="Value" id="fr-value" type="number" value={fundraising.value} onChange={e => setFundraising({...fundraising, value: Number(e.target.value)})} />
                                     <Input label="Equity" id="fr-equity" type="number" value={fundraising.equity} onChange={e => setFundraising({...fundraising, equity: Number(e.target.value)})} />
                                     <Input label="Pitch Deck" id="fr-deck" type="file" />
                                     <Input 
                                         label="Pitch Video (YouTube Link)" 
                                         id="fr-video" 
                                         type="url" 
                                         placeholder="https://www.youtube.com/watch?v=..."
                                         value={fundraising.pitchVideoUrl || ''}
                                         onChange={e => setFundraising({...fundraising, pitchVideoUrl: e.target.value})}
                                     />
                                     <div className="flex items-center">
                                         <input type="checkbox" id="fr-validation" className="h-4 w-4 rounded border-gray-300 text-brand-primary focus:ring-brand-primary" checked={fundraising.validationRequested} onChange={e => setFundraising({...fundraising, validationRequested: e.target.checked})} />
                                         <label htmlFor="fr-validation" className="ml-2 block text-sm text-gray-900">Startup Nation Validation Requested</label>
                                     </div>
                                     {fundraising.validationRequested && (
                                         <div className="p-3 bg-blue-50 border-l-4 border-brand-accent text-sm text-slate-600">
                                             Startup Nation will charge 3% of fund raised or 4% to total equity raised as fees for validation, documentation and connection.
                                         </div>
                                     )}
                                 </div>
                             </fieldset>
                         )}
                    </Card>
                </div>
            </div>
            
            {/* Offers Received - moved below graphs and fundraising */}
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Offers Received</h3>
                {isViewOnly && (
                    <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                        <p className="text-sm text-blue-800">
                            <strong>Debug Info:</strong> Loading offers for startup ID: {startup.id} | 
                            Offers loaded: {offersReceived.length} | 
                            User role: {userRole} | 
                            View only: {isViewOnly ? 'Yes' : 'No'}
                        </p>
                    </div>
                )}
                <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-slate-200">
                        <thead className="bg-slate-50">
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">From</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Type</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Offer Details</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Actions / Status</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Code</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-slate-200">
                            {offersReceived.map(offer => (
                                <tr key={offer.id}>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">
                                        {offer.from}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                                        {offer.type}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                                        {offer.offerDetails}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        {offer.type === 'Incubation' && offer.status === 'accepted' && offer.agreementUrl && (
                                            <button
                                                onClick={() => handleDownloadAgreement(offer.agreementUrl!)}
                                                className="text-blue-600 hover:text-blue-800 flex items-center gap-1"
                                            >
                                                <Download className="h-4 w-4" />
                                                Download Agreement
                                            </button>
                                        )}
                                        {offer.type === 'Due Diligence' && offer.status === 'pending' && (
                                            <Button
                                                size="sm"
                                                onClick={() => handleAcceptDiligenceRequest(offer)}
                                                disabled={isAcceptingOffer || offer.status !== 'pending'}
                                                className="flex items-center gap-1"
                                            >
                                                <Check className="h-4 w-4" />
                                                {isAcceptingOffer ? 'Accepting...' : 'Accept Request'}
                                            </Button>
                                        )}
                                        {offer.type === 'Due Diligence' && offer.status === 'accepted' && offer.agreementUrl && (
                                            <button
                                                onClick={() => handleDownloadAgreement(offer.agreementUrl!)}
                                                className="text-blue-600 hover:text-blue-800 flex items-center gap-1"
                                            >
                                                <Download className="h-4 w-4" />
                                                Download Agreement
                                            </button>
                                        )}
                                        {offer.type === 'Due Diligence' && offer.status === 'accepted' && !offer.agreementUrl && (
                                            <span className="text-green-600 flex items-center gap-1">
                                                <Check className="h-4 w-4" />
                                                Accepted
                                            </span>
                                        )}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                                        {offer.code}
                                    </td>
                                </tr>
                            ))}
                            {offersReceived.length === 0 && (
                                <tr>
                                    <td colSpan={5} className="px-6 py-8 text-center text-slate-500">
                                        {isViewOnly ? (
                                            <div className="space-y-2">
                                                <p className="text-sm">No offers or opportunities received yet.</p>
                                                <p className="text-xs text-slate-400">This startup hasn't applied to any incubation programs or received investment offers.</p>
                                            </div>
                                        ) : (
                                            "No offers received yet."
                                        )}
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </Card>
            
            <Modal isOpen={isFounderModalOpen} onClose={() => setIsFounderModalOpen(false)} title="Edit Founder Information">
                <div className="space-y-4 max-h-[60vh] overflow-y-auto pr-2">
                    {editingFounders.map((founder, index) => (
                        <div key={founder.id} className="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-2 relative border p-4 rounded-lg bg-slate-50/50">
                            <Input 
                                label={`Founder ${index + 1} Name`}
                                id={`founder-name-${founder.id}`}
                                type="text"
                                value={founder.name}
                                onChange={e => handleFounderChange(founder.id, 'name', e.target.value)}
                                required
                            />
                            <Input 
                                label={`Founder ${index + 1} Email`}
                                id={`founder-email-${founder.id}`}
                                type="email"
                                value={founder.email}
                                onChange={e => handleFounderChange(founder.id, 'email', e.target.value)}
                                required
                            />
                            {editingFounders.length > 1 && (
                                <Button 
                                    type="button" 
                                    onClick={() => handleRemoveFounder(founder.id)}
                                    className="absolute top-2 right-2 p-1.5 h-auto bg-transparent hover:bg-red-100 text-slate-400 hover:text-red-500 shadow-none border-none"
                                    variant="secondary"
                                    size="sm"
                                    aria-label="Remove founder"
                                >
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            )}
                        </div>
                    ))}
                    <Button type="button" variant="outline" size="sm" onClick={handleAddFounder}>
                        <UserPlus className="h-4 w-4 mr-2" />
                        Add Another Founder
                    </Button>
                </div>
                <div className="flex justify-end gap-3 pt-6 border-t mt-4">
                    <Button type="button" variant="secondary" onClick={() => setIsFounderModalOpen(false)}>Cancel</Button>
                    <Button type="button" onClick={handleFounderSave}>Save Changes</Button>
                </div>
                         </Modal>

             {/* Delete Confirmation Modal */}
             <Modal isOpen={isDeleteModalOpen} onClose={() => setIsDeleteModalOpen(false)} title="Delete Investment">
                 <div className="space-y-4">
                     <p className="text-slate-600">
                         Are you sure you want to delete the investment from{' '}
                         <span className="font-semibold">{investmentToDelete?.investorName}</span>?
                     </p>
                     <p className="text-sm text-slate-500">
                         This action cannot be undone. The investment record will be permanently removed.
                     </p>
                 </div>
                 <div className="flex justify-end gap-3 pt-6 border-t mt-4">
                     <Button type="button" variant="secondary" onClick={() => setIsDeleteModalOpen(false)}>
                         Cancel
                     </Button>
                     <Button 
                         type="button" 
                         variant="destructive" 
                         onClick={() => investmentToDelete && handleDeleteInvestment(investmentToDelete)}
                     >
                         Delete Investment
                     </Button>
                 </div>
             </Modal>
 
            {/* Recognition and Incubation */}
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Recognition and Incubation</h3>
                <div className="overflow-x-auto">
                     <table className="min-w-full divide-y divide-slate-200 text-sm">
                        <thead className="bg-slate-50">
                            <tr>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Program Name</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Facilitator</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Date Added</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Signed Agreement</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-slate-200">
                            {recognitionRecords.map(rec => (
                                <tr key={rec.id}>
                                    <td className="px-4 py-2 font-medium text-slate-900">{rec.programName}</td>
                                    <td className="px-4 py-2 text-slate-500">{rec.facilitatorName}</td>
                                    <td className="px-4 py-2 text-slate-500">{rec.dateAdded}</td>

                                    <td className="px-4 py-2 text-slate-500">
                                        <a href={rec.signedAgreementUrl} className="flex items-center text-brand-primary hover:underline">
                                            <Download className="h-4 w-4 mr-1"/> View Document
                                        </a>
                                    </td>
                                </tr>
                            ))}
                             {recognitionRecords.length === 0 && (
                                <tr><td colSpan={4} className="text-center py-6 text-slate-500">No recognitions added yet.</td></tr>
                            )}
                        </tbody>
                    </table>
                        </div>
            </Card>

            {/* Investor List */}
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Investor List</h3>
                <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-slate-200 text-sm">
                        <thead className="bg-slate-50">
                            <tr>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Investor Name</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Investor Code</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Amount</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Equity</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Post-Money</th>
                                <th className="px-4 py-2 text-right font-medium text-slate-500">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-slate-200">
                            {investmentRecords.map(inv => (
                                    <tr key={inv.id}>
                                        <td className="px-4 py-2 font-medium text-slate-900">{inv.investorName}</td>
                                        <td className="px-4 py-2 text-slate-500 font-mono text-xs">
                                            {inv.investorCode ? (
                                                <span className="bg-blue-50 text-blue-700 px-2 py-1 rounded border border-blue-200">
                                                    {inv.investorCode}
                                                </span>
                                            ) : (
                                                <span className="text-slate-400">No code</span>
                                            )}
                                        </td>
                                        <td className="px-4 py-2 text-slate-500">{formatCurrency(inv.amount)}</td>
                                        <td className="px-4 py-2 text-slate-500">{inv.equityAllocated}%</td>
                                        <td className="px-4 py-2 text-slate-500">{formatCurrency(inv.postMoneyValuation || ((inv.equityAllocated && inv.equityAllocated > 0) ? (inv.amount * 100) / inv.equityAllocated : 0))}</td>
                                        <td className="px-4 py-2 text-right">
                                            <div className="flex items-center justify-end gap-2">
                                                <Button size="sm" variant="outline" disabled={!canEdit}><Edit3 className="h-4 w-4" /></Button>
                                                {canEdit && (
                                                    <Button 
                                                        size="sm" 
                                                        variant="outline" 
                                                        className="text-red-600 border-red-300 hover:bg-red-50"
                                                        onClick={() => {
                                                            setInvestmentToDelete(inv);
                                                            setIsDeleteModalOpen(true);
                                                        }}
                                                    >
                                                        <Trash2 className="h-4 w-4" />
                                                    </Button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                            ))}
                            {investmentRecords.length === 0 && (
                                <tr><td colSpan={6} className="text-center py-6 text-slate-500">No investments added yet.</td></tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </Card>

            {/* Incubation & Acceleration Programs */}
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Incubation & Acceleration Programs</h3>
                <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-slate-200 text-sm">
                        <thead className="bg-slate-50">
                            <tr>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Program Name</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Program Type</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Start Date</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">End Date</th>
                                <th className="px-4 py-2 text-left font-medium text-slate-500">Status</th>
                                <th className="px-4 py-2 text-right font-medium text-slate-500">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-slate-200">
                            {incubationPrograms.map(program => (
                                <tr key={program.id}>
                                    <td className="px-4 py-2 font-medium text-slate-900">{program.programName}</td>
                                    <td className="px-4 py-2 text-slate-500">{program.programType}</td>
                                    <td className="px-4 py-2 text-slate-500">{program.startDate}</td>
                                    <td className="px-4 py-2 text-slate-500">{program.endDate}</td>
                                        <td className="px-4 py-2 text-slate-500">
                                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                            program.status === 'Active' ? 'bg-green-100 text-green-800' :
                                            program.status === 'Completed' ? 'bg-blue-100 text-blue-800' :
                                            'bg-red-100 text-red-800'
                                        }`}>
                                            {program.status}
                                        </span>
                                        </td>
                                        <td className="px-4 py-2 text-right">
                                        <Button size="sm" variant="outline" disabled={!canEdit}><Edit3 className="h-4 w-4" /></Button>
                                        </td>
                                    </tr>
                            ))}
                            {incubationPrograms.length === 0 && (
                                <tr><td colSpan={6} className="px-6 py-6 text-center text-slate-500">
                                    {isViewOnly ? (
                                        <div className="space-y-2">
                                            <p className="text-sm">No incubation programs enrolled yet.</p>
                                            <p className="text-xs text-slate-400">This startup hasn't joined any incubation or acceleration programs.</p>
                                        </div>
                                    ) : (
                                        "No incubation programs added yet."
                                    )}
                                </td></tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </Card>

            {/* Add Entry Form (Unified) */}
            <Card>
                <h3 className="text-lg font-semibold mb-4 text-slate-700">Add New Entry to Cap Table</h3>
                <fieldset disabled={!canEdit}>
                    <form onSubmit={handleEntrySubmit} className="space-y-4">
                        <Select label="Entry Type" id="entry-type" value={entryType} onChange={e => setEntryType(e.target.value as 'investment' | 'recognition')}>
                            <option value="investment">Investment</option>
                            <option value="recognition">Recognition / Incubation</option>
                        </Select>

                        {entryType === 'investment' && (
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 pt-4 border-t">
                                <Input label="Date" name="inv-date" id="inv-date" type="date" required />
                                <Select label="Investor Type" name="inv-investor-type" id="inv-investor-type" required>
                                    {Object.values(InvestorType).map(t => <option key={t} value={t}>{t}</option>)}
                                </Select>
                                <Select label="Investment Type" name="inv-type" id="inv-type" required>
                                    {Object.values(InvestmentRoundType).map(t => <option key={t} value={t}>{t}</option>)}
                                </Select>
                                <Input label="Investor Name" name="inv-name" id="inv-name" required />
                                <Input label="Investor Code" name="inv-code" id="inv-code" placeholder="e.g., INV-A7B3C9"/>
                                <Input label="Investment Amount" name="inv-amount" id="inv-amount" type="number" required value={invAmountDraft} onChange={(e) => setInvAmountDraft(e.target.value)} />
                                <Input label="Equity Allocated (%)" name="inv-equity" id="inv-equity" type="number" required value={invEquityDraft} onChange={(e) => setInvEquityDraft(e.target.value)} />
                                <Input label="Post-Money Valuation (auto)" name="inv-postmoney" id="inv-postmoney" type="number" readOnly value={invPostMoneyDraft} />
                                <Input label="Proof of Investment" name="inv-proof" id="inv-proof" type="file" />
                            </div>
                        )}

                        {entryType === 'recognition' && (
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4 border-t">
                                <Input label="Program Name" name="rec-program-name" id="rec-program-name" required containerClassName="md:col-span-2"/>
                                <Input label="Facilitator Name" name="rec-facilitator-name" id="rec-facilitator-name" required />
                                <Input label="Facilitator Code" name="rec-facilitator-code" id="rec-facilitator-code" placeholder="e.g., FAC-D4E5F6" required />
                                <Select label="Incubation Type" name="rec-incubation-type" id="rec-incubation-type" required>
                                    {Object.values(IncubationType).map(t => <option key={t} value={t}>{t}</option>)}
                                </Select>
                                <Select label="Fee Type" name="rec-fee-type" id="rec-fee-type" value={feeType} onChange={e => setFeeType(e.target.value as FeeType)} required>
                                   {Object.values(FeeType).map(t => <option key={t} value={t}>{t}</option>)}
                                </Select>
                                {(feeType === FeeType.Fees || feeType === FeeType.Hybrid) && (
                                    <Input label="Fee Amount" name="rec-fee-amount" id="rec-fee-amount" type="number" required />
                                )}
                                {(feeType === FeeType.Equity || feeType === FeeType.Hybrid) && (
                                    <>
                                        <Input label="Equity Allocated (%)" name="rec-equity" id="rec-equity" type="number" required/>
                                        <Input label="Pre-Money Valuation" name="rec-premoney" id="rec-premoney" type="number" required/>
                                    </>
                                )}
                                <Input label="Upload Signed Agreement" name="rec-agreement" id="rec-agreement" type="file" required containerClassName="md:col-span-2" />
                            </div>
                        )}
                        
                        <div className="flex items-end pt-4 border-t">
                            <Button type="submit"><Plus className="h-4 w-4 mr-2" />Add Entry</Button>
                        </div>
                    </form>
                </fieldset>
            </Card>

            {/* Incubation & Acceleration Programs */}
            {/* Add New Program Form */}
            {canEdit && (
                <Card>
                    <h3 className="text-lg font-semibold mb-4 text-slate-700">Add New Program</h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        <Select 
                            label="Program" 
                            id="program-name" 
                            value={newProgram.programName} 
                            onChange={e => handleProgramNameChange(e.target.value)}
                        >
                            <option value="">Select a program</option>
                            {popularPrograms.map(program => (
                                <option key={program} value={program}>{program}</option>
                            ))}
                            <option value="custom">Custom Program</option>
                        </Select>
                        <Select 
                            label="Type" 
                            id="program-type" 
                            value={newProgram.programType} 
                            onChange={e => handleProgramTypeChange(e.target.value as any)}
                        >
                            <option value="Acceleration">Acceleration</option>
                            <option value="Incubation">Incubation</option>
                            <option value="Mentorship">Mentorship</option>
                            <option value="Bootcamp">Bootcamp</option>
                        </Select>
                        <Input 
                            label="Start Date" 
                            id="program-start-date" 
                            type="date" 
                            value={newProgram.startDate} 
                            onChange={e => setNewProgram({...newProgram, startDate: e.target.value})} 
                        />
                        <Input 
                            label="End Date" 
                            id="program-end-date" 
                            type="date" 
                            value={newProgram.endDate} 
                            onChange={e => setNewProgram({...newProgram, endDate: e.target.value})} 
                        />
                        <Input 
                            label="Mentor Name" 
                            id="program-mentor" 
                            value={newProgram.mentorName} 
                            onChange={e => setNewProgram({...newProgram, mentorName: e.target.value})} 
                            placeholder="Optional"
                        />
                        <Input 
                            label="Mentor Email" 
                            id="program-mentor-email" 
                            type="email" 
                            value={newProgram.mentorEmail} 
                            onChange={e => setNewProgram({...newProgram, mentorEmail: e.target.value})} 
                            placeholder="Optional"
                        />
                        <div className="flex items-end col-span-full">
                            <Button onClick={handleAddProgram}>Add Program</Button>
                        </div>
                    </div>
                </Card>
            )}

            {/* Delete Program Confirmation Modal */}
            <Modal 
                isOpen={isDeleteProgramModalOpen} 
                onClose={() => setIsDeleteProgramModalOpen(false)}
                title="Delete Program"
            >
                <div className="space-y-4">
                    <p>Are you sure you want to delete the program "{programToDelete?.programName}"?</p>
                    <p className="text-sm text-slate-500">This action cannot be undone.</p>
                    <div className="flex gap-3 justify-end">
                        <Button 
                            type="button" 
                            variant="outline" 
                            onClick={() => setIsDeleteProgramModalOpen(false)}
                        >
                            Cancel
                        </Button>
                        <Button 
                            type="button" 
                            variant="destructive" 
                            onClick={() => programToDelete && handleDeleteProgram(programToDelete.id)}
                        >
                            Delete Program
                        </Button>
                    </div>
                </div>
            </Modal>
            {/* Total Shares Modal */}
            <SimpleModal 
                isOpen={isSharesModalOpen}
                title="Update Total Shares"
                onClose={() => setIsSharesModalOpen(false)}
                footer={
                    <>
                        <Button type="button" variant="outline" onClick={() => setIsSharesModalOpen(false)}>Cancel</Button>
                        <Button 
                            type="button"
                            onClick={async () => {
                                const parsed = Number(totalSharesDraft);
                                if (!Number.isFinite(parsed) || parsed < 0) {
                                    setError('Please enter a valid non-negative number');
                                    return;
                                }
                                try {
                                    setIsSavingShares(true);
                                    let latestValuation = startup.currentValuation || 0;
                                    if (investmentRecords && investmentRecords.length > 0) {
                                        const latest = [...investmentRecords]
                                            .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())[0] as any;
                                        if (latest?.postMoneyValuation && latest.postMoneyValuation > 0) {
                                            latestValuation = latest.postMoneyValuation;
                                        }
                                    }
                                    const computedPricePerShare = parsed > 0 ? latestValuation / parsed : 0;
                                    const saved = await capTableService.upsertTotalShares(startup.id, parsed, computedPricePerShare);
                                    setTotalShares(saved);
                                    setPricePerShare(computedPricePerShare);
                                    setIsSharesModalOpen(false);
                                } catch (err) {
                                    console.error('Failed to save total shares', err);
                                } finally {
                                    setIsSavingShares(false);
                                }
                            }}
                        >
                            Save
                        </Button>
                    </>
                }
            >
                <div style={{ display: 'grid', gap: 8 }}>
                    <label htmlFor="modal-total-shares" style={{ fontSize: 12, color: '#475569' }}>Total Shares</label>
                    <input 
                        id="modal-total-shares"
                        type="number"
                        value={totalSharesDraft}
                        onChange={(e) => setTotalSharesDraft(e.target.value)}
                        style={{ padding: '8px 10px', border: '1px solid #cbd5e1', borderRadius: 6 }}
                    />
                </div>
            </SimpleModal>

        </div>
    );
};

export default CapTableTab;