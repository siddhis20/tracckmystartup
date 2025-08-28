import { Startup, NewInvestment, ComplianceStatus, InvestmentType, StartupAdditionRequest, User, UserRole, VerificationRequest, InvestmentOffer } from './types';

export const mockStartups: Startup[] = [
  {
    id: 1,
    name: 'InnovateAI',
    investmentType: InvestmentType.SeriesA,
    investmentValue: 500000,
    equityAllocation: 10,
    currentValuation: 10000000,
    complianceStatus: ComplianceStatus.Compliant,
    sector: 'AI/ML',
    totalFunding: 2000000,
    totalRevenue: 500000,
    registrationDate: '2022-01-15',
    founders: [
        { name: 'Alex Chen', email: 'alex@innovateai.com' },
        { name: 'Brenda Lee', email: 'brenda@innovateai.com' },
    ],
  },
  {
    id: 2,
    name: 'HealthWell',
    investmentType: InvestmentType.SeriesB,
    investmentValue: 1000000,
    equityAllocation: 15,
    currentValuation: 25000000,
    complianceStatus: ComplianceStatus.Compliant,
    sector: 'HealthTech',
    totalFunding: 5000000,
    totalRevenue: 1200000,
    registrationDate: '2021-06-20',
    founders: [],
  },
  {
    id: 3,
    name: 'FinSecure',
    investmentType: InvestmentType.SeriesA,
    investmentValue: 750000,
    equityAllocation: 8,
    currentValuation: 15000000,
    complianceStatus: ComplianceStatus.Pending,
    sector: 'FinTech',
    totalFunding: 3000000,
    totalRevenue: 800000,
    registrationDate: '2023-03-10',
    founders: [],
  },
  {
    id: 4,
    name: 'EcoSolutions',
    investmentType: InvestmentType.Seed,
    investmentValue: 250000,
    equityAllocation: 5,
    currentValuation: 5000000,
    complianceStatus: ComplianceStatus.NonCompliant,
    sector: 'GreenTech',
    totalFunding: 1000000,
    totalRevenue: 150000,
    registrationDate: '2022-11-05',
    founders: [],
  },
   {
    id: 5,
    name: 'EduVerse',
    investmentType: InvestmentType.Seed,
    investmentValue: 400000,
    equityAllocation: 12,
    currentValuation: 8000000,
    complianceStatus: ComplianceStatus.Compliant,
    sector: 'EdTech',
    totalFunding: 1500000,
    totalRevenue: 300000,
    registrationDate: '2021-09-01',
    founders: [],
  },
];

export const mockNewInvestments: NewInvestment[] = [
    {
        id: 101,
        name: 'QuantumLeap',
        investmentType: InvestmentType.Seed,
        investmentValue: 150000,
        equityAllocation: 7,
        sector: 'DeepTech',
        totalFunding: 150000,
        totalRevenue: 0,
        registrationDate: '2024-02-01',
        pitchDeckUrl: '#',
        pitchVideoUrl: 'https://www.youtube.com/watch?v=QJ21TaeN9K0',
        complianceStatus: ComplianceStatus.Compliant,
    },
    {
        id: 102,
        name: 'AgroFuture',
        investmentType: InvestmentType.SeriesA,
        investmentValue: 1200000,
        equityAllocation: 18,
        sector: 'AgriTech',
        totalFunding: 2500000,
        totalRevenue: 400000,
        registrationDate: '2023-08-15',
        pitchDeckUrl: '#',
        pitchVideoUrl: 'https://www.youtube.com/watch?v=gt_l_4TfG4k',
        complianceStatus: ComplianceStatus.Pending,
    },
    { id: 103, name: 'CyberGuard', investmentType: InvestmentType.SeriesB, investmentValue: 3000000, equityAllocation: 10, sector: 'Cybersecurity', totalFunding: 5000000, totalRevenue: 1000000, registrationDate: '2022-07-22', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=rok_p26_Z5o', complianceStatus: ComplianceStatus.Compliant },
    { id: 104, name: 'BioSynth', investmentType: InvestmentType.Seed, investmentValue: 500000, equityAllocation: 15, sector: 'BioTech', totalFunding: 500000, totalRevenue: 50000, registrationDate: '2024-01-05', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=8aGhZQkoFbQ', complianceStatus: ComplianceStatus.Compliant },
    { id: 105, name: 'RetailNext', investmentType: InvestmentType.SeriesA, investmentValue: 2500000, equityAllocation: 12, sector: 'RetailTech', totalFunding: 4000000, totalRevenue: 800000, registrationDate: '2023-05-18', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=Y_N1_Jj9-KA', complianceStatus: ComplianceStatus.Pending },
    { id: 106, name: 'GameOn', investmentType: InvestmentType.Seed, investmentValue: 750000, equityAllocation: 20, sector: 'Gaming', totalFunding: 750000, totalRevenue: 150000, registrationDate: '2023-11-30', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=d_HlPboL_sA', complianceStatus: ComplianceStatus.Compliant },
    { id: 107, name: 'PropTech Pro', investmentType: InvestmentType.PreSeed, investmentValue: 100000, equityAllocation: 5, sector: 'Real Estate', totalFunding: 100000, totalRevenue: 10000, registrationDate: '2024-03-01', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=uK67H2PAmn8', complianceStatus: ComplianceStatus.Pending },
    { id: 108, name: 'LogiChain', investmentType: InvestmentType.SeriesA, investmentValue: 1800000, equityAllocation: 9, sector: 'Logistics', totalFunding: 3000000, totalRevenue: 600000, registrationDate: '2022-09-10', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=uJg4B5a-a28', complianceStatus: ComplianceStatus.Compliant },
    { id: 109, name: 'EduKids', investmentType: InvestmentType.Seed, investmentValue: 300000, equityAllocation: 10, sector: 'EdTech', totalFunding: 300000, totalRevenue: 60000, registrationDate: '2023-10-25', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=GGlY3g_2Q_E', complianceStatus: ComplianceStatus.NonCompliant },
    { id: 110, name: 'QuantumLeap 2', investmentType: InvestmentType.Seed, investmentValue: 150000, equityAllocation: 7, sector: 'DeepTech', totalFunding: 150000, totalRevenue: 0, registrationDate: '2024-02-01', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=P1ww1X2-S1U', complianceStatus: ComplianceStatus.Compliant, },
    { id: 111, name: 'SpaceHaul', investmentType: InvestmentType.SeriesB, investmentValue: 10000000, equityAllocation: 15, sector: 'Aerospace', totalFunding: 25000000, totalRevenue: 500000, registrationDate: '2021-12-01', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=sO-tjb4Edb8', complianceStatus: ComplianceStatus.Compliant },
    { id: 112, name: 'MindWell', investmentType: InvestmentType.Seed, investmentValue: 400000, equityAllocation: 12, sector: 'HealthTech', totalFunding: 400000, totalRevenue: 80000, registrationDate: '2024-04-10', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=4x7_v-2-a3I', complianceStatus: ComplianceStatus.Compliant },
    { id: 113, name: 'CleanPlate', investmentType: InvestmentType.Seed, investmentValue: 200000, equityAllocation: 8, sector: 'FoodTech', totalFunding: 200000, totalRevenue: 40000, registrationDate: '2023-09-05', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=ysz5S6PUM-U', complianceStatus: ComplianceStatus.Pending },
    { id: 114, name: 'Solaris', investmentType: InvestmentType.SeriesA, investmentValue: 2200000, equityAllocation: 11, sector: 'GreenTech', totalFunding: 3500000, totalRevenue: 700000, registrationDate: '2022-11-20', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=o0u4M6vppCI', complianceStatus: ComplianceStatus.Compliant },
    { id: 115, name: 'LegalEase', investmentType: InvestmentType.PreSeed, investmentValue: 120000, equityAllocation: 6, sector: 'LegalTech', totalFunding: 120000, totalRevenue: 25000, registrationDate: '2024-05-15', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=J132shgI_Ns', complianceStatus: ComplianceStatus.Pending },
    { id: 116, name: 'TravelBug', investmentType: InvestmentType.Seed, investmentValue: 600000, equityAllocation: 14, sector: 'TravelTech', totalFunding: 600000, totalRevenue: 120000, registrationDate: '2023-03-12', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=T_i-T58-S2E', complianceStatus: ComplianceStatus.Compliant },
    { id: 117, name: 'DataWeave', investmentType: InvestmentType.SeriesB, investmentValue: 4500000, equityAllocation: 10, sector: 'Data Analytics', totalFunding: 8000000, totalRevenue: 1500000, registrationDate: '2021-10-01', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=R2vXbFp5C9o', complianceStatus: ComplianceStatus.Compliant },
    { id: 118, name: 'AutoDrive', investmentType: InvestmentType.SeriesA, investmentValue: 5000000, equityAllocation: 18, sector: 'Automotive', totalFunding: 10000000, totalRevenue: 800000, registrationDate: '2022-06-01', pitchDeckUrl: '#', pitchVideoUrl: 'https://www.youtube.com/watch?v=uA8X54c_w18', complianceStatus: ComplianceStatus.NonCompliant }
];

export const mockStartupAdditionRequests: StartupAdditionRequest[] = [
    {
        id: 201,
        name: 'ConnectSphere',
        investmentType: InvestmentType.Seed,
        investmentValue: 200000,
        equityAllocation: 8,
        sector: 'Social Tech',
        totalFunding: 200000,
        totalRevenue: 10000,
        registrationDate: '2023-11-20'
    }
];

export const mockUsers: User[] = [
    { id: 'user-1', name: 'Alice Investor', email: 'investor@example.com', role: 'Investor', registrationDate: '2023-01-10', investorCode: 'INV-A7B3C9' },
    { id: 'user-2', name: 'Alex Chen', email: 'alex@innovateai.com', role: 'Startup', registrationDate: '2022-01-15' },
    { id: 'user-3', name: 'Bob CA', email: 'ca@example.com', role: 'CA', registrationDate: '2023-03-01' },
    { id: 'user-4', name: 'Charlie CS', email: 'cs@example.com', role: 'CS', registrationDate: '2023-04-01' },
    { id: 'user-5', name: 'Admin User', email: 'admin@example.com', role: 'Admin', registrationDate: '2022-01-01' },
    { id: 'user-6', name: 'Brenda Lee', email: 'brenda@innovateai.com', role: 'Startup', registrationDate: '2022-01-15' },
    { id: 'user-7', name: 'Facilitator One', email: 'facilitator@example.com', role: 'Startup Facilitation Center', registrationDate: '2024-01-20' },
];

export const mockVerificationRequests: VerificationRequest[] = [
    { id: 1, startupId: 3, startupName: 'FinSecure', requestDate: '2024-06-25' },
    { id: 2, startupId: 4, startupName: 'EcoSolutions', requestDate: '2024-06-28' },
];

export const mockInvestmentOffers: InvestmentOffer[] = [
    { 
        id: 1, 
        investorEmail: 'investor@example.com', 
        startupName: 'QuantumLeap', 
        investment: mockNewInvestments[0], 
        offerAmount: 140000, 
        equityPercentage: 6.5,
        status: 'pending' 
    },
    { 
        id: 2, 
        investorEmail: 'investor@example.com', 
        startupName: 'AgroFuture', 
        investment: mockNewInvestments[1], 
        offerAmount: 1100000, 
        equityPercentage: 17,
        status: 'pending' 
    }
];

// Compliance rules for different countries and company types
export const COMPLIANCE_RULES = {
    'Canada': {
        'Private Limited': {
            firstYear: [
                { id: 'articles', name: 'Articles of Incorporation', caRequired: true, csRequired: false }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: true, csRequired: false },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: false, csRequired: true }
            ]
        },
        'Public Limited': {
            firstYear: [
                { id: 'articles', name: 'Articles of Incorporation', caRequired: true, csRequired: true }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: true, csRequired: true },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: true, csRequired: true }
            ]
        },
        default: {
            firstYear: [
                { id: 'articles', name: 'Articles of Incorporation', caRequired: true, csRequired: false }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: true, csRequired: false },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: false, csRequired: true }
            ]
        }
    },
    'India': {
        'Private Limited': {
            firstYear: [
                { id: 'articles', name: 'Articles of Incorporation', caRequired: true, csRequired: false }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: true, csRequired: false },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: false, csRequired: true }
            ]
        },
        'Public Limited': {
            firstYear: [
                { id: 'articles', name: 'Articles of Incorporation', caRequired: true, csRequired: true }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: true, csRequired: true },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: true, csRequired: true }
            ]
        },
        default: {
            firstYear: [
                { id: 'articles', name: 'Articles of Incorporation', caRequired: true, csRequired: false }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: true, csRequired: false },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: false, csRequired: true }
            ]
        }
    },
    'United States': {
        'LLC': {
            firstYear: [
                { id: 'articles', name: 'Articles of Organization', caRequired: false, csRequired: false }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: false, csRequired: false },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: false, csRequired: false }
            ]
        },
        'Corporation': {
            firstYear: [
                { id: 'articles', name: 'Articles of Incorporation', caRequired: true, csRequired: false }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: true, csRequired: false },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: false, csRequired: true }
            ]
        },
        default: {
            firstYear: [
                { id: 'articles', name: 'Articles of Incorporation', caRequired: true, csRequired: false }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: true, csRequired: false },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: false, csRequired: true }
            ]
        }
    },
    default: {
        'Private Limited': {
            firstYear: [
                { id: 'articles', name: 'Articles of Incorporation', caRequired: true, csRequired: false }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: true, csRequired: false },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: false, csRequired: true }
            ]
        },
        default: {
            firstYear: [
                { id: 'articles', name: 'Articles of Incorporation', caRequired: true, csRequired: false }
            ],
            annual: [
                { id: 'annual_report', name: 'Annual Report', caRequired: true, csRequired: false },
                { id: 'board_minutes', name: 'Board Meeting Minutes', caRequired: false, csRequired: true }
            ]
        }
    }
};

// Countries list for dropdown
export const COUNTRIES = [
    'Canada',
    'India', 
    'United States',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'Singapore',
    'Brazil'
];