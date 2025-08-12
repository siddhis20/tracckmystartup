# Storage Policy Implementation Guide for Startup Nation App

## Overview
This guide will help you implement comprehensive, role-based storage policies for your 6 Supabase storage buckets. The policies ensure proper security while allowing appropriate access based on user roles.

## Your Storage Buckets
1. **startup-documents** - General startup documents, business plans
2. **pitch-decks** - Pitch deck presentations  
3. **pitch-videos** - Pitch video presentations
4. **financial-documents** - Financial statements, tax documents
5. **employee-contracts** - Employee contracts, HR documents
6. **verification-documents** - Legal verification documents, compliance certificates

## Step-by-Step Implementation

### Step 1: Access Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**

### Step 2: Run the Comprehensive Policies Script
1. Copy the entire content from `COMPREHENSIVE_STORAGE_POLICIES.sql`
2. Paste it into the SQL Editor
3. Click **Run** to execute the script

### Step 3: Verify Policy Creation
After running the script, execute these verification queries:

```sql
-- Check if all policies were created
SELECT 
  policyname,
  cmd,
  permissive
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;
```

You should see 24 policies (4 policies per bucket × 6 buckets):
- `startup-documents-upload`, `startup-documents-update`, `startup-documents-delete`, `startup-documents-view`
- `pitch-decks-upload`, `pitch-decks-update`, `pitch-decks-delete`, `pitch-decks-view`
- `pitch-videos-upload`, `pitch-videos-update`, `pitch-videos-delete`, `pitch-videos-view`
- `financial-documents-upload`, `financial-documents-update`, `financial-documents-delete`, `financial-documents-view`
- `employee-contracts-upload`, `employee-contracts-update`, `employee-contracts-delete`, `employee-contracts-view`
- `verification-documents-upload`, `verification-documents-update`, `verification-documents-delete`, `verification-documents-view`

### Step 4: Test Helper Functions
Run this query to test the role-checking functions:

```sql
SELECT 
  'get_user_role' as function_name,
  get_user_role() as result
UNION ALL
SELECT 
  'is_admin' as function_name,
  is_admin()::TEXT as result
UNION ALL
SELECT 
  'is_startup' as function_name,
  is_startup()::TEXT as result;
```

## Role-Based Access Matrix

| Bucket | Startup | Investor | CA/CS | Admin | Facilitator |
|--------|---------|----------|-------|-------|-------------|
| **startup-documents** | Full | Read | Read | Full | Read |
| **pitch-decks** | Full | Read | Read | Full | Read |
| **pitch-videos** | Full | Read | Read | Full | Read |
| **financial-documents** | Full | Read | Full | Full | Read |
| **employee-contracts** | Full | None | Read | Full | Read |
| **verification-documents** | Upload | Read | Full | Full | Read |

**Legend:**
- **Full**: Upload, Download, Update, Delete
- **Read**: Download only
- **Upload**: Upload only
- **None**: No access

## Testing Your Policies

### Test 1: File Upload
1. Log in as a Startup user
2. Try uploading a document to `startup-documents`
3. Expected result: ✅ Success
4. Log in as an Investor
5. Try uploading to `startup-documents`
6. Expected result: ❌ Permission denied

### Test 2: File Download
1. Log in as an Investor
2. Try downloading a file from `pitch-decks`
3. Expected result: ✅ Success
4. Log in as an Investor
5. Try downloading from `employee-contracts`
6. Expected result: ❌ Permission denied

### Test 3: File Management
1. Log in as a CA/CS user
2. Try uploading to `financial-documents`
3. Expected result: ✅ Success
4. Try deleting from `financial-documents`
5. Expected result: ✅ Success

## Troubleshooting Common Issues

### Issue 1: "Permission denied" errors
**Cause:** User doesn't have the required role or permissions
**Solution:** 
- Check user's role in the `users` table
- Verify the policy allows the user's role for that operation

### Issue 2: "Bucket not found" errors
**Cause:** Bucket name mismatch
**Solution:**
- Verify bucket names are exactly: `startup-documents`, `pitch-decks`, `pitch-videos`, `financial-documents`, `employee-contracts`, `verification-documents`

### Issue 3: Uploads timeout or fail
**Cause:** Network issues or policy conflicts
**Solution:**
- Check browser console for specific error messages
- Verify user is authenticated
- Try the troubleshooting policies in the SQL file

### Issue 4: Helper functions return null
**Cause:** User not found in `users` table
**Solution:**
- Ensure user exists in `public.users` table
- Check that `auth.uid()` matches the user's `id`

## Fallback Policies (If Needed)

If you encounter persistent issues, you can temporarily use these simpler policies:

```sql
-- Drop all existing policies first
DROP POLICY IF EXISTS "startup-documents-upload" ON storage.objects;
-- (repeat for all policies)

-- Simple policy for all authenticated users
CREATE POLICY "Allow all operations for authenticated users" ON storage.objects
FOR ALL USING (auth.role() = 'authenticated');
```

## Security Best Practices

1. **Regular Audits**: Periodically review who has access to sensitive documents
2. **Role Validation**: Ensure users are assigned correct roles
3. **Document Classification**: Use appropriate buckets for different document types
4. **Access Logging**: Monitor file access patterns for suspicious activity

## Integration with Your App

The policies work with your existing Supabase client code. No changes needed to your React components - the policies will automatically enforce access control.

## Next Steps

1. ✅ Run the comprehensive policies script
2. ✅ Verify all policies are created
3. ✅ Test with different user roles
4. ✅ Monitor for any issues in your app
5. ✅ Update your app's error handling for permission denied cases

## Support

If you encounter issues:
1. Check the Supabase logs in the dashboard
2. Review the troubleshooting section above
3. Test with the fallback policies if needed
4. Verify user roles are correctly set in your database

---

**Note:** These policies provide a good balance between security and usability. You can adjust them based on your specific requirements by modifying the role conditions in each policy.
