export enum ComplianceStatus {
  Compliant = 'Compliant',
  Pending = 'Pending',
  NonCompliant = 'Non-Compliant',
}

export enum InvestmentType {
    PreSeed = 'Pre-Seed',
    Seed = 'Seed',
    SeriesA = 'Series A',
    SeriesB = 'Series B',
    Bridge = 'Bridge',
}

export type UserRole = 'Investor' | 'Startup' | 'CA' | 'CS' | 'Admin' | 'Startup Facilitation Center';

export interface Founder {
  name: string;
  email: string;
}

export interface Startup {
  id: number;
  name:string;
  investmentType: InvestmentType;
  investmentValue: number;
  equityAllocation: number;
  currentValuation: number;
  complianceStatus: ComplianceStatus;
  sector: string;
  totalFunding: number;
  totalRevenue: number;
  registrationDate: string; // YYYY-MM-DD
  founders: Founder[];
}

export interface NewInvestment {
  id: number;
  name: string;
  investmentType: InvestmentType;
  investmentValue: number;
  equityAllocation: number;
  sector: string;
  totalFunding: number;
  totalRevenue: number;
  registrationDate: string; // YYYY-MM-DD
  pitchDeckUrl?: string;
  pitchVideoUrl?: string;
  complianceStatus: ComplianceStatus;
}

export interface StartupAdditionRequest {
  id: number;
  name: string;
  investmentType: InvestmentType;
  investmentValue: number;
  equityAllocation: number;
  sector: string;
  totalFunding: number;
  totalRevenue: number;
  registrationDate: string;
}

// New types for Startup Health View

export interface Subsidiary {
  id: number;
  country: string;
  companyType: string;
  registrationDate: string;
}

export interface InternationalOp {
  country: string;
  startDate: string;
}

export interface ProfileData {
  country: string;
  companyType: string;
  registrationDate: string;
  subsidiaries: Subsidiary[];
  internationalOps: InternationalOp[];
  caServiceCode?: string;
  csServiceCode?: string;
}


export interface FinancialRecord {
    id: string;
    startup_id: number;
    record_type: 'expense' | 'revenue';
    date: string;
    entity: string;
    description: string;
    vertical: string;
    amount: number;
    funding_source?: string; // For expenses
    cogs?: number; // For revenue
    attachment_url?: string;
}

// Add missing interfaces for FinancialsTab
export interface Expense {
    id: string;
    date: string;
    entity: string;
    description: string;
    vertical: string;
    amount: number;
    fundingSource: string;
    attachmentUrl?: string;
}

export interface Revenue {
    id: string;
    date: string;
    entity: string;
    vertical: string;
    earnings: number;
    cogs: number;
    attachmentUrl?: string;
}

export interface Employee {
    id: string;
    name: string;
    joiningDate: string;
    entity: string;
    department: string;
    salary: number;
    esopAllocation: number; // Represents currency value
    allocationType: 'one-time' | 'annually' | 'quarterly' | 'monthly';
    esopPerAllocation: number;
    contractUrl?: string;
}

export enum InvestorType {
    Angel = 'Angel',
    VC = 'VC Firm',
    Corporate = 'Corporate',
    Government = 'Government'
}

export enum InvestmentRoundType {
    Equity = 'Equity',
    Debt = 'Debt',
    Grant = 'Grant'
}

export interface InvestmentRecord {
    id: string;
    date: string;
    investorType: InvestorType;
    investmentType: InvestmentRoundType;
    investorName: string;
    investorCode?: string;
    amount: number;
    equityAllocated: number;
    preMoneyValuation: number;
    proofUrl?: string;
}

export interface FundraisingDetails {
    active: boolean;
    type: InvestmentType;
    value: number;
    equity: number;
    validationRequested: boolean;
    pitchDeckUrl?: string;
    pitchVideoUrl?: string;
}

// Admin Panel Types
export interface User {
    id: string;
    name: string;
    email: string;
    role: UserRole;
    registrationDate: string; // YYYY-MM-DD
}

export interface VerificationRequest {
    id: number;
    startupId: number;
    startupName: string;
    requestDate: string; // YYYY-MM-DD
}

export interface InvestmentOffer {
    id: number;
    investorEmail: string;
    startupName: string;
    investment: NewInvestment; // The opportunity being offered on
    offerAmount: number;
    equityPercentage: number;
    status: 'pending' | 'approved' | 'rejected';
}