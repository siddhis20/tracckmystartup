# Currency Save Fix - Implementation Instructions

## Problem
When startup chooses currency in profile tab, it was not updating when saved.

## Root Cause
1. **Missing Database Column**: The `currency` field was not present in the `startups` table
2. **Missing Profile Service Support**: The profile service was not handling the currency field
3. **Missing Profile Update**: The ProfileTab was not passing currency in the onProfileUpdate call

## Solution Implemented

### 1. Database Schema Update
**File**: `ADD_CURRENCY_TO_STARTUPS.sql`
- Added `currency` column to `startups` table
- Set default value to 'USD'
- Added proper documentation

**To Apply**: Run the SQL script in Supabase SQL Editor

### 2. Profile Service Updates
**File**: `lib/profileService.ts`
- Updated `getStartupProfile()` to include currency field with fallback to 'USD'
- Updated `updateStartupProfile()` to handle currency parameter in all update paths:
  - RPC function calls (`update_startup_profile_simple` and `update_startup_profile`)
  - Direct database updates

### 3. ProfileTab Updates
**File**: `components/startup-health/ProfileTab.tsx`
- Added currency field to the `onProfileUpdate` call
- Ensures currency changes are propagated to other tabs

### 4. Currency Hook
**File**: `lib/hooks/useStartupCurrency.ts`
- Created reusable hook to get startup currency
- Provides fallback to 'USD' if no currency is set

## Testing Steps

1. **Add Database Column**:
   ```sql
   -- Run in Supabase SQL Editor
   ALTER TABLE public.startups 
   ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'USD';
   ```

2. **Test Currency Selection**:
   - Go to Profile tab in startup dashboard
   - Change currency from dropdown
   - Click Save
   - Verify currency is saved and reflected in other tabs

3. **Verify Cross-Tab Consistency**:
   - Check Financials tab shows correct currency
   - Check Employees tab shows correct currency  
   - Check Cap Table tab shows correct currency

## Expected Behavior

✅ **Profile Tab**: Currency selection saves properly
✅ **Financials Tab**: All amounts display in selected currency
✅ **Employees Tab**: Salaries and ESOP allocations in selected currency
✅ **Cap Table Tab**: Investment amounts and valuations in selected currency
✅ **Real-time Updates**: Currency changes immediately reflect across all tabs

## Supported Currencies
- USD (US Dollar)
- EUR (Euro)
- GBP (British Pound)
- INR (Indian Rupee)
- CAD (Canadian Dollar)
- AUD (Australian Dollar)
- JPY (Japanese Yen)
- CHF (Swiss Franc)
- SGD (Singapore Dollar)
- CNY (Chinese Yuan)

## Files Modified
- `lib/profileService.ts` - Added currency support to profile operations
- `components/startup-health/ProfileTab.tsx` - Include currency in profile updates
- `lib/hooks/useStartupCurrency.ts` - Created currency hook
- `components/startup-health/FinancialsTab.tsx` - Use startup currency
- `components/startup-health/EmployeesTab.tsx` - Use startup currency
- `components/startup-health/CapTableTab.tsx` - Use startup currency

## Database Changes Required
Run the SQL script `ADD_CURRENCY_TO_STARTUPS.sql` in Supabase SQL Editor to add the currency column to the startups table.
