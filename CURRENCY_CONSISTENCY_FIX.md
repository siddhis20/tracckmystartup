# Currency Consistency Fix - Implementation Guide

## 🐛 **Problem Identified**
The system has a currency consistency bug where:
- Users can select their preferred currency (USD, INR, EUR, etc.) in the profile
- But all financial displays across dashboards still show USD only
- This creates confusion and inconsistency

## 🎯 **Solution Overview**
We need to:
1. **Create a centralized currency context/hook** that gets the user's selected currency
2. **Update all hardcoded USD references** to use the user's currency
3. **Ensure consistent currency display** across all components
4. **Add proper currency conversion** if needed

## 📋 **Files That Need Updates**

### **1. AdminView.tsx** - Line 46
**Current (Hardcoded USD):**
```typescript
const formatCurrency = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact' }).format(value);
```

**Fix:**
```typescript
const formatCurrency = (value: number, currency: string = 'USD') => new Intl.NumberFormat('en-US', { style: 'currency', currency: currency, notation: 'compact' }).format(value);
```

### **2. InvestorService.ts** - Lines 148-156
**Current (Hardcoded USD):**
```typescript
formatCurrency(amount: number): string {
  if (amount >= 1000000) {
    return `$${(amount / 1000000).toFixed(1)}M`;
  } else if (amount >= 1000) {
    return `$${(amount / 1000).toFixed(1)}K`;
  } else {
    return `$${amount.toLocaleString()}`;
  }
}
```

**Fix:**
```typescript
formatCurrency(amount: number, currency: string = 'USD'): string {
  const symbol = getCurrencySymbol(currency);
  if (amount >= 1000000) {
    return `${symbol}${(amount / 1000000).toFixed(1)}M`;
  } else if (amount >= 1000) {
    return `${symbol}${(amount / 1000).toFixed(1)}K`;
  } else {
    return `${symbol}${amount.toLocaleString()}`;
  }
}
```

### **3. All Dashboard Components**
Need to use the startup's currency instead of hardcoded USD.

## 🛠️ **Implementation Steps**

### **Step 1: Create Currency Context**
Create a context that provides the current user's currency preference.

### **Step 2: Update All Components**
Replace hardcoded USD with dynamic currency from context.

### **Step 3: Update Service Functions**
Modify all service functions to accept currency parameter.

### **Step 4: Test Currency Consistency**
Verify that changing currency in profile updates all displays.

## 🎯 **Expected Result**
- ✅ User selects INR in profile → All dashboards show ₹ (Rupees)
- ✅ User selects EUR in profile → All dashboards show € (Euros)  
- ✅ User selects USD in profile → All dashboards show $ (Dollars)
- ✅ Consistent currency across all financial displays
- ✅ Real-time updates when currency is changed

## 📊 **Components to Update**
1. **AdminView** - Investment offers, analytics
2. **InvestorView** - Investment amounts, valuations
3. **StartupDashboardTab** - Financial metrics
4. **CapTableTab** - Share values, investments
5. **FinancialsTab** - Revenue, expenses
6. **EmployeesTab** - Salaries, ESOP values
7. **All Service Functions** - Currency formatting

This fix will ensure complete currency consistency across the entire application.

