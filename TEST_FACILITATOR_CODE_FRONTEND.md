# Frontend Test Guide for Facilitator Code System

## 🔧 Fix Applied

The import error has been fixed by changing:
```typescript
// OLD (causing error)
import { supabase } from './database';

// NEW (correct)
import { supabase } from './supabase';
```

## 🧪 Testing Steps

### 1. Check Browser Console
- **Open Developer Tools** (F12)
- **Check Console tab** for any remaining errors
- **The import error should be gone**

### 2. Test Facilitator Code Display
1. **Login as a facilitator** (Startup Facilitation Center role)
2. **Check the header** - should show facilitator code beside logout button
3. **Verify styling** matches the image

### 3. Test Database Connection
1. **Run the SQL script** `FACILITATOR_CODE_SYSTEM.sql` in Supabase
2. **Run the test script** `TEST_FACILITATOR_CODE.sql` to verify database setup
3. **Check that facilitators have codes assigned**

## 🚨 Common Issues & Solutions

### Issue 1: Import Error (Fixed)
```
The requested module '/lib/database.ts' does not provide an export named 'supabase'
```
**Solution**: ✅ Fixed - Changed import to use `./supabase`

### Issue 2: Tailwind Warning
```
cdn.tailwindcss.com should not be used in production
```
**Solution**: This is just a warning, not an error. The app will still work.

### Issue 3: No Facilitator Code Displayed
**Possible causes**:
1. **User is not a facilitator** - Check user role is "Startup Facilitation Center"
2. **Database not set up** - Run the SQL script
3. **No facilitator code assigned** - Check database

### Issue 4: Loading State Stuck
**Possible causes**:
1. **Network error** - Check browser console
2. **RPC function not found** - Verify SQL script ran successfully
3. **User ID not found** - Check authentication

## 🔍 Debug Steps

### Check User Role
```javascript
// In browser console
console.log('Current user:', currentUser);
console.log('User role:', currentUser?.role);
```

### Check Database Functions
```sql
-- In Supabase SQL Editor
SELECT routine_name FROM information_schema.routines 
WHERE routine_name LIKE '%facilitator%';
```

### Check Facilitator Codes
```sql
-- In Supabase SQL Editor
SELECT name, email, facilitator_code 
FROM users 
WHERE role = 'Startup Facilitation Center';
```

## ✅ Expected Result

After fixing the import and running the SQL script:

1. **No console errors** related to imports
2. **Facilitator code displays** in header beside logout button
3. **Styling matches** the image you provided
4. **Code format**: "FAC-XXXXXX" (6 random characters)

## 🎯 Next Steps

1. **Run the SQL script** if not done already
2. **Test with a facilitator account**
3. **Verify the code appears in header**
4. **Check that styling matches your design**

The import error should now be resolved! 🎉
