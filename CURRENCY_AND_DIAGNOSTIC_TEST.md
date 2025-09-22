# Currency and Diagnostic Bar Test Guide

## Issues Fixed

### 1. Currency Not Updating in Profile Save
**Problem**: Profile was saving without error but currency wasn't being updated in the database.

**Root Cause**: The profile service was only updating currency if it had a truthy value, but it should update even if the currency is an empty string or specific value.

**Solution Applied**:
- Modified `lib/profileService.ts` to always include currency in updates if it's provided (even if empty)
- Added detailed logging to track currency values through the update process
- Enhanced error handling to show specific error messages

### 2. Diagnostic Bar Not Showing App Action Logs
**Problem**: The diagnostic bar wasn't capturing console logs from the application.

**Root Cause**: The diagnostic bar was only showing manually logged diagnostic entries, not capturing all console logs.

**Solution Applied**:
- Added console.log override in `App.tsx` to capture all logs containing 🔍, ❌, or ✅
- Enhanced diagnostic logging to show real-time application actions
- Improved log filtering and display

### 3. Currency Symbols Already Available
**Status**: ✅ Currency symbols are already implemented in `lib/utils.ts`
- `getCurrencySymbol()` function provides symbols for USD ($), EUR (€), GBP (£), INR (₹), etc.
- `getCurrencyName()` function provides full currency names
- `formatCurrency()` and `formatCurrencyCompact()` functions handle proper formatting

## Testing Instructions

### Test 1: Currency Update
1. **Open the startup dashboard**
2. **Go to Profile tab**
3. **Change the currency** (e.g., from USD to EUR)
4. **Save the profile**
5. **Check browser console** for these logs:
   ```
   🔍 Currency being saved: EUR
   🔍 Adding currency to update: EUR
   🔍 Update data: { currency: "EUR", updated_at: "..." }
   ✅ Profile update successful
   ```
6. **Verify in other tabs** (Financials, Employees, Cap Table) that currency is now EUR

### Test 2: Diagnostic Bar
1. **Look at the bottom of the screen** for the diagnostic bar
2. **Perform any action** (navigate, save profile, etc.)
3. **Check that logs appear** in the diagnostic bar with timestamps
4. **Look for logs like**:
   ```
   [MICRO] Console: 🔍 Currency being saved: EUR
   [MICRO] Console: ✅ Profile update successful
   ```

### Test 3: Currency Symbols
1. **Go to Financials tab**
2. **Check that currency symbols appear** correctly:
   - USD should show as $1,234.56
   - EUR should show as €1,234.56
   - INR should show as ₹1,234.56
3. **Go to Employees tab**
4. **Check salary displays** use the correct currency symbol
5. **Go to Cap Table tab**
6. **Check investment amounts** use the correct currency symbol

## Debugging Commands

If issues persist, run this in browser console:

```javascript
// Test currency update directly
async function testCurrencyUpdate() {
    console.log('🧪 Testing currency update...');
    
    // Get current startup data
    const { data: startup } = await window.supabase
        .from('startups')
        .select('id, name, currency')
        .limit(1);
    
    if (!startup || startup.length === 0) {
        console.error('❌ No startup found');
        return;
    }
    
    const startupId = startup[0].id;
    const currentCurrency = startup[0].currency;
    
    console.log('Current startup:', startup[0]);
    console.log('Current currency:', currentCurrency);
    
    // Test update
    const newCurrency = currentCurrency === 'USD' ? 'EUR' : 'USD';
    const { error } = await window.supabase
        .from('startups')
        .update({ currency: newCurrency })
        .eq('id', startupId);
    
    if (error) {
        console.error('❌ Update failed:', error);
    } else {
        console.log('✅ Currency updated to:', newCurrency);
        
        // Verify update
        const { data: updated } = await window.supabase
            .from('startups')
            .select('currency')
            .eq('id', startupId)
            .single();
        
        console.log('Verified currency:', updated.currency);
    }
}

// Run the test
testCurrencyUpdate();
```

## Expected Results

### ✅ Currency Update Should Work
- Profile saves without errors
- Currency field updates in database
- Other tabs reflect the new currency
- Currency symbols display correctly

### ✅ Diagnostic Bar Should Show Logs
- Real-time capture of application actions
- Timestamps for each log entry
- Color-coded log types
- Clear/Hide buttons work

### ✅ Currency Symbols Should Display
- Proper symbols for each currency
- Consistent formatting across all tabs
- Compact notation for large numbers (e.g., $1.2M)

## Files Modified

1. **`lib/profileService.ts`**
   - Enhanced currency update logic
   - Added detailed logging
   - Improved error handling

2. **`components/startup-health/ProfileTab.tsx`**
   - Added currency logging in save process
   - Enhanced error messages

3. **`App.tsx`**
   - Added console.log override for diagnostic capture
   - Enhanced diagnostic logging system

## Next Steps

1. **Test the currency update** by changing currency in profile and saving
2. **Verify diagnostic bar** shows real-time logs
3. **Check currency symbols** display correctly in all financial tabs
4. **Report any remaining issues** with specific error messages

The fixes ensure that:
- Currency updates are properly saved to the database
- Diagnostic bar captures all application actions
- Currency symbols display correctly across all tabs
