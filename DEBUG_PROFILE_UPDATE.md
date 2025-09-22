# Debug Profile Update Issues

## Current Status
Profile update is still failing even after running the SQL migration. Let's debug this step by step.

## Debugging Steps

### Step 1: Check Browser Console
1. Open the startup dashboard
2. Go to Profile tab
3. Try to save any change
4. Open browser console (F12)
5. Look for error messages starting with "❌"

### Step 2: Run Database Test
Copy and paste this code in the browser console:

```javascript
// Test database connection and RPC functions
async function debugProfileUpdate() {
    console.log('🔍 Starting profile update debug...');
    
    try {
        // Test 1: Check supabase client
        console.log('1. Checking Supabase client...');
        if (typeof window.supabase === 'undefined') {
            console.error('❌ Supabase client not found');
            return;
        }
        console.log('✅ Supabase client found');
        
        // Test 2: Query startups table
        console.log('2. Testing database query...');
        const { data: startups, error: queryError } = await window.supabase
            .from('startups')
            .select('id, name, currency, country_of_registration, company_type')
            .limit(1);
            
        if (queryError) {
            console.error('❌ Query failed:', queryError);
            return;
        }
        console.log('✅ Query successful:', startups);
        
        if (!startups || startups.length === 0) {
            console.error('❌ No startups found');
            return;
        }
        
        const startup = startups[0];
        console.log('Using startup:', startup);
        
        // Test 3: Check currency column
        console.log('3. Checking currency column...');
        if ('currency' in startup) {
            console.log('✅ Currency column exists:', startup.currency);
        } else {
            console.error('❌ Currency column missing');
        }
        
        // Test 4: Test RPC function with minimal parameters
        console.log('4. Testing RPC function...');
        const { data: rpcData, error: rpcError } = await window.supabase
            .rpc('update_startup_profile_simple', {
                startup_id_param: startup.id,
                country_param: 'USA',
                company_type_param: 'C-Corporation',
                registration_date_param: '2024-01-01',
                currency_param: 'USD',
                ca_service_code_param: null,
                cs_service_code_param: null
            });
            
        if (rpcError) {
            console.error('❌ RPC function failed:', rpcError);
            console.log('RPC error details:', {
                message: rpcError.message,
                details: rpcError.details,
                hint: rpcError.hint,
                code: rpcError.code
            });
        } else {
            console.log('✅ RPC function successful:', rpcData);
        }
        
        // Test 5: Test direct update
        console.log('5. Testing direct update...');
        const { error: updateError } = await window.supabase
            .from('startups')
            .update({
                currency: 'USD',
                updated_at: new Date().toISOString()
            })
            .eq('id', startup.id);
            
        if (updateError) {
            console.error('❌ Direct update failed:', updateError);
        } else {
            console.log('✅ Direct update successful');
        }
        
    } catch (error) {
        console.error('❌ Debug test failed:', error);
    }
}

// Run the debug test
debugProfileUpdate();
```

### Step 3: Check SQL Migration Status
Run this in Supabase SQL Editor to verify the migration was successful:

```sql
-- Check if currency column exists
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name = 'currency';

-- Check if RPC functions exist
SELECT routine_name, routine_definition 
FROM information_schema.routines 
WHERE routine_name LIKE '%startup_profile%';

-- Test the RPC function directly
SELECT update_startup_profile_simple(
    1, -- replace with actual startup ID
    'USA',
    'C-Corporation', 
    '2024-01-01',
    'USD',
    null,
    null
);
```

### Step 4: Common Issues and Solutions

#### Issue 1: RPC Function Not Found
**Error**: `function update_startup_profile_simple does not exist`
**Solution**: The SQL migration didn't run properly. Re-run the migration script.

#### Issue 2: Currency Column Missing
**Error**: `column "currency" does not exist`
**Solution**: The currency column wasn't added. Run this SQL:
```sql
ALTER TABLE public.startups 
ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'USD';
```

#### Issue 3: Permission Denied
**Error**: `permission denied for table startups`
**Solution**: Check RLS policies. Run this SQL:
```sql
-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'startups';

-- Temporarily disable RLS for testing (NOT for production)
ALTER TABLE public.startups DISABLE ROW LEVEL SECURITY;
```

#### Issue 4: Function Parameter Mismatch
**Error**: `function update_startup_profile_simple(integer, text, text, date, text, text, text) does not exist`
**Solution**: The function signature doesn't match. Recreate the function:
```sql
DROP FUNCTION IF EXISTS update_startup_profile_simple(INTEGER, TEXT, TEXT, DATE, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION update_startup_profile_simple(
    startup_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE,
    currency_param TEXT DEFAULT 'USD',
    ca_service_code_param TEXT DEFAULT NULL,
    cs_service_code_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.startups 
    SET 
        country_of_registration = country_param,
        company_type = company_type_param,
        registration_date = registration_date_param,
        currency = currency_param,
        ca_service_code = ca_service_code_param,
        cs_service_code = cs_service_code_param,
        updated_at = NOW()
    WHERE id = startup_id_param;
    
    RETURN FOUND;
END;
$$;
```

### Step 5: Alternative Approach
If RPC functions continue to fail, we can modify the profile service to use only direct database updates:

```typescript
// In lib/profileService.ts, replace the RPC calls with direct updates
async updateStartupProfile(startupId: number, profileData: Partial<ProfileData>): Promise<boolean> {
  try {
    const updateData: any = {
      updated_at: new Date().toISOString(),
    };
    
    if (profileData.country) updateData.country_of_registration = profileData.country;
    if (profileData.companyType) updateData.company_type = profileData.companyType;
    if (profileData.registrationDate) updateData.registration_date = profileData.registrationDate;
    if (profileData.currency) updateData.currency = profileData.currency;
    if (profileData.caServiceCode) updateData.ca_service_code = profileData.caServiceCode;
    if (profileData.csServiceCode) updateData.cs_service_code = profileData.csServiceCode;
    
    const { error } = await supabase
      .from('startups')
      .update(updateData)
      .eq('id', startupId);
    
    if (error) throw error;
    return true;
  } catch (error) {
    console.error('❌ Profile update failed:', error);
    throw error;
  }
}
```

## Next Steps
1. Run the debug script in browser console
2. Check the console output for specific error messages
3. Apply the appropriate fix based on the error
4. Test profile update again

## Files to Check
- Browser console for error messages
- Supabase SQL Editor for database status
- Network tab for failed requests
- Application logs for detailed error information
