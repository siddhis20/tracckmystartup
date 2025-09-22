# Investment Advisor Startup Visibility Fix

## 🐛 **Root Cause Identified**

The issue was that Investment Advisors were not seeing startups in the "My Startup Offers" table because of **incorrect data loading logic**.

### **Problem Analysis**

1. **Data Loading Issue**: Investment Advisors were using `startupService.getAllStartups()` which only fetches startups belonging to the current user (`eq('user_id', user.id)`)

2. **Wrong Data Source**: Investment Advisors need to see ALL startups that have entered their investment advisor code, not just their own startups

3. **Field Name Confusion**: The filtering logic was using the wrong field name (`investment_advisor_code` instead of `investment_advisor_code_entered`)

## 🔧 **Fixes Applied**

### **1. Created New Service Function**
Added `getAllStartupsForInvestmentAdvisor()` in `lib/database.ts`:
```typescript
// Get all startups (for investment advisor users)
async getAllStartupsForInvestmentAdvisor() {
  console.log('Fetching all startups for investment advisor...');
  try {
    const { data, error } = await supabase
      .from('startups')
      .select(`
        *,
        founders (*)
      `)
      .order('created_at', { ascending: false })
    // ... rest of the function
  }
}
```

### **2. Updated App.tsx Data Loading**
Modified the data fetching logic to use the new service for Investment Advisors:
```typescript
// Use role-specific startup fetching
currentUserRef.current?.role === 'Admin' 
  ? startupService.getAllStartupsForAdmin() 
  : currentUserRef.current?.role === 'Investment Advisor'
  ? startupService.getAllStartupsForInvestmentAdvisor()  // NEW!
  : currentUserRef.current?.role === 'CA'
  ? caService.getAssignedStartups()...
  // ... rest of the conditions
```

### **3. Fixed Field Name in Filtering**
Updated the filtering logic to use the correct field name:
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

### **4. Fixed Syntax Errors**
Resolved compilation errors in `InvestmentAdvisorView.tsx`:
- Fixed missing parentheses in map functions
- Corrected indentation issues
- Removed duplicate variable declarations

### **5. Enhanced Debug Logging**
Added comprehensive debug logging to track:
- Total startups loaded
- Startups with investment advisor codes
- Sample startup data with codes
- All startups with codes and acceptance status

## 🧪 **Testing Results**

### **Expected Behavior**
- ✅ Investment Advisors should now see ALL startups in the system
- ✅ Startups that have entered the advisor's code should appear in "My Startup Offers"
- ✅ Debug console should show detailed startup data
- ✅ Proper filtering based on investment advisor codes

### **Debug Information**
The debug console will now show:
```javascript
🔍 Investment Advisor Debug: {
  currentUserCode: "IA-123456",
  totalUsers: 25,
  totalStartups: 150,  // Should now show ALL startups
  pendingInvestorRequests: 3,
  pendingStartupRequests: 2,  // Should now show startups with codes
  myInvestors: 5,
  myStartups: 1,
  // ... more debug info
  allStartupsWithCodes: [
    {
      id: 123,
      name: "TechStartup Inc",
      code: "IA-123456",
      accepted: false
    }
    // ... more startups
  ]
}
```

## 🚀 **Key Changes Summary**

1. **Data Loading**: Investment Advisors now fetch ALL startups instead of just their own
2. **Field Names**: Corrected field name from `investment_advisor_code` to `investment_advisor_code_entered`
3. **Service Layer**: Added dedicated service function for Investment Advisor data loading
4. **Debug Tools**: Enhanced logging and created SQL debug script for troubleshooting

## 📊 **Expected Results**

After these fixes:
- ✅ Startups with investment advisor codes should appear in "My Startup Offers"
- ✅ Investment Advisors can see all startups in the system
- ✅ Proper filtering and acceptance workflow should work
- ✅ Debug information should be available for troubleshooting

The Investment Advisor dashboard should now correctly display startup requests! 🚀

## 🔍 **Additional Debugging**

If startups still don't appear, run the SQL debug script:
```sql
-- Execute DEBUG_STARTUP_INVESTMENT_ADVISOR_CODES.sql
-- This will show:
-- 1. Column structure in both tables
-- 2. All startups with investment advisor codes
-- 3. Data comparison between startups and users tables
```

The issue was fundamentally about data access - Investment Advisors need to see all startups, not just their own! 🎯
