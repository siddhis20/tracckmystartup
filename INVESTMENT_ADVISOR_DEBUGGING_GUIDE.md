# Investment Advisor Debugging Guide

## 🚫 **Subscription Errors Are NOT the Issue**

The errors you're seeing:
```
GET https://dlesebbmlrewsbmqvuza.supabase.co/rest/v1/user_subscriptions?select=*%2Csubscription_plans%28price%2Cinterval%29&user_id=eq.5c2987d7-6b47-45ce-89d2-1c5b9181684b&status=eq.active 406 (Not Acceptable)
```

**These are subscription-related errors (406 Not Acceptable) and are completely unrelated to the investment advisor code functionality.**

## 🔍 **Real Issue: Startup Visibility in Investment Advisor Dashboard**

The startup visibility issue is likely due to one of these factors:

### **1. Data Loading Issue**
- Investment Advisor might not be getting all startups
- The `getAllStartupsForInvestmentAdvisor()` function might not be working

### **2. Code Matching Issue**
- Investment advisor codes might not be matching correctly
- Field names might be different than expected

### **3. Database Field Issue**
- The `advisor_accepted` field might not exist in the database
- This would cause the filtering logic to fail

## 🧪 **Debugging Steps**

### **Step 1: Check Browser Console**
Look for the debug output that should show:
```javascript
🔍 Investment Advisor Debug: {
  currentUserCode: "IA-123456",
  totalUsers: 25,
  totalStartups: 150,
  pendingInvestorRequests: 3,
  pendingStartupRequests: 2,  // This should show startups with matching codes
  myInvestors: 5,
  myStartups: 1,
  
  // Key debug information:
  allUsersWithCodes: [...],  // Users with matching investment advisor codes
  startupUserRelationships: [...],  // How startups link to users
  pendingStartupDetails: [...],  // Details of pending startup requests
  sampleUserFields: [...]  // Check if advisor_accepted field exists
}
```

### **Step 2: Verify Data Flow**
Check these key points in the debug output:

1. **Current User Code**: Does `currentUserCode` show the correct investment advisor code?
2. **Users with Codes**: Does `allUsersWithCodes` show users with matching codes?
3. **Startup Relationships**: Does `startupUserRelationships` show proper linking?
4. **Field Existence**: Does `sampleUserFields` show if `advisor_accepted` field exists?

### **Step 3: Database Verification**
Run this SQL query in Supabase to verify the data:

```sql
-- Check if users have investment advisor codes
SELECT 
    id,
    name,
    email,
    role,
    investment_advisor_code_entered,
    advisor_accepted
FROM users 
WHERE investment_advisor_code_entered IS NOT NULL
ORDER BY role, name;

-- Check startup-user relationships
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    s.user_id,
    u.name as user_name,
    u.role,
    u.investment_advisor_code_entered,
    u.advisor_accepted
FROM startups s
JOIN users u ON s.user_id = u.id
WHERE u.investment_advisor_code_entered IS NOT NULL
ORDER BY s.name;
```

## 🔧 **Potential Fixes**

### **Fix 1: If `advisor_accepted` field doesn't exist**
If the debug shows `hasAdvisorAccepted: false`, then we need to modify the filtering logic to not rely on this field.

### **Fix 2: If codes don't match**
If `allUsersWithCodes` is empty, then the investment advisor codes aren't matching correctly.

### **Fix 3: If startup-user relationships are broken**
If `startupUserRelationships` shows `userFound: false`, then the linking between startups and users is broken.

## 📊 **Expected Debug Output**

If everything is working correctly, you should see:

```javascript
🔍 Investment Advisor Debug: {
  currentUserCode: "IA-123456",
  totalUsers: 25,
  totalStartups: 150,
  pendingInvestorRequests: 3,
  pendingStartupRequests: 2,  // Should show startups with matching codes
  myInvestors: 5,
  myStartups: 1,
  
  allUsersWithCodes: [
    {
      userId: "user-123",
      userName: "John Investor",
      userEmail: "john@investor.com",
      userRole: "Investor",
      code: "IA-123456",
      accepted: false
    },
    {
      userId: "user-456",
      userName: "Jane Startup",
      userEmail: "jane@startup.com",
      userRole: "Startup",
      code: "IA-123456",
      accepted: false
    }
  ],
  
  startupUserRelationships: [
    {
      startupId: 789,
      startupName: "TechStartup Inc",
      startupUserId: "user-456",
      userFound: true,
      userCode: "IA-123456",
      userAccepted: false,
      matchesCurrentCode: true
    }
  ],
  
  pendingStartupDetails: [
    {
      startupId: 789,
      startupName: "TechStartup Inc",
      startupUserId: "user-456",
      userCode: "IA-123456",
      userAccepted: false
    }
  ],
  
  sampleUserFields: [
    {
      userId: "user-123",
      userName: "John Investor",
      userRole: "Investor",
      hasAdvisorAccepted: true,  // This should be true if field exists
      advisorAcceptedValue: false,
      allFields: ["id", "name", "email", "role", "investment_advisor_code_entered", "advisor_accepted"]
    }
  ]
}
```

## 🚀 **Next Steps**

1. **Check the browser console** for the debug output
2. **Share the debug output** so we can identify the exact issue
3. **Run the SQL queries** to verify the database data
4. **Apply the appropriate fix** based on what we find

The subscription errors are a red herring - the real issue is in the investment advisor code matching and filtering logic! 🎯
