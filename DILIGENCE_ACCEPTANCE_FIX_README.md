# Diligence Acceptance Fix

## Problem Description

The application was failing to accept diligence requests from startups with a 404 error when calling the `safe_update_diligence_status` RPC function. This function was supposed to exist in the database but was missing.

## Root Cause

The `safe_update_diligence_status` RPC function was not created in the Supabase database, causing the frontend to fail when trying to accept diligence requests.

## Solution Applied

### 1. Frontend Fix (Immediate)

Updated the `CapTableTab.tsx` component to use direct database updates instead of the missing RPC function:

- Removed dependency on `safe_update_diligence_status` RPC function
- Implemented direct database update with optimistic locking
- Added better error handling and logging
- Added verification that the update was successful

### 2. Database Fix (Optional but Recommended)

Created SQL scripts to properly set up the database:

- `FIX_DILIGENCE_ACCEPTANCE_FINAL.sql` - Creates the missing RPC function
- `test-database-connection.sql` - Tests database connectivity

## How to Apply the Database Fix

### Option 1: Run the SQL Script (Recommended)

1. Open your Supabase dashboard
2. Go to the SQL Editor
3. Copy and paste the contents of `FIX_DILIGENCE_ACCEPTANCE_FINAL.sql`
4. Run the script
5. Verify the function was created successfully

### Option 2: Manual Function Creation

If you prefer to create the function manually, run this SQL:

```sql
CREATE OR REPLACE FUNCTION safe_update_diligence_status(
    p_application_id UUID,
    p_new_status TEXT,
    p_expected_current_status TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    current_status TEXT;
    update_count INTEGER;
BEGIN
    -- Get current status
    SELECT diligence_status INTO current_status
    FROM opportunity_applications
    WHERE id = p_application_id;
    
    -- If no record found, return false
    IF current_status IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- If expected current status is provided, check it matches
    IF p_expected_current_status IS NOT NULL AND current_status != p_expected_current_status THEN
        RETURN FALSE;
    END IF;
    
    -- Prevent updating if already approved
    IF current_status = 'approved' AND p_new_status = 'approved' THEN
        RETURN FALSE;
    END IF;
    
    -- Update the status
    UPDATE opportunity_applications
    SET diligence_status = p_new_status,
        updated_at = COALESCE(updated_at, NOW())
    WHERE id = p_application_id
    AND diligence_status != 'approved';
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    
    RETURN update_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION safe_update_diligence_status(UUID, TEXT, TEXT) TO authenticated;
```

## Verification

After applying the fix:

1. **Frontend**: The diligence acceptance should work immediately
2. **Database**: Run the test script to verify the function exists
3. **Functionality**: Try accepting a diligence request as a startup user

## Testing

To test the fix:

1. Log in as a startup user
2. Navigate to the Cap Table tab
3. Look for diligence requests that need acceptance
4. Click "Accept" on a diligence request
5. Verify the request is accepted successfully

## Error Messages

If you still see errors, check:

- Database connection (run `test-database-connection.sql`)
- RLS policies on `opportunity_applications` table
- User permissions and authentication
- Console logs for detailed error information

## Rollback

If you need to rollback:

1. The frontend changes are safe and can be reverted
2. The database function can be dropped with:
   ```sql
   DROP FUNCTION IF EXISTS safe_update_diligence_status(UUID, TEXT, TEXT);
   ```

## Future Improvements

Consider implementing:

1. Better error handling and user feedback
2. Audit logging for diligence status changes
3. Email notifications when diligence is accepted
4. Dashboard indicators for pending diligence requests

## Support

If you continue to experience issues:

1. Check the browser console for error messages
2. Verify database connectivity
3. Check Supabase logs for RPC function errors
4. Ensure all required database columns exist
