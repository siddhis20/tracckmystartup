# Profile Update Fix Guide

## Problem
"Failed to update profile" error when trying to save profile changes, particularly when currency is involved.

## Root Cause
The issue was caused by:
1. **Missing Database Column**: The `currency` column didn't exist in the `startups` table
2. **Outdated RPC Functions**: The database RPC functions didn't support the `currency_param` parameter
3. **Incomplete Error Handling**: The profile service wasn't handling missing database columns gracefully

## Solution Implemented

### 1. Database Schema Updates
**File**: `FIX_PROFILE_UPDATE_CURRENCY.sql`

**Changes Made**:
- Added `currency` column to `startups` table with default value 'USD'
- Updated `update_startup_profile_simple` function to support `currency_param`
- Updated `update_startup_profile` function to support `currency_param`
- Updated `get_startup_profile_simple` function to include currency in response
- Added proper error handling and fallbacks

### 2. Profile Service Updates
**File**: `lib/profileService.ts`

**Changes Made**:
- Enhanced `updateStartupProfile()` with robust error handling
- Added fallback logic for missing currency column
- Improved direct database update with retry mechanism
- Added currency parameter to RPC function calls
- Enhanced `getStartupProfile()` to handle currency field

### 3. Error Handling Improvements
- **Graceful Degradation**: If currency column doesn't exist, falls back to USD
- **Retry Logic**: If update fails due to missing column, retries without currency
- **Comprehensive Logging**: Added detailed console logs for debugging
- **Fallback Chain**: RPC functions → Direct update → Retry without currency

## How to Apply the Fix

### Step 1: Run Database Migration
Execute the SQL script in Supabase SQL Editor:

```sql
-- Copy and paste the contents of FIX_PROFILE_UPDATE_CURRENCY.sql
-- This will add the currency column and update all RPC functions
```

### Step 2: Verify the Fix
1. **Test Profile Update**:
   - Go to Profile tab in startup dashboard
   - Change any field (country, company type, currency)
   - Click Save
   - Verify success message appears

2. **Test Currency Selection**:
   - Change currency in profile
   - Save profile
   - Check other tabs (Financials, Employees, Cap Table) show correct currency

3. **Check Browser Console**:
   - Look for success messages like "✅ Profile updated successfully"
   - No error messages should appear

## Expected Behavior After Fix

✅ **Profile Updates Work**: All profile fields can be saved successfully  
✅ **Currency Selection**: Currency dropdown saves and persists  
✅ **Cross-Tab Consistency**: Currency changes reflect in all financial tabs  
✅ **Error Handling**: Graceful fallbacks if database issues occur  
✅ **Logging**: Clear console messages for debugging  

## Troubleshooting

### If Profile Update Still Fails:

1. **Check Database Connection**:
   ```javascript
   // In browser console
   console.log('Supabase client:', window.supabase);
   ```

2. **Verify RPC Functions**:
   ```sql
   -- In Supabase SQL Editor
   SELECT routine_name, routine_definition 
   FROM information_schema.routines 
   WHERE routine_name LIKE '%startup_profile%';
   ```

3. **Check Column Exists**:
   ```sql
   -- In Supabase SQL Editor
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'startups' 
   AND column_name = 'currency';
   ```

### Common Issues and Solutions:

| Issue | Solution |
|-------|----------|
| "currency column doesn't exist" | Run the SQL migration script |
| "RPC function not found" | Check if functions were created successfully |
| "Permission denied" | Verify RLS policies allow updates |
| "Currency not saving" | Check if currency field is included in form data |

## Files Modified

### Database
- `FIX_PROFILE_UPDATE_CURRENCY.sql` - Complete database migration

### Application Code
- `lib/profileService.ts` - Enhanced profile service with currency support
- `components/startup-health/ProfileTab.tsx` - Include currency in profile updates
- `lib/hooks/useStartupCurrency.ts` - Currency hook for consistent access

### Financial Tabs
- `components/startup-health/FinancialsTab.tsx` - Use startup currency
- `components/startup-health/EmployeesTab.tsx` - Use startup currency  
- `components/startup-health/CapTableTab.tsx` - Use startup currency

## Testing Checklist

- [ ] Profile tab loads without errors
- [ ] Currency dropdown shows all supported currencies
- [ ] Profile save works for all fields
- [ ] Currency selection persists after save
- [ ] Financials tab shows correct currency
- [ ] Employees tab shows correct currency
- [ ] Cap Table tab shows correct currency
- [ ] No console errors during profile operations
- [ ] Cross-tab currency consistency maintained

## Support

If issues persist after applying this fix:
1. Check browser console for specific error messages
2. Verify database migration was successful
3. Test with a fresh browser session
4. Check Supabase logs for server-side errors
