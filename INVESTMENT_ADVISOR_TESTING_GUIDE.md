# Investment Advisor Registration Testing Guide

## Database Setup Confirmed ✅

The database setup is complete with all required columns:
- ✅ `investment_advisor_code` (with unique constraint)
- ✅ `logo_url`
- ✅ `proof_of_business_url`
- ✅ `financial_advisor_license_url`
- ✅ Auto-generation trigger: `trigger_set_investment_advisor_code`

## Updated Registration Flow

### Investment Advisor Registration
**Required Documents:**
1. **Government ID** (Passport, Driver's License, etc.)
2. **Proof of Firm Registration** (correctly labeled)
3. **License (As per country regulations)** (newly added)
4. **Company Logo** (newly added)

### Investor/Startup Registration
**Optional Field:**
- **Investment Advisor Code** (for linking to existing Investment Advisor)

## Testing Steps

### 1. Test Investment Advisor Registration

1. **Open the registration page**
2. **Fill in basic information:**
   - Name: "Test Investment Advisor"
   - Email: "test-advisor@example.com"
   - Password: "password123"
   - Role: "Investment Advisor"
   - Country: "United States"

3. **Document Upload Step:**
   - Verify all 4 document fields are visible:
     - Government ID
     - Proof of Firm Registration
     - License (As per country regulations)
     - Company Logo
   - Upload test files for each field
   - Verify validation requires all 4 documents

4. **Check Browser Console:**
   - Open Developer Tools (F12)
   - Go to Console tab
   - Look for debug logs:
     - "Updating user profile with data: ..."
     - "User ID: ..."
   - If there's an error, it will show the actual error message

### 2. Debug Information

The updated code now includes better error logging:

```typescript
console.log('Updating user profile with data:', updateData);
console.log('User ID:', user.id);

if (updateError) {
  console.error('Update error:', updateError);
  throw new Error(`Failed to update user profile: ${updateError.message}`);
}
```

### 3. Expected Console Output

**Successful Registration:**
```
Updating user profile with data: {
  government_id: "https://...",
  ca_license: "https://...",
  verification_documents: ["https://...", "https://...", "https://...", "https://..."],
  updated_at: "2024-01-01T00:00:00.000Z",
  financial_advisor_license_url: "https://...",
  logo_url: "https://..."
}
User ID: "uuid-here"
```

**If Error Occurs:**
```
Update error: {message: "actual error message", details: "..."}
Failed to update user profile: actual error message
```

## Common Issues and Solutions

### 1. "Failed to update user profile" Error

**Possible Causes:**
- RLS (Row Level Security) policy blocking the update
- Missing required fields
- Invalid data types
- File upload failures

**Debug Steps:**
1. Check browser console for the actual error message
2. Verify all file uploads completed successfully
3. Check if the user is properly authenticated
4. Verify RLS policies allow the update

### 2. File Upload Issues

**Check:**
- File sizes are within limits
- File types are accepted (.pdf, .jpg, .jpeg, .png, .svg)
- Network connection is stable
- Storage bucket permissions are correct

### 3. Validation Issues

**Verify:**
- All required fields are filled
- File uploads are completed
- No validation errors are shown

## RLS Policy Check

If you're still getting errors, check the RLS policies on the `users` table:

```sql
-- Check current RLS policies
SELECT * FROM pg_policies WHERE tablename = 'users';

-- Verify the update policy exists
SELECT * FROM pg_policies 
WHERE tablename = 'users' 
AND policyname = 'Users can update their own profile';
```

## Manual Database Test

You can test the database update manually:

```sql
-- Test updating a user profile (replace with actual user ID)
UPDATE users 
SET 
  government_id = 'test-url',
  ca_license = 'test-url',
  verification_documents = ARRAY['test-url1', 'test-url2'],
  financial_advisor_license_url = 'test-url',
  logo_url = 'test-url',
  updated_at = NOW()
WHERE id = 'your-user-id-here';
```

## Next Steps

1. **Test the registration** with the updated code
2. **Check browser console** for debug information
3. **Report the actual error message** if registration still fails
4. **Verify file uploads** are working correctly
5. **Check RLS policies** if needed

The enhanced error logging should now provide the exact error message, making it easier to identify and fix the issue.

## Files Modified

- ✅ `components/DocumentUploadStep.tsx` - Added license field and proper validation
- ✅ `components/TwoStepRegistration.tsx` - Added license handling and better error logging
- ✅ `lib/auth.ts` - Added Investment Advisor fields to AuthUser interface

All files are ready for testing with the database setup complete.

