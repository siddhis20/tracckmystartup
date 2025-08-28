export enum ComplianceStatus {
  Compliant = 'Compliant',
  Pending = 'Pending',
  NonCompliant = 'Non-Compliant',
  Verified = 'Verified',
  Rejected = 'Rejected',
  NotRequired = 'Not Required',
}

export enum InvestmentType {
    PreSeed = 'Pre-Seed',
    Seed = 'Seed',
    SeriesA = 'Series A',
    SeriesB = 'Series B',
    Bridge = 'Bridge',
}

export enum IncubationType {
    IncubationCenter = 'Incubation Center',
    Accelerator = 'Accelerator',
    InnovationHub = 'Innovation Hub',
    TechnologyPark = 'Technology Park',
    ResearchInstitute = 'Research Institute',
}

export enum FeeType {
    Free = 'Free',
    Fees = 'Fees',
    Equity = 'Equity',
    Hybrid = 'Hybrid',
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
  profile?: ProfileData;
  complianceChecks?: ComplianceCheck[];
  financials?: FinancialRecord[];
  investments?: InvestmentRecord[];
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
  investorCode?: string;
  status?: 'pending' | 'approved' | 'rejected';
}

// New types for Startup Health View

export interface ServiceProvider {
  name: string;
  code: string;
  licenseUrl: string;
}

export interface Subsidiary {
  id: number;
  country: string;
  companyType: string;
  registrationDate: string;
  caCode?: string;
  csCode?: string;
  ca?: ServiceProvider;
  cs?: ServiceProvider;
}

export interface InternationalOp {
  id: number;
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
  ca?: ServiceProvider;
  cs?: ServiceProvider;
}

// New compliance task interface for dynamic generation
export interface ComplianceTaskGenerated {
  task_id: string;
  entity_identifier: string;
  entity_display_name: string;
  year: number;
  task_name: string;
  ca_required: boolean;
  cs_required: boolean;
  task_type: string;
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

// Missing shared types referenced across services
export type EsopAllocationType = 'one-time' | 'annually' | 'quarterly' | 'monthly';
export type OfferStatus = 'pending' | 'approved' | 'rejected' | 'accepted' | 'completed';

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

export interface RecognitionRecord {
    id: string;
    startupId: number;
    programName: string;
    facilitatorName: string;
    facilitatorCode: string;
    incubationType: IncubationType;
    feeType: FeeType;
    feeAmount?: number;
    equityAllocated?: number;
    preMoneyValuation?: number;
    signedAgreementUrl: string;
    status?: string;
    dateAdded: string;
    startup?: {
        id: number;
        name: string;
        sector: string;
        current_valuation: number;
        compliance_status: string;
        total_funding: number;
        total_revenue: number;
        registration_date: string;
    };
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
    serviceCode?: string;
    investorCode?: string; // Unique investor code for investors
    caCode?: string; // Unique CA code for CA users
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
    investorName?: string;
    startupName: string;
    startup?: {
        id: number;
        name: string;
        sector: string;
        complianceStatus: ComplianceStatus;
        startupNationValidated?: boolean;
        validationDate?: string;
        createdAt: string;
    };
    offerAmount: number;
    equityPercentage: number;
    status: 'pending' | 'approved' | 'rejected' | 'accepted' | 'completed';
    createdAt: string;
}

// Incubation & Acceleration Programs
export interface IncubationProgram {
    id: string;
    programName: string;
    programType: 'Incubation' | 'Acceleration' | 'Mentorship' | 'Bootcamp';
    startDate: string;
    endDate: string;
    status: 'Active' | 'Completed' | 'Dropped';
    description?: string;
    mentorName?: string;
    mentorEmail?: string;
    programUrl?: string;
    createdAt: string;
}

export interface AddIncubationProgramData {
    programName: string;
    programType: 'Incubation' | 'Acceleration' | 'Mentorship' | 'Bootcamp';
    startDate: string;
    endDate: string;
    description?: string;
    mentorName?: string;
    mentorEmail?: string;
    programUrl?: string;
}

// Compliance related interfaces
export interface ComplianceCheck {
    taskId: string;
    caStatus: ComplianceStatus;
    csStatus: ComplianceStatus;
    documentUrl?: string;
}

export enum FinancialVertical {
    Saas = 'SaaS',
    Ecommerce = 'E-commerce',
    Fintech = 'FinTech',
    Healthtech = 'HealthTech',
    Edtech = 'EdTech',
    Other = 'Other'
}