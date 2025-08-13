# Cap Table Implementation Guide

## Overview
The Cap Table module provides comprehensive functionality for managing startup investment records, founders, fundraising details, valuation history, and equity holdings. This guide will help you set up and integrate the Cap Table backend with your frontend.

## 🗄️ Database Setup

### 1. Run Backend Setup Script
Execute the following SQL script in your Supabase SQL Editor:

```sql
-- Run CAP_TABLE_BACKEND_SETUP.sql
```

This script creates:
- **5 Tables**: `investment_records`, `founders`, `fundraising_details`, `valuation_history`, `equity_holdings`
- **4 RPC Functions**: `get_investment_summary`, `get_valuation_history`, `get_equity_distribution`, `get_fundraising_status`
- **RLS Policies**: Secure access control for all tables
- **Triggers**: Automatic `updated_at` timestamp updates
- **Sample Data**: Initial test data for development

### 2. Run Storage Setup Script
Execute the storage setup script:

```sql
-- Run CAP_TABLE_STORAGE_SETUP.sql
```

This creates:
- **Storage Bucket**: `cap-table-documents` for investment proofs and pitch decks
- **Storage Policies**: Secure file access control

### 3. Test the Setup
Run the test script to verify everything works:

```sql
-- Run TEST_CAP_TABLE_SETUP.sql
```

## 📁 File Structure

```
lib/
├── capTableService.ts          # Frontend service layer
├── supabase.ts                 # Supabase client

components/startup-health/
├── CapTableTab.tsx            # Main Cap Table component (to be updated)

SQL Scripts/
├── CAP_TABLE_BACKEND_SETUP.sql
├── CAP_TABLE_STORAGE_SETUP.sql
└── TEST_CAP_TABLE_SETUP.sql
```

## 🔧 Frontend Integration

### 1. Service Layer (`lib/capTableService.ts`)
The service provides these key functions:

#### Investment Records
```typescript
// Get all investment records for a startup
const investments = await capTableService.getInvestmentRecords(startupId);

// Add new investment record
const newInvestment = await capTableService.addInvestmentRecord(startupId, {
  date: '2024-01-15',
  investorType: InvestorType.VC,
  investmentType: InvestmentRoundType.Equity,
  investorName: 'Venture Capital Fund',
  amount: 1000000,
  equityAllocated: 10,
  preMoneyValuation: 9000000
});

// Update investment record
await capTableService.updateInvestmentRecord(investmentId, updates);

// Delete investment record
await capTableService.deleteInvestmentRecord(investmentId);
```

#### Founders Management
```typescript
// Get founders
const founders = await capTableService.getFounders(startupId);

// Update founders
await capTableService.updateFounders(startupId, [
  { name: 'John Doe', email: 'john@startup.com' },
  { name: 'Jane Smith', email: 'jane@startup.com' }
]);
```

#### Fundraising Details
```typescript
// Get fundraising status
const fundraising = await capTableService.getFundraisingDetails(startupId);

// Update fundraising details
await capTableService.updateFundraisingDetails(startupId, {
  active: true,
  type: InvestmentType.SeriesA,
  value: 5000000,
  equity: 15,
  validationRequested: true,
  pitchDeckUrl: 'https://...',
  pitchVideoUrl: 'https://youtube.com/...'
});
```

#### Analytics and Charts
```typescript
// Get investment summary for cards
const summary = await capTableService.getInvestmentSummary(startupId);

// Get valuation history for charts
const valuationData = await capTableService.getValuationHistoryData(startupId);

// Get equity distribution for pie chart
const equityData = await capTableService.getEquityDistributionData(startupId);
```

### 2. Real-time Subscriptions
```typescript
// Subscribe to investment record changes
const subscription = capTableService.subscribeToInvestmentRecords(startupId, (payload) => {
  console.log('Investment record changed:', payload);
  // Refresh your UI here
});

// Subscribe to founders changes
capTableService.subscribeToFounders(startupId, (payload) => {
  console.log('Founders changed:', payload);
  // Refresh founders section
});

// Subscribe to fundraising changes
capTableService.subscribeToFundraisingDetails(startupId, (payload) => {
  console.log('Fundraising changed:', payload);
  // Refresh fundraising section
});
```

### 3. File Uploads
```typescript
// Upload investment proof document
const proofUrl = await capTableService.uploadProofDocument(file, startupId);

// Upload pitch deck
const pitchDeckUrl = await capTableService.uploadPitchDeck(file, startupId);
```

## 🎯 Key Features

### 1. Investment Records Management
- ✅ Add, edit, delete investment records
- ✅ Track investor types (Angel, VC, Corporate, Government)
- ✅ Track investment types (Equity, Debt, Grant)
- ✅ Store proof documents
- ✅ Calculate equity allocations

### 2. Founders Management
- ✅ Add/remove founders
- ✅ Track founder equity percentages
- ✅ Real-time updates

### 3. Fundraising Management
- ✅ Active fundraising rounds
- ✅ Validation requests
- ✅ Pitch deck and video uploads
- ✅ Round type tracking

### 4. Valuation History
- ✅ Track valuation changes over time
- ✅ Investment round valuations
- ✅ Historical data for charts

### 5. Equity Holdings
- ✅ Real-time equity distribution
- ✅ Founder vs investor ownership
- ✅ ESOP tracking

### 6. Analytics and Reporting
- ✅ Investment summary cards
- ✅ Valuation history charts
- ✅ Equity distribution pie charts
- ✅ Funding breakdown by type

## 🔒 Security Features

### Row-Level Security (RLS)
- Users can only access their own startup's data
- Secure file uploads with startup-specific folders
- Automatic data isolation

### Data Validation
- Investment amounts must be positive
- Equity allocations must be valid percentages
- Date validations for all records

## 🚀 Next Steps

### 1. Update CapTableTab Component
Replace the mock data functions in `CapTableTab.tsx` with real service calls:

```typescript
// Replace generateMockInvestors with:
const investments = await capTableService.getInvestmentRecords(startup.id);

// Replace generateValuationData with:
const valuationData = await capTableService.getValuationHistoryData(startup.id);

// Replace static equity data with:
const equityData = await capTableService.getEquityDistributionData(startup.id);
```

### 2. Add Real-time Updates
Implement real-time subscriptions to automatically refresh the UI when data changes.

### 3. Add Error Handling
Implement proper error handling and loading states for all async operations.

### 4. Add File Upload UI
Create file upload components for investment proofs and pitch decks.

## 🧪 Testing

### 1. Database Functions
Test all RPC functions work correctly:
```sql
SELECT * FROM get_investment_summary(1);
SELECT * FROM get_valuation_history(1);
SELECT * FROM get_equity_distribution(1);
SELECT * FROM get_fundraising_status(1);
```

### 2. Frontend Integration
Test all CRUD operations work from the frontend:
- Add investment records
- Update founders
- Manage fundraising details
- Upload files

### 3. Real-time Features
Test that UI updates automatically when data changes in the database.

## 📊 Data Flow

```
Frontend (CapTableTab.tsx)
    ↓
Service Layer (capTableService.ts)
    ↓
Supabase Client (supabase.ts)
    ↓
PostgreSQL Database
    ↓
Real-time Subscriptions
    ↓
Frontend Updates
```

## 🎨 UI Components to Update

1. **Summary Cards**: Connect to `getInvestmentSummary()`
2. **Valuation Chart**: Connect to `getValuationHistoryData()`
3. **Equity Pie Chart**: Connect to `getEquityDistributionData()`
4. **Investment Form**: Connect to `addInvestmentRecord()`
5. **Investor List**: Connect to `getInvestmentRecords()`
6. **Founders Section**: Connect to `getFounders()` and `updateFounders()`
7. **Fundraising Section**: Connect to `getFundraisingDetails()` and `updateFundraisingDetails()`

## 🔧 Troubleshooting

### Common Issues

1. **RLS Policy Errors**: Ensure user is authenticated and has access to the startup
2. **Foreign Key Errors**: Ensure startup exists before adding related records
3. **File Upload Errors**: Check storage bucket exists and policies are correct
4. **RPC Function Errors**: Check function signatures match expected types

### Debug Commands

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Check RPC functions
SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public';

-- Check storage bucket
SELECT * FROM storage.buckets WHERE id = 'cap-table-documents';
```

## 📈 Performance Considerations

1. **Indexes**: All tables have proper indexes for startup_id lookups
2. **Pagination**: Consider adding pagination for large investment lists
3. **Caching**: Implement client-side caching for frequently accessed data
4. **Optimistic Updates**: Use optimistic updates for better UX

---

**Ready to implement!** Follow this guide step by step to integrate the Cap Table module with your frontend. The backend is fully set up and ready to use.
