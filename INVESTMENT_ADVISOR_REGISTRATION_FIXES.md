# Investment Advisor Registration Fixes

## Issues Identified and Solutions

### 1. Database Columns Missing
**Problem**: "Failed to update user profile" error occurs because the database columns for Investment Advisor fields don't exist yet.

**Solution**: Run the database setup script first.

### 2. Document Labels and Fields
**Problem**: Missing "License (As per country regulations)" field and incorrect labels.

**Solution**: Updated the registration form to include all required fields with correct labels.

## Required Actions

### Step 1: Run Database Setup Script
Before testing Investment Advisor registration, you must run the database setup script:

```sql
-- Run this script in your Supabase SQL editor
-- File: INVESTMENT_ADVISOR_DATABASE_SETUP_FIXED.sql
```

This script will:
- Add 'Investment Advisor' to the user_role enum
- Add required columns to the users table:
  - `investment_advisor_code`
  - `logo_url`
  - `proof_of_business_url`
  - `financial_advisor_license_url`
- Create all necessary tables and policies

### Step 2: Updated Registration Flow

#### For Investment Advisor Registration:
**Required Documents:**
1. **Government ID** (Passport, Driver's License, etc.)
2. **Proof of Firm Registration** (correctly labeled now)
3. **License (As per country regulations)** (newly added)
4. **Company Logo** (newly added)

#### For Investor/Startup Registration:
**Optional Field:**
- **Investment Advisor Code** (for linking to existing Investment Advisor)

## Files Modified

### 1. `components/DocumentUploadStep.tsx`
**Changes Made:**
- Added `license` field to uploadedFiles state
- Added "License (As per country regulations)" upload field for Investment Advisor role
- Updated validation to require license and logo for Investment Advisors
- Fixed document labels

**Key Code Changes:**
```typescript
// Added license field to state
const [uploadedFiles, setUploadedFiles] = useState<{
  govId: File | null;
  roleSpecific: File | null;
  license?: File | null; // Added this
  logo?: File | null;
}>({
  govId: null,
  roleSpecific: null,
  license: null, // Added this
  logo: null
});

// Added license validation
if (userData.role === 'Investment Advisor') {
  if (!uploadedFiles.license) {
    setError('License (As per country regulations) is required for Investment Advisors');
    setIsLoading(false);
    return;
  }
  if (!uploadedFiles.logo) {
    setError('Company logo is required for Investment Advisors');
    setIsLoading(false);
    return;
  }
}

// Added license upload field
{userData.role === 'Investment Advisor' && (
  <div>
    <label className="block text-sm font-medium text-slate-700 mb-2">
      License (As per country regulations)
    </label>
    <Input
      type="file"
      accept=".pdf,.jpg,.jpeg,.png"
      onChange={(e) => handleFileChange(e, 'license')}
      required
    />
    {/* ... */}
  </div>
)}
```

### 2. `components/TwoStepRegistration.tsx`
**Changes Made:**
- Added license upload handling
- Updated user profile creation to include license URL
- Fixed verification documents array to include all uploaded files

**Key Code Changes:**
```typescript
// Added license upload handling
if (documents.license && userData.role === 'Investment Advisor') {
  const result = await storageService.uploadVerificationDocument(
    documents.license, 
    userData.email, 
    'financial-advisor-license'
  );
  if (result.success && result.url) {
    licenseUrl = result.url;
  }
}

// Updated user profile with Investment Advisor fields
if (userData.role === 'Investment Advisor') {
  if (licenseUrl) {
    updateData.financial_advisor_license_url = licenseUrl;
  }
  if (logoUrl) {
    updateData.logo_url = logoUrl;
  }
  // Add license and logo to verification documents
  updateData.verification_documents = [governmentIdUrl, roleSpecificUrl, licenseUrl, logoUrl].filter(Boolean);
}
```

## Registration Flow Summary

### Investment Advisor Registration:
1. **Basic Information**: Name, email, password, role selection
2. **Document Upload**:
   - Government ID (required)
   - Proof of Firm Registration (required)
   - License (As per country regulations) (required)
   - Company Logo (required)
3. **Auto-generated**: Investment Advisor Code (e.g., IA-123456)

### Investor/Startup Registration:
1. **Basic Information**: Name, email, password, role selection
2. **Document Upload**:
   - Government ID (required)
   - Role-specific document (required)
3. **Optional**: Investment Advisor Code (if they have an advisor)

## Testing Steps

### 1. Database Setup
1. Run `INVESTMENT_ADVISOR_DATABASE_SETUP_FIXED.sql` in Supabase SQL editor
2. Verify that the script runs without errors
3. Check that the `users` table has the new columns

### 2. Investment Advisor Registration
1. Register a new user with "Investment Advisor" role
2. Verify all four document fields are visible and required:
   - Government ID
   - Proof of Firm Registration
   - License (As per country regulations)
   - Company Logo
3. Upload all required documents
4. Verify registration completes successfully
5. Check that Investment Advisor code is auto-generated

### 3. Investor/Startup Registration
1. Register users with "Investor" or "Startup" roles
2. Verify that only Government ID and role-specific document are required
3. Verify that Investment Advisor Code field is visible and optional
4. Test with and without Investment Advisor Code

### 4. File Upload Validation
1. Test with valid file types for each document
2. Test with invalid file types to ensure proper error handling
3. Verify file size limits are respected
4. Test with missing required documents

## Error Resolution

### "Failed to update user profile" Error
**Cause**: Database columns for Investment Advisor fields don't exist.

**Solution**: 
1. Run the database setup script first
2. Ensure all required columns are created
3. Verify RLS policies are properly set up

### Missing Document Fields
**Cause**: Document upload fields not properly configured for Investment Advisor role.

**Solution**: 
1. Ensure all four document fields are visible for Investment Advisor role
2. Verify validation requires all four documents
3. Check that file uploads are properly handled

## Next Steps

1. **Run Database Setup**: Execute `INVESTMENT_ADVISOR_DATABASE_SETUP_FIXED.sql`
2. **Test Registration**: Try registering as Investment Advisor
3. **Verify Documents**: Ensure all four documents are uploaded and stored
4. **Check Dashboard**: Verify Investment Advisor dashboard displays correctly
5. **Test Other Roles**: Ensure Investor/Startup registration still works with optional Investment Advisor Code

The registration flow should now work correctly with all required fields and proper validation for Investment Advisor registration.

