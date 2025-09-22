# Investment Advisor Implementation Fixes

## Issues Identified and Fixed

### 1. User Role Enum Error
**Problem**: 
```
ERROR: 22P02: invalid input value for enum user_role: "Investment Advisor"
```

**Root Cause**: 
The `user_role` enum in the database doesn't include "Investment Advisor" as a valid value.

**Fix Applied**:
- Added a DO block to safely add "Investment Advisor" to the `user_role` enum
- Used conditional logic to prevent errors if the value already exists
- Created a separate script (`ADD_INVESTMENT_ADVISOR_ENUM.sql`) for quick enum fix

### 2. Foreign Key Constraint Error
**Problem**: 
```
ERROR: 42804: foreign key constraint "investment_advisor_recommendations_investment_advisor_id_fkey" cannot be implemented
DETAIL: Key columns "investment_advisor_id" and "id" are of incompatible types: text and uuid.
```

**Root Cause**: 
The `users.id` column in Supabase is of type `UUID`, but I was trying to create foreign key references using `TEXT` columns.

**Fix Applied**:
- Changed all foreign key references from `TEXT` to `UUID` in the following tables:
  - `investment_advisor_recommendations`
  - `investment_advisor_relationships` 
  - `investment_advisor_commissions`
- Updated all function signatures to use `UUID` instead of `TEXT` for user ID parameters
- Updated all RLS policies to use `auth.uid()` directly instead of `auth.uid()::TEXT`

### 3. Email Verification Not Working
**Problem**: 
New users are no longer receiving verification emails after implementing the Investment Advisor changes.

**Root Cause**: 
The RLS (Row Level Security) policies on the `users` table were missing or too restrictive, preventing new user records from being created during registration. This would block the email verification flow.

**Fix Applied**:
- Added comprehensive RLS policies for the `users` table:
  - `Users can insert their own profile` - Allows users to create their own profile during registration
  - `Users can update their own profile` - Allows users to update their profile
  - `Users can view their own profile` - Allows users to view their own profile and related data
- Ensured RLS is properly enabled on the `users` table
- Made sure the policies allow the registration flow to complete successfully

## Files Updated

### 1. `ADD_INVESTMENT_ADVISOR_ENUM.sql`
- **Quick fix script** to add "Investment Advisor" to the user_role enum
- Run this first if you're getting the enum error
- Safe to run multiple times (won't create duplicates)

### 2. `INVESTMENT_ADVISOR_DATABASE_SETUP_FIXED.sql`
- **New file** with all fixes applied
- Corrected data types for all foreign key references
- Added proper RLS policies for user registration
- Includes enum fix and maintains all original functionality

### 3. `INVESTMENT_ADVISOR_DATABASE_SETUP.sql`
- **Original file** - contains the same fixes as the FIXED version
- Updated in place to resolve the issues

## Key Changes Made

### Enum Update
```sql
-- Add Investment Advisor to user_role enum
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'Investment Advisor' 
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_role')
    ) THEN
        ALTER TYPE user_role ADD VALUE 'Investment Advisor';
    END IF;
END $$;
```

### Database Schema Changes
```sql
-- Before (causing errors)
investment_advisor_id TEXT NOT NULL REFERENCES users(id)

-- After (fixed)
investment_advisor_id UUID NOT NULL REFERENCES users(id)
```

### RLS Policy Changes
```sql
-- Added critical policies for user registration
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (id = auth.uid());
```

### Function Signature Changes
```sql
-- Before
CREATE OR REPLACE FUNCTION get_investment_advisor_investors(advisor_id TEXT)

-- After  
CREATE OR REPLACE FUNCTION get_investment_advisor_investors(advisor_id UUID)
```

## Testing Recommendations

### 1. Database Setup
1. **First**: Run the `ADD_INVESTMENT_ADVISOR_ENUM.sql` script to add the enum value
2. **Then**: Run the `INVESTMENT_ADVISOR_DATABASE_SETUP_FIXED.sql` script in your Supabase SQL editor
3. Verify all tables are created without errors
4. Check that all foreign key constraints are properly established

### 2. User Registration Testing
1. Try registering a new user with any role
2. Verify that the verification email is sent
3. Complete the email verification process
4. Confirm the user can log in successfully

### 3. Investment Advisor Testing
1. Register a new user with "Investment Advisor" role
2. Verify that an Investment Advisor code is automatically generated
3. Test the Investment Advisor dashboard functionality
4. Test the recommendation system

### 4. Relationship Testing
1. Register an Investor with an Investment Advisor code
2. Register a Startup with an Investment Advisor code
3. Verify the relationships are properly established in the database
4. Test the Investment Advisor's ability to see their associated users

## Rollback Plan

If issues persist, you can:

1. **Drop the new tables** (if needed):
```sql
DROP TABLE IF EXISTS investment_advisor_commissions CASCADE;
DROP TABLE IF EXISTS investment_advisor_relationships CASCADE;
DROP TABLE IF EXISTS investment_advisor_recommendations CASCADE;
```

2. **Remove the new columns** (if needed):
```sql
ALTER TABLE users DROP COLUMN IF EXISTS investment_advisor_code;
ALTER TABLE users DROP COLUMN IF EXISTS logo_url;
ALTER TABLE users DROP COLUMN IF EXISTS proof_of_business_url;
ALTER TABLE users DROP COLUMN IF EXISTS financial_advisor_license_url;
ALTER TABLE startups DROP COLUMN IF EXISTS investment_advisor_code;
ALTER TABLE startup_addition_requests DROP COLUMN IF EXISTS investment_advisor_code;
```

3. **Restore original RLS policies** (if needed):
```sql
-- This would depend on what your original policies were
-- You may need to check your backup or version control
```

## Next Steps

1. **First**: Run `ADD_INVESTMENT_ADVISOR_ENUM.sql` to add the enum value
2. **Then**: Run the fixed SQL script (`INVESTMENT_ADVISOR_DATABASE_SETUP_FIXED.sql`) in your Supabase database
3. **Test user registration** to ensure email verification works
4. **Test Investment Advisor functionality** end-to-end
5. **Monitor for any additional issues** and address them as needed

The fixes address both the foreign key constraint error and the email verification issue while maintaining all the Investment Advisor functionality that was implemented.
