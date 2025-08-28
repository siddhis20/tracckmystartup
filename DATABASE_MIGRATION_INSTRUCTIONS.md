# Database Migration Instructions

## Issue
The error `"Could not find the 'startup_id' column of 'investment_offers'` occurs because the database schema hasn't been updated yet.

## Solution
You need to run the SQL migration script in your Supabase SQL Editor.

## Steps to Fix:

### 1. Open Supabase Dashboard
- Go to your Supabase project dashboard
- Navigate to the **SQL Editor** section

### 2. Run the Migration Script
Copy and paste this SQL script into the SQL Editor:

```sql
-- FIX_INVESTMENT_OFFERS_FOREIGN_KEY_TO_STARTUPS.sql
-- Fix the foreign key constraint in investment_offers table to reference startups table

-- 1. Drop the existing foreign key constraint
ALTER TABLE investment_offers 
DROP CONSTRAINT IF EXISTS investment_offers_investment_id_fkey;

-- 2. Rename the column to be more descriptive
ALTER TABLE investment_offers 
RENAME COLUMN investment_id TO startup_id;

-- 3. Add new foreign key constraint to reference startups table
ALTER TABLE investment_offers 
ADD CONSTRAINT investment_offers_startup_id_fkey 
FOREIGN KEY (startup_id) REFERENCES startups(id) ON DELETE CASCADE;

-- 4. Verify the changes
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name='investment_offers';

-- 5. Show the updated table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'investment_offers'
ORDER BY ordinal_position;
```

### 3. Execute the Script
- Click the **Run** button in the SQL Editor
- Wait for the script to complete successfully

### 4. Verify the Changes
After running the script, you should see:
- The foreign key constraint now references `startups(id)` instead of `new_investments(id)`
- The column name has changed from `investment_id` to `startup_id`

### 5. Test the Fix
- Go back to your application
- Try submitting an investment offer again
- The error should be resolved

## What This Migration Does:
1. **Removes** the old foreign key constraint to `new_investments`
2. **Renames** the column from `investment_id` to `startup_id`
3. **Creates** a new foreign key constraint to `startups`
4. **Verifies** the changes were applied correctly

## Expected Result:
- ✅ Investment offers can reference startup IDs (like 37)
- ✅ Foreign key constraints are properly satisfied
- ✅ No more "column not found" errors
- ✅ Investment offer submission works correctly
