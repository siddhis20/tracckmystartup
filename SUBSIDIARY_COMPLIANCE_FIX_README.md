# Subsidiary Compliance Fix

## Problem
Subsidiaries were not generating compliance tasks properly because the `subsidiaries` table was missing the `company_type` column that the compliance task generation function expects.

## Root Cause
The compliance task generation function in `FIX_GENERATE_COMPLIANCE_TASKS.sql` tries to access `sub_rec.company_type` from the subsidiaries table, but this column didn't exist, causing silent failures in subsidiary compliance task generation.

## Solution
This fix adds the missing columns and updates the necessary functions to make subsidiary compliance work exactly like the primary company compliance.

## Files Created
1. **`FIX_SUBSIDIARY_COMPLIANCE_ISSUES.sql`** - Main fix script
2. **`TEST_SUBSIDIARY_COMPLIANCE_FIX.sql`** - Test script to verify the fix
3. **`SUBSIDIARY_COMPLIANCE_FIX_README.md`** - This documentation

## What the Fix Does

### 1. Adds Missing Columns
- **`subsidiaries.company_type`** - Required for compliance rule matching
- **`subsidiaries.user_id`** - For proper ownership tracking
- **`subsidiaries.profile_updated_at`** - For tracking changes
- **`international_ops.company_type`** - Same as subsidiaries
- **`international_ops.user_id`** - Same as subsidiaries
- **`international_ops.profile_updated_at`** - Same as subsidiaries

### 2. Updates Functions
- **`add_subsidiary()`** - Now includes company_type parameter
- **`update_subsidiary()`** - Now handles company_type updates
- **`add_international_op()`** - Now includes company_type parameter
- **`update_international_op()`** - Now handles company_type updates
- **`get_startup_profile()`** - Now returns company_type for subsidiaries and international ops

### 3. Adds Performance Indexes
- Indexes on `company_type` columns for faster queries
- Indexes on `user_id` columns for ownership checks
- Indexes on `profile_updated_at` columns for change tracking

### 4. Updates Security Policies
- Row Level Security (RLS) policies now include user_id checks
- Proper ownership-based access control

## How to Apply the Fix

### Step 1: Run the Fix Script
```sql
-- Run this in your Supabase SQL Editor
\i FIX_SUBSIDIARY_COMPLIANCE_ISSUES.sql
```

### Step 2: Verify the Fix
```sql
-- Run this to test that everything works
\i TEST_SUBSIDIARY_COMPLIANCE_FIX.sql
```

### Step 3: Test Compliance Task Generation
1. Go to your startup profile
2. Add a subsidiary with country and company type
3. Go to the compliance tab
4. Verify that compliance tasks are generated for the subsidiary

## Expected Results

After applying the fix:

1. **Subsidiaries will generate compliance tasks** based on their country and company type
2. **International operations will generate compliance tasks** based on their country and company type
3. **All compliance tasks will use admin-defined rules** from the `compliance_rules` table
4. **Fallback to default rules** when country-specific rules don't exist
5. **Real-time updates** when profile data changes

## Verification Checklist

- [ ] `subsidiaries` table has `company_type` column
- [ ] `subsidiaries` table has `user_id` column
- [ ] `international_ops` table has `company_type` column
- [ ] `international_ops` table has `user_id` column
- [ ] All functions updated to handle company_type
- [ ] Indexes created for performance
- [ ] RLS policies updated for security
- [ ] Compliance task generation works for subsidiaries
- [ ] Compliance task generation works for international operations

## Frontend Compatibility

The frontend components already support company type selection for subsidiaries and international operations, so no frontend changes are needed. The fix ensures that the backend properly stores and processes this data.

## Database Schema Changes

### Before Fix
```sql
-- subsidiaries table
CREATE TABLE subsidiaries (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER REFERENCES startups(id),
    country TEXT NOT NULL,
    registration_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### After Fix
```sql
-- subsidiaries table
CREATE TABLE subsidiaries (
    id SERIAL PRIMARY KEY,
    startup_id INTEGER REFERENCES startups(id),
    country TEXT NOT NULL,
    company_type TEXT NOT NULL DEFAULT 'C-Corporation',  -- ✅ ADDED
    registration_date DATE NOT NULL,
    user_id UUID REFERENCES auth.users(id),              -- ✅ ADDED
    profile_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- ✅ ADDED
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Troubleshooting

### If compliance tasks still don't generate for subsidiaries:
1. Check that the subsidiary has a valid `company_type`
2. Verify that compliance rules exist for the subsidiary's country
3. Check the database logs for any errors in the compliance task generation function

### If you get permission errors:
1. Ensure the user has proper RLS permissions
2. Check that the `user_id` is properly set for subsidiaries
3. Verify that the startup ownership is correct

## Support

If you encounter any issues with this fix, check:
1. The test script output for any errors
2. The Supabase logs for database errors
3. The browser console for frontend errors
4. The compliance task generation function logs

The fix is designed to be backward compatible and should not break any existing functionality.
