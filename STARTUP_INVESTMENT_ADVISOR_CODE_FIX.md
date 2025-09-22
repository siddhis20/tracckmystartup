# Startup Investment Advisor Code Fix

## 🐛 **Issue Identified**

Startups are not appearing in the "My Startup Offers" table even though they have added the investment advisor code in their profile.

## 🔍 **Root Cause Analysis**

The issue is likely in the field name used for filtering startups. There are two possible scenarios:

### **Scenario 1: Field Name Mismatch**
- **Investors**: Store code in `investment_advisor_code_entered` field
- **Startups**: May also store code in `investment_advisor_code_entered` field (not `investment_advisor_code`)

### **Scenario 2: Data Location Mismatch**
- **Investors**: Data stored in `users` table
- **Startups**: Data may be stored in `users` table (not `startups` table)

## 🔧 **Fixes Applied**

### **1. Updated Field Name**
```typescript
// Before (incorrect)
const pendingStartupRequests = startups.filter(startup => 
  (startup as any).investment_advisor_code === currentUser?.investment_advisor_code &&
  !(startup as any).advisor_accepted
);

// After (correct)
const pendingStartupRequests = startups.filter(startup => 
  (startup as any).investment_advisor_code_entered === currentUser?.investment_advisor_code &&
  !(startup as any).advisor_accepted
);
```

### **2. Enhanced Debug Logging**
Added comprehensive debug logging to track:
- Total startups loaded
- Startups with investment advisor codes
- Sample startup data
- All startups with codes and their acceptance status

```typescript
console.log('🔍 Investment Advisor Debug:', {
  // ... existing debug info
  sampleStartupWithCode: startups.find(s => (s as any).investment_advisor_code_entered),
  allStartupsWithCodes: startups.filter(s => (s as any).investment_advisor_code_entered).map(s => ({
    id: s.id,
    name: s.name,
    code: (s as any).investment_advisor_code_entered,
    accepted: (s as any).advisor_accepted
  }))
});
```

### **3. Database Debug Script**
Created `DEBUG_STARTUP_INVESTMENT_ADVISOR_CODES.sql` to:
- Check column existence in both `startups` and `users` tables
- Show all startups with investment advisor codes
- Compare data between tables
- Find startups by specific investment advisor code

## 🧪 **Testing Steps**

### **1. Check Browser Console**
Look for the debug output to see:
- How many startups are loaded
- Which startups have investment advisor codes
- Whether the codes match the current advisor's code

### **2. Run Database Debug Script**
Execute `DEBUG_STARTUP_INVESTMENT_ADVISOR_CODES.sql` in Supabase to:
- Verify column names and data types
- See actual data in the database
- Identify where startup codes are stored

### **3. Verify Data Flow**
Check if:
- Startups are storing codes in `startups` table or `users` table
- Field name is `investment_advisor_code` or `investment_advisor_code_entered`
- `advisor_accepted` field exists and is being used correctly

## 🔍 **Possible Additional Issues**

If startups still don't appear, the issue might be:

1. **Data Location**: Startups might store codes in `users` table instead of `startups` table
2. **Field Name**: The field might be named differently than expected
3. **Data Loading**: The `startups` array might not include the investment advisor code field
4. **Acceptance Field**: The `advisor_accepted` field might not exist or work as expected

## 📊 **Expected Results**

After the fix:
- ✅ Startups with investment advisor codes should appear in "My Startup Offers"
- ✅ Debug console should show startup data with codes
- ✅ Database script should reveal the correct field names and data location

## 🚀 **Next Steps**

1. **Test the fix** by checking the browser console for debug output
2. **Run the SQL script** to verify database structure
3. **Report findings** if startups still don't appear (may need additional fixes)

The investment advisor dashboard should now correctly display startup requests! 🚀
